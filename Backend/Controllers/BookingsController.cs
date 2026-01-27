using Backend.Data;
using Backend.Enums;
using Backend.Models;
using Backend.Dto;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class BookingsController : ControllerBase
{
      private readonly AppDbContext _context;

      public BookingsController(AppDbContext context)
      {
            _context = context;
      }

      // GET /api/bookings/calendar?from=...&to=...
      [HttpGet("calendar")]
      public async Task<IActionResult> GetCalendar([FromQuery] DateTime from, [FromQuery] DateTime to)
      {
            var bookings = await _context.Bookings
                .Where(b => b.StartTime >= from && b.EndTime <= to && b.Status != BookingStatus.Cancelled)
                .Include(b => b.Court)
                .Include(b => b.Member) // Maybe limit fields returned for public view
                .Select(b => new
                {
                      b.Id,
                      b.CourtId,
                      CourtName = b.Court!.Name,
                      b.StartTime,
                      b.EndTime,
                      b.Status,
                      MemberName = b.Member!.FullName // To show who booked
                })
                .ToListAsync();

            return Ok(bookings);
      }

      // POST /api/bookings
      [HttpPost]
      [Authorize]
      public async Task<IActionResult> CreateBooking([FromBody] CreateBookingDto request)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member not found.");

            // 1. Validate Time
            if (request.StartTime >= request.EndTime) return BadRequest("End time must be after start time.");
            if (request.StartTime < DateTime.UtcNow) return BadRequest("Cannot book in the past.");

            // 2. Check Availability
            var conflict = await _context.Bookings.AnyAsync(b =>
                b.CourtId == request.CourtId &&
                b.Status != BookingStatus.Cancelled &&
                b.StartTime < request.EndTime &&
                b.EndTime > request.StartTime);

            if (conflict) return BadRequest("Slot is already booked.");

            // 3. Calculate Price
            var court = await _context.Courts.FindAsync(request.CourtId);
            if (court == null || !court.IsActive) return BadRequest("Court not available.");

            var durationHours = (request.EndTime - request.StartTime).TotalHours;
            var totalPrice = (decimal)durationHours * court.PricePerHour;

            // 4. Check Balance
            if (member.WalletBalance < totalPrice)
                  return BadRequest("Insufficient wallet balance.");

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                  // 5. Deduct Balance
                  member.WalletBalance -= totalPrice;
                  member.TotalSpent += totalPrice; // Update tier logic triggers could go here

                  // 6. Create Wallet Transaction
                  var walletTx = new WalletTransaction
                  {
                        MemberId = member.Id,
                        Amount = -totalPrice,
                        Type = TransactionType.Payment,
                        Status = TransactionStatus.Completed,
                        Description = $"Payment for booking {court.Name} ({request.StartTime:MM/dd HH:mm})",
                        CreatedDate = DateTime.UtcNow
                  };
                  _context.WalletTransactions.Add(walletTx);
                  await _context.SaveChangesAsync();

                  // 7. Create Booking
                  var booking = new Booking
                  {
                        CourtId = request.CourtId,
                        MemberId = member.Id,
                        StartTime = request.StartTime,
                        EndTime = request.EndTime,
                        TotalPrice = totalPrice,
                        TransactionId = walletTx.Id,
                        Status = BookingStatus.Confirmed,
                        IsRecurring = false
                  };
                  _context.Bookings.Add(booking);
                  await _context.SaveChangesAsync();

                  // Link TX to Booking
                  walletTx.RelatedId = booking.Id.ToString();
                  await _context.SaveChangesAsync();

                  await transaction.CommitAsync();

                  return Ok(new { Message = "Booking confirmed.", BookingId = booking.Id });
            }
            catch (Exception ex)
            {
                  await transaction.RollbackAsync();
                  return StatusCode(500, "Error processing booking: " + ex.Message);
            }
      }

      // POST /api/bookings/recurring
      [HttpPost("recurring")]
      [Authorize]
      public async Task<IActionResult> CreateRecurringBooking([FromBody] RecurringBookingDto request)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member not found.");

            // 1. Generate Dates
            List<DateTime> dates = new List<DateTime>();
            var current = request.StartTime;
            var duration = request.EndTime - request.StartTime;

            while (current.Date <= request.RecurUntil.Date)
            {
                  if (request.DaysOfWeek.Contains(current.DayOfWeek))
                  {
                        dates.Add(current);
                  }
                  current = current.AddDays(1);
            }

            if (dates.Count == 0) return BadRequest("No valid dates found in range.");

            // 2. Check Availability for ALL dates
            foreach (var date in dates)
            {
                  var start = date.Date + request.StartTime.TimeOfDay;
                  var end = start + duration;

                  var conflict = await _context.Bookings.AnyAsync(b =>
                      b.CourtId == request.CourtId &&
                      b.Status != BookingStatus.Cancelled &&
                      b.StartTime < end &&
                      b.EndTime > start);

                  if (conflict) return BadRequest($"Slot booked on {start:MM/dd}. Transaction cancelled.");
            }

            // 3. Calculate Total Price
            var court = await _context.Courts.FindAsync(request.CourtId);
            if (court == null || !court.IsActive) return BadRequest("Court not available.");

            var totalPrice = (decimal)duration.TotalHours * court.PricePerHour * dates.Count;

            // 4. Check Balance
            if (member.WalletBalance < totalPrice)
                  return BadRequest($"Insufficient wallet balance. Total: {totalPrice:C}");

            // 5. Execution
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                  member.WalletBalance -= totalPrice;
                  member.TotalSpent += totalPrice;

                  var walletTx = new WalletTransaction
                  {
                        MemberId = member.Id,
                        Amount = -totalPrice,
                        Type = TransactionType.Payment,
                        Status = TransactionStatus.Completed,
                        Description = $"Recurring Booking {court.Name} ({dates.Count} slots)",
                        CreatedDate = DateTime.UtcNow
                  };
                  _context.WalletTransactions.Add(walletTx);
                  await _context.SaveChangesAsync();

                  int? parentId = null;
                  foreach (var date in dates)
                  {
                        var start = date.Date + request.StartTime.TimeOfDay;
                        var end = start + duration;

                        var booking = new Booking
                        {
                              CourtId = request.CourtId,
                              MemberId = member.Id,
                              StartTime = start,
                              EndTime = end,
                              TotalPrice = (decimal)duration.TotalHours * court.PricePerHour,
                              TransactionId = walletTx.Id,
                              Status = BookingStatus.Confirmed,
                              IsRecurring = true,
                              RecurrenceRule = request.Frequency,
                              ParentBookingId = parentId
                        };
                        _context.Bookings.Add(booking);
                        await _context.SaveChangesAsync();

                        if (parentId == null) parentId = booking.Id;
                        else booking.ParentBookingId = parentId;
                  }

                  walletTx.RelatedId = parentId.ToString();
                  await _context.SaveChangesAsync();

                  await transaction.CommitAsync();
                  return Ok(new { Message = "Recurring booking success.", TotalSlots = dates.Count });
            }
            catch (Exception ex)
            {
                  await transaction.RollbackAsync();
                  return StatusCode(500, ex.Message);
            }
      }

      // POST /api/bookings/cancel/{id}
      [HttpPost("cancel/{id}")]
      [Authorize]
      public async Task<IActionResult> CancelBooking(int id)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            var booking = await _context.Bookings.Include(b => b.Court).FirstOrDefaultAsync(b => b.Id == id);
            if (booking == null) return NotFound("Booking not found.");

            if (booking.MemberId != member?.Id) return Forbid();

            if (booking.Status == BookingStatus.Cancelled) return BadRequest("Already cancelled.");
            if (booking.StartTime < DateTime.UtcNow) return BadRequest("Cannot cancel past/current bookings.");

            decimal refundAmount = 0;
            if ((booking.StartTime - DateTime.UtcNow).TotalHours > 24)
            {
                  refundAmount = booking.TotalPrice;
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                  booking.Status = BookingStatus.Cancelled;

                  if (refundAmount > 0)
                  {
                        member.WalletBalance += refundAmount;

                        _context.WalletTransactions.Add(new WalletTransaction
                        {
                              MemberId = member.Id,
                              Amount = refundAmount,
                              Type = TransactionType.Refund,
                              Status = TransactionStatus.Completed,
                              Description = $"Refund for booking {booking.Id}",
                              RelatedId = booking.Id.ToString(),
                              CreatedDate = DateTime.UtcNow
                        });
                  }

                  await _context.SaveChangesAsync();
                  await transaction.CommitAsync();

                  return Ok(new { Message = "Booking cancelled.", Refund = refundAmount });
            }
            catch (Exception ex)
            {
                  await transaction.RollbackAsync();
                  return StatusCode(500, ex.Message);
            }
      }
}
