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
public class TournamentsController : ControllerBase
{
      private readonly AppDbContext _context;

      public TournamentsController(AppDbContext context)
      {
            _context = context;
      }

      // POST /api/tournaments
      [HttpPost]
      [Authorize] // Usually Admin only
      public async Task<IActionResult> CreateTournament([FromBody] CreateTournamentDto request)
      {
            var tournament = new Tournament
            {
                  Name = request.Name,
                  StartDate = request.StartDate,
                  EndDate = request.EndDate,
                  Format = request.Format,
                  EntryFee = request.EntryFee,
                  PrizePool = request.PrizePool,
                  Settings = request.Settings,
                  Status = TournamentStatus.Open
            };

            _context.Tournaments.Add(tournament);
            await _context.SaveChangesAsync();
            return Ok(tournament);
      }

      // POST /api/tournaments/{id}/join
      [HttpPost("{id}/join")]
      [Authorize]
      public async Task<IActionResult> JoinTournament(int id, [FromQuery] string? teamName)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member not found.");

            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound("Tournament not found.");
            if (tournament.Status != TournamentStatus.Open && tournament.Status != TournamentStatus.Registering)
                  return BadRequest("Tournament registration is closed.");

            // Check if already joined
            var existing = await _context.TournamentParticipants
                .AnyAsync(tp => tp.TournamentId == id && tp.MemberId == member.Id);
            if (existing) return BadRequest("Already joined this tournament.");

            // Check balance
            if (member.WalletBalance < tournament.EntryFee)
                  return BadRequest("Insufficient balance for entry fee.");

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                  // Deduct Fee
                  if (tournament.EntryFee > 0)
                  {
                        member.WalletBalance -= tournament.EntryFee;
                        member.TotalSpent += tournament.EntryFee;

                        _context.WalletTransactions.Add(new WalletTransaction
                        {
                              MemberId = member.Id,
                              Amount = -tournament.EntryFee,
                              Type = TransactionType.Payment,
                              Status = TransactionStatus.Completed,
                              Description = $"Entry fee for {tournament.Name}",
                              RelatedId = tournament.Id.ToString(),
                              CreatedDate = DateTime.UtcNow
                        });
                  }

                  var participant = new TournamentParticipant
                  {
                        TournamentId = id,
                        MemberId = member.Id,
                        TeamName = teamName,
                        PaymentStatus = true
                  };
                  _context.TournamentParticipants.Add(participant);

                  await _context.SaveChangesAsync();
                  await transaction.CommitAsync();

                  return Ok(new { Message = "Joined tournament successfully." });
            }
            catch (Exception ex)
            {
                  await transaction.RollbackAsync();
                  return StatusCode(500, ex.Message);
            }
      }

      // POST /api/tournaments/{id}/generate-schedule
      [HttpPost("{id}/generate-schedule")]
      [Authorize]
      public async Task<IActionResult> GenerateSchedule(int id)
      {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();

            var participants = await _context.TournamentParticipants
                .Where(tp => tp.TournamentId == id)
                .ToListAsync();

            if (participants.Count < 2) return BadRequest("Not enough participants.");

            // Basic logic: Pair them up for Round 1
            // In a real app, this would be much more complex based on Format (RoundRobin/Knockout)
            var matches = new List<Match>();
            for (int i = 0; i < participants.Count; i += 2)
            {
                  if (i + 1 < participants.Count)
                  {
                        matches.Add(new Match
                        {
                              TournamentId = id,
                              RoundName = "Round 1",
                              Date = tournament.StartDate,
                              Team1_Player1Id = participants[i].MemberId,
                              Team2_Player1Id = participants[i + 1].MemberId,
                              Status = MatchStatus.Scheduled,
                              WinningSide = WinningSide.None
                        });
                  }
            }

            _context.Matches.AddRange(matches);
            tournament.Status = TournamentStatus.DrawCompleted;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Schedule generated.", MatchCount = matches.Count });
      }

      // POST /api/matches/{id}/result
      [HttpPost("/api/matches/{id}/result")]
      [Authorize]
      public async Task<IActionResult> UpdateMatchResult(int id, [FromBody] MatchResultDto result)
      {
            var match = await _context.Matches.FindAsync(id);
            if (match == null) return NotFound();

            match.Score1 = result.Score1;
            match.Score2 = result.Score2;
            match.Details = result.Details;
            match.WinningSide = result.WinningSide;
            match.Status = MatchStatus.Finished;

            // Logic: Update Ranking Points?
            // If match.IsRanked... update member.RankLevel

            await _context.SaveChangesAsync();

            // Notify via SignalR (to be implemented)
            // _hubContext.Clients.All.SendAsync("UpdateMatchScore", match);

            return Ok(match);
      }
}
