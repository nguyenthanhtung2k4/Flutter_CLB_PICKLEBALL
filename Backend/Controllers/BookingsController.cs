using Backend.Data;
using Backend.Enums;
using Backend.Models;
using Backend.Dto;
using Backend.Services;
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
      private readonly MemberTierService _tierService;
      private readonly NotificationService _notificationService;

      public BookingsController(AppDbContext context, MemberTierService tierService, NotificationService notificationService)
      {
            _context = context;
            _tierService = tierService;
            _notificationService = notificationService;
      }

      // GET /api/bookings/calendar?from=...&to=...
      [HttpGet("calendar")]
      public async Task<IActionResult> GetCalendar([FromQuery] DateTime from, [FromQuery] DateTime to)
      {
            var now = DateTime.UtcNow;
            var bookings = await _context.Bookings
                .Where(b => b.StartTime >= from && b.EndTime <= to &&
                            b.Status != BookingStatus.Cancelled &&
                            (b.Status != BookingStatus.Holding || b.HoldUntil == null || b.HoldUntil > now))
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
                      MemberName = b.Member!.FullName, // To show who booked
                      MemberId = b.MemberId,
                      b.HoldUntil
                })
                .ToListAsync();

            return Ok(bookings);
      }

      // POST /api/bookings/hold
      [HttpPost("hold")]
      [Authorize]
      public async Task<IActionResult> HoldSlot([FromBody] HoldBookingDto request)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member not found.");

            if (request.StartTime >= request.EndTime) return BadRequest("End time must be after start time.");
            if (request.StartTime < DateTime.UtcNow) return BadRequest("Cannot hold slot in the past.");

            var now = DateTime.UtcNow;
            var conflict = await _context.Bookings.AnyAsync(b =>
                b.CourtId == request.CourtId &&
                b.Status != BookingStatus.Cancelled &&
                (b.Status != BookingStatus.Holding || (b.HoldUntil != null && b.HoldUntil > now)) &&
                b.StartTime < request.EndTime &&
                b.EndTime > request.StartTime);

            if (conflict) return BadRequest("Slot is already booked or held.");

            var court = await _context.Courts.FindAsync(request.CourtId);
            if (court == null || !court.IsActive) return BadRequest("Court not available.");

            var durationHours = (request.EndTime - request.StartTime).TotalHours;
            var totalPrice = (decimal)durationHours * court.PricePerHour;

            var holdMinutes = request.HoldMinutes <= 0 ? 5 : request.HoldMinutes;
            var holdUntil = DateTime.UtcNow.AddMinutes(holdMinutes);

            var booking = new Booking
            {
                  CourtId = request.CourtId,
                  MemberId = member.Id,
                  StartTime = request.StartTime,
                  EndTime = request.EndTime,
                  TotalPrice = totalPrice,
                  Status = BookingStatus.Holding,
                  HoldUntil = holdUntil,
                  IsRecurring = false
            };

            _context.Bookings.Add(booking);
            await _context.SaveChangesAsync();

            await _notificationService.BroadcastCalendarUpdate();

            return Ok(new
            {
                  Message = "Slot held successfully.",
                  HoldId = booking.Id,
                  HoldUntil = holdUntil,
                  TotalPrice = totalPrice
            });
      }

      // POST /api/bookings/confirm/{id}
      [HttpPost("confirm/{id}")]
      [Authorize]
      public async Task<IActionResult> ConfirmHold(int id)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member not found.");

            var booking = await _context.Bookings.Include(b => b.Court).FirstOrDefaultAsync(b => b.Id == id);
            if (booking == null) return NotFound("Hold not found.");

            if (booking.MemberId != member.Id) return Forbid();
            if (booking.Status != BookingStatus.Holding) return BadRequest("Booking is not in holding status.");
            if (booking.HoldUntil != null && booking.HoldUntil < DateTime.UtcNow)
                  return BadRequest("Hold expired.");

            var totalPrice = booking.TotalPrice;
            if (totalPrice <= 0 && booking.Court != null)
            {
                  var durationHours = (booking.EndTime - booking.StartTime).TotalHours;
                  totalPrice = (decimal)durationHours * booking.Court.PricePerHour;
                  booking.TotalPrice = totalPrice;
            }

            if (member.WalletBalance < totalPrice)
                  return BadRequest("Insufficient wallet balance.");

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                  member.WalletBalance -= totalPrice;
                  member.TotalSpent += totalPrice;
                  _tierService.UpdateTier(member);

                  var walletTx = new WalletTransaction
                  {
                        MemberId = member.Id,
                        Amount = -totalPrice,
                        Type = TransactionType.Payment,
                        Status = TransactionStatus.Completed,
                        Description = $"Payment for booking {booking.Court?.Name} ({booking.StartTime:MM/dd HH:mm})",
                        CreatedDate = DateTime.UtcNow
                  };
                  _context.WalletTransactions.Add(walletTx);
                  await _context.SaveChangesAsync();

                  booking.TransactionId = walletTx.Id;
                  booking.Status = BookingStatus.Confirmed;
                  booking.HoldUntil = null;

                  walletTx.RelatedId = booking.Id.ToString();
                  await _context.SaveChangesAsync();

                  await transaction.CommitAsync();

                  await _notificationService.NotifyMemberAsync(
                        member,
                        $"Äáº·t sÃ¢n thÃ nh cÃ´ng: {booking.Court?.Name} {booking.StartTime:dd/MM HH:mm}",
                        NotificationType.Success,
                        "Äáº·t sÃ¢n thÃ nh cÃ´ng",
                        "/booking"
                  );

                  await _notificationService.BroadcastCalendarUpdate();

                  return Ok(new { Message = "Booking confirmed.", BookingId = booking.Id });
            }
            catch (Exception ex)
            {
                  await transaction.RollbackAsync();
                  return StatusCode(500, "Error processing booking: " + ex.Message);
            }
      }

      // DELETE /api/bookings/hold/{id}
      [HttpDelete("hold/{id}")]
      [Authorize]
      public async Task<IActionResult> ReleaseHold(int id)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member not found.");

            var booking = await _context.Bookings.FindAsync(id);
            if (booking == null) return NotFound("Hold not found.");
            if (booking.MemberId != member.Id) return Forbid();
            if (booking.Status != BookingStatus.Holding) return BadRequest("Booking is not in holding status.");

            booking.Status = BookingStatus.Cancelled;
            booking.HoldUntil = null;
            await _context.SaveChangesAsync();

            await _notificationService.BroadcastCalendarUpdate();

            return Ok(new { Message = "Hold released." });
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
            var now = DateTime.UtcNow;
            var conflict = await _context.Bookings.AnyAsync(b =>
                b.CourtId == request.CourtId &&
                b.Status != BookingStatus.Cancelled &&
                (b.Status != BookingStatus.Holding || (b.HoldUntil != null && b.HoldUntil > now)) &&
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
                  member.TotalSpent += totalPrice;
                  _tierService.UpdateTier(member);

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

                  await _notificationService.NotifyMemberAsync(
                        member,
                        $"Äáº·t sÃ¢n thÃ nh cÃ´ng: {court.Name} {request.StartTime:dd/MM HH:mm}",
                        NotificationType.Success,
                        "Äáº·t sÃ¢n thÃ nh cÃ´ng",
                        "/booking"
                  );

                  await _notificationService.BroadcastCalendarUpdate();

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

            if (!_tierService.IsVip(member))
                  return Forbid("VIP members only.");

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
                  _tierService.UpdateTier(member);

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
                  var recurrenceRule = $"{request.Frequency};{string.Join(",", request.DaysOfWeek)}";
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
                              RecurrenceRule = recurrenceRule,
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

                  await _notificationService.NotifyMemberAsync(
                        member,
                        $"Äáº·t lÃ¡Â»Â‹ch Ä‘á»‹nh ká»³ thÃ nh cÃ´ng: {court.Name} ({dates.Count} buá»•i)",
                        NotificationType.Success,
                        "Äáº·t lÃ¡Â»Â‹ch Ä‘á»‹nh ká»³ thÃ nh cÃ´ng",
                        "/booking"
                  );

                  await _notificationService.BroadcastCalendarUpdate();

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

                  await _notificationService.NotifyMemberAsync(
                        member!,
                        refundAmount > 0
                              ? $"Há»§y Ä‘áº·t sÃ¢n vÃ  Ä‘Ã£ hoÃ n tiá»n: +{refundAmount:n0} VNÄ"
                              : "Há»§y Ä‘áº·t sÃ¢n thÃ nh cÃ´ng.",
                        refundAmount > 0 ? NotificationType.Success : NotificationType.Info,
                        "Há»§y Ä‘áº·t sÃ¢n",
                        "/booking"
                  );

                  await _notificationService.BroadcastCalendarUpdate();

                  return Ok(new { Message = "Booking cancelled.", Refund = refundAmount });
            }
            catch (Exception ex)
            {
                  await transaction.RollbackAsync();
                  return StatusCode(500, ex.Message);
            }
      }
}
