using Backend.Data;
using Backend.Dto;
using Backend.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers;

[Route("api/admin")]
[ApiController]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
      private readonly AppDbContext _context;

      public AdminController(AppDbContext context)
      {
            _context = context;
      }

      // GET /api/admin/dashboard/stats
      [HttpGet("dashboard/stats")]
      public async Task<IActionResult> GetDashboardStats()
      {
            var now = DateTime.UtcNow;
            var firstDayOfMonth = new DateTime(now.Year, now.Month, 1);

            // Total Revenue
            var totalRevenue = await _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Completed)
                .SumAsync(t => t.Amount);

            // Monthly Revenue
            var monthlyRevenue = await _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit &&
                           t.Status == TransactionStatus.Completed &&
                           t.CreatedDate >= firstDayOfMonth)
                .SumAsync(t => t.Amount);

            // Total Bookings
            var totalBookings = await _context.Bookings.CountAsync();

            // Monthly Bookings
            var monthlyBookings = await _context.Bookings
                .Where(b => b.StartTime >= firstDayOfMonth)
                .CountAsync();

            // Total Members
            var totalMembers = await _context.Members.CountAsync();

            // Active Members (booked or joined tournament in last 30 days)
            var thirtyDaysAgo = now.AddDays(-30);
            var activeMembers = await _context.Members
                .Where(m => m.IsActive &&
                           (_context.Bookings.Any(b => b.MemberId == m.Id && b.StartTime >= thirtyDaysAgo) ||
                            _context.TournamentParticipants.Any(tp => tp.MemberId == m.Id)))
                .CountAsync();

            // Pending Deposits
            var pendingDeposits = await _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending)
                .CountAsync();

            return Ok(new AdminDashboardStatsDto
            {
                  TotalRevenue = totalRevenue,
                  MonthlyRevenue = monthlyRevenue,
                  TotalBookings = totalBookings,
                  MonthlyBookings = monthlyBookings,
                  TotalMembers = totalMembers,
                  ActiveMembers = activeMembers,
                  PendingDeposits = pendingDeposits
            });
      }

      // GET /api/admin/dashboard/revenue
      [HttpGet("dashboard/revenue")]
      public async Task<IActionResult> GetRevenueChart([FromQuery] int days = 30)
      {
            var now = DateTime.UtcNow;
            var startDate = now.AddDays(-days);

            var transactions = await _context.WalletTransactions
                .Where(t => t.CreatedDate >= startDate && t.Status == TransactionStatus.Completed)
                .ToListAsync();

            var revenueByDay = transactions
                .GroupBy(t => t.CreatedDate.Date)
                .Select(g => new RevenueChartDto
                {
                      Date = g.Key.ToString("yyyy-MM-dd"),
                      DepositAmount = g.Where(t => t.Type == TransactionType.Deposit).Sum(t => t.Amount),
                      PaymentAmount = Math.Abs(g.Where(t => t.Type == TransactionType.Payment).Sum(t => t.Amount)),
                      RefundAmount = g.Where(t => t.Type == TransactionType.Refund).Sum(t => t.Amount)
                })
                .OrderBy(r => r.Date)
                .ToList();

            return Ok(revenueByDay);
      }

      // GET /api/admin/dashboard/bookings-stats
      [HttpGet("dashboard/bookings-stats")]
      public async Task<IActionResult> GetBookingsStats()
      {
            var totalBookings = await _context.Bookings.CountAsync();
            var confirmedBookings = await _context.Bookings
                .CountAsync(b => b.Status == BookingStatus.Confirmed);
            var cancelledBookings = await _context.Bookings
                .CountAsync(b => b.Status == BookingStatus.Cancelled);

            // Bookings by month (last 12 months)
            var now = DateTime.UtcNow;
            var twelveMonthsAgo = now.AddMonths(-12);

            var bookingsByMonth = await _context.Bookings
                .Where(b => b.StartTime >= twelveMonthsAgo)
                .GroupBy(b => new { b.StartTime.Year, b.StartTime.Month })
                .Select(g => new
                {
                      Month = $"{g.Key.Year}-{g.Key.Month:D2}",
                      Count = g.Count()
                })
                .ToListAsync();

            var bookingsByMonthDict = bookingsByMonth.ToDictionary(x => x.Month, x => x.Count);

            return Ok(new BookingStatsDto
            {
                  TotalBookings = totalBookings,
                  ConfirmedBookings = confirmedBookings,
                  CancelledBookings = cancelledBookings,
                  BookingsByMonth = bookingsByMonthDict
            });
      }

      // GET /api/admin/members/stats
      [HttpGet("members/stats")]
      public async Task<IActionResult> GetMembersStats()
      {
            var totalMembers = await _context.Members.CountAsync();

            // Members by Tier
            var membersByTier = await _context.Members
                .GroupBy(m => m.Tier)
                .Select(g => new { Tier = g.Key.ToString(), Count = g.Count() })
                .ToListAsync();

            var membersByTierDict = membersByTier.ToDictionary(x => x.Tier, x => x.Count);

            // Members by Rank Range
            var membersByRankRange = new Dictionary<string, int>
            {
                  { "0-1.0", await _context.Members.CountAsync(m => m.RankLevel >= 0 && m.RankLevel < 1) },
                  { "1.0-2.0", await _context.Members.CountAsync(m => m.RankLevel >= 1 && m.RankLevel < 2) },
                  { "2.0-3.0", await _context.Members.CountAsync(m => m.RankLevel >= 2 && m.RankLevel < 3) },
                  { "3.0-4.0", await _context.Members.CountAsync(m => m.RankLevel >= 3 && m.RankLevel < 4) },
                  { "4.0-5.0", await _context.Members.CountAsync(m => m.RankLevel >= 4 && m.RankLevel <= 5) }
            };

            return Ok(new MemberStatsDto
            {
                  TotalMembers = totalMembers,
                  MembersByTier = membersByTierDict,
                  MembersByRankRange = membersByRankRange
            });
      }

      // GET /api/admin/wallet/pending-deposits
      [HttpGet("wallet/pending-deposits")]
      public async Task<IActionResult> GetPendingDeposits([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
      {
            var query = _context.WalletTransactions
                .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Pending)
                .OrderBy(t => t.CreatedDate);

            var totalItems = await query.CountAsync();
            var totalPages = (int)Math.Ceiling(totalItems / (double)pageSize);

            var deposits = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Include(t => t.Member)
                .Select(t => new PendingDepositDto
                {
                      TransactionId = t.Id,
                      MemberId = t.MemberId,
                      MemberName = t.Member != null ? t.Member.FullName : "",
                      Amount = t.Amount,
                      Description = t.Description,
                      ProofImageUrl = t.ProofImageUrl,
                      CreatedDate = t.CreatedDate
                })
                .ToListAsync();

            return Ok(new
            {
                  TotalItems = totalItems,
                  TotalPages = totalPages,
                  Page = page,
                  PageSize = pageSize,
                  Data = deposits
            });
      }
}
