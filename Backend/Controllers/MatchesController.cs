using Backend.Data;
using Backend.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class MatchesController : ControllerBase
{
      private readonly AppDbContext _context;

      public MatchesController(AppDbContext context)
      {
            _context = context;
      }

      // GET /api/matches/upcoming
      [HttpGet("upcoming")]
      [Authorize]
      public async Task<IActionResult> GetUpcomingMatches([FromQuery] int take = 10)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member not found.");

            var now = DateTime.UtcNow;

            var matches = await _context.Matches
                .Where(m =>
                      (m.Team1_Player1Id == member.Id || m.Team1_Player2Id == member.Id ||
                       m.Team2_Player1Id == member.Id || m.Team2_Player2Id == member.Id) &&
                      (m.Status == MatchStatus.Scheduled || m.Status == MatchStatus.InProgress))
                .Include(m => m.Tournament)
                .OrderBy(m => m.Date)
                .ThenBy(m => m.StartTime)
                .Take(take)
                .ToListAsync();

            var memberIds = matches.SelectMany(m => new[] { m.Team1_Player1Id, m.Team1_Player2Id, m.Team2_Player1Id, m.Team2_Player2Id })
                .Where(id => id.HasValue)
                .Select(id => id!.Value)
                .Distinct()
                .ToList();

            var memberNames = await _context.Members
                .Where(m => memberIds.Contains(m.Id))
                .ToDictionaryAsync(m => m.Id, m => m.FullName);

            var result = matches.Select(m => new
            {
                  m.Id,
                  TournamentName = m.Tournament != null ? m.Tournament.Name : "Friendly Match",
                  m.RoundName,
                  StartDateTime = m.Date.Date + m.StartTime,
                  Team1 = new[]
                  {
                        m.Team1_Player1Id.HasValue && memberNames.ContainsKey(m.Team1_Player1Id.Value) ? memberNames[m.Team1_Player1Id.Value] : null,
                        m.Team1_Player2Id.HasValue && memberNames.ContainsKey(m.Team1_Player2Id.Value) ? memberNames[m.Team1_Player2Id.Value] : null
                  }.Where(n => !string.IsNullOrEmpty(n)).ToList(),
                  Team2 = new[]
                  {
                        m.Team2_Player1Id.HasValue && memberNames.ContainsKey(m.Team2_Player1Id.Value) ? memberNames[m.Team2_Player1Id.Value] : null,
                        m.Team2_Player2Id.HasValue && memberNames.ContainsKey(m.Team2_Player2Id.Value) ? memberNames[m.Team2_Player2Id.Value] : null
                  }.Where(n => !string.IsNullOrEmpty(n)).ToList(),
                  m.Status
            }).ToList();

            return Ok(result);
      }
}
