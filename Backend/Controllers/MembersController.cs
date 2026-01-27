using Backend.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class MembersController : ControllerBase
{
      private readonly AppDbContext _context;

      public MembersController(AppDbContext context)
      {
            _context = context;
      }

      // GET /api/members
      [HttpGet]
      public async Task<IActionResult> GetMembers([FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
      {
            var query = _context.Members.AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                  query = query.Where(m => m.FullName.Contains(search) || m.Id.ToString() == search);
            }

            var totalItems = await query.CountAsync();
            var totalPages = (int)Math.Ceiling(totalItems / (double)pageSize);

            var data = await query
                .OrderByDescending(m => m.RankLevel)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return Ok(new
            {
                  TotalItems = totalItems,
                  TotalPages = totalPages,
                  Page = page,
                  PageSize = pageSize,
                  Data = data
            });
      }

      // GET /api/members/{id}/profile
      [HttpGet("{id}/profile")]
      public async Task<IActionResult> GetProfile(int id)
      {
            var member = await _context.Members
                .FirstOrDefaultAsync(m => m.Id == id);

            if (member == null) return NotFound("Member not found");

            // Logic to get match history (simple version for now)
            var matches = await _context.Matches
                .Where(m => m.Team1_Player1Id == id || m.Team1_Player2Id == id ||
                            m.Team2_Player1Id == id || m.Team2_Player2Id == id)
                .OrderByDescending(m => m.Date)
                .Take(10)
                .ToListAsync();

            return Ok(new
            {
                  Member = member,
                  RecentMatches = matches,
                  // RankHistory = ... (Not implemented yet, would need a separate table or logs)
            });
      }
}
