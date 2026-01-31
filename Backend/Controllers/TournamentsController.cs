using Backend.Data;
using Backend.Enums;
using Backend.Models;
using Backend.Dto;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using System.Text.Json;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class TournamentsController : ControllerBase
{
      private readonly AppDbContext _context;
      private readonly MemberTierService _tierService;
      private readonly NotificationService _notificationService;

      public TournamentsController(AppDbContext context, MemberTierService tierService, NotificationService notificationService)
      {
            _context = context;
            _tierService = tierService;
            _notificationService = notificationService;
      }

      private static int? GetSettingInt(string? settings, string key)
      {
            if (string.IsNullOrWhiteSpace(settings)) return null;
            try
            {
                  using var doc = JsonDocument.Parse(settings);
                  if (doc.RootElement.TryGetProperty(key, out var element) && element.TryGetInt32(out var value))
                  {
                        return value;
                  }
            }
            catch
            {
                  // Ignore invalid JSON
            }
            return null;
      }

      private static string GetKnockoutRoundName(int participantCount)
      {
            return participantCount switch
            {
                  2 => "Final",
                  4 => "Semi Final",
                  8 => "Quarter Final",
                  16 => "Round of 16",
                  32 => "Round of 32",
                  _ => "Round 1"
            };
      }

      private async Task ApplyRankChangeAsync(int memberId, double delta, int matchId, string reason)
      {
            var member = await _context.Members.FindAsync(memberId);
            if (member == null) return;

            var oldRank = member.RankLevel;
            var newRank = Math.Max(0, oldRank + delta);
            member.RankLevel = newRank;

            _context.RankHistories.Add(new RankHistory
            {
                  MemberId = memberId,
                  OldRank = oldRank,
                  NewRank = newRank,
                  ChangedDate = DateTime.UtcNow,
                  Reason = reason,
                  MatchId = matchId
            });
      }

      private async Task DistributePrizePoolAsync(Tournament tournament, List<int> winnerIds)
      {
            if (tournament.PrizePool <= 0 || winnerIds.Count == 0) return;

            var uniqueWinners = winnerIds.Distinct().ToList();
            var prizeEach = tournament.PrizePool / uniqueWinners.Count;

            foreach (var winnerId in uniqueWinners)
            {
                  var member = await _context.Members.FindAsync(winnerId);
                  if (member == null) continue;

                  member.WalletBalance += prizeEach;
                  _context.WalletTransactions.Add(new WalletTransaction
                  {
                        MemberId = member.Id,
                        Amount = prizeEach,
                        Type = TransactionType.Reward,
                        Status = TransactionStatus.Completed,
                        Description = $"Prize for tournament {tournament.Name}",
                        RelatedId = tournament.Id.ToString(),
                        CreatedDate = DateTime.UtcNow
                  });

                  await _notificationService.NotifyMemberAsync(
                        member,
                        $"ChÃºc má»«ng báº¡n nháº­n thÆ°á»Ÿng: +{prizeEach:n0} VNÄ",
                        NotificationType.Success,
                        "ThÆ°á»Ÿng giáº£i Ä‘áº¥u",
                        "/wallet"
                  );
            }
      }

      // GET /api/tournaments
      [HttpGet]
      public async Task<IActionResult> GetTournaments([FromQuery] string? status)
      {
            var query = _context.Tournaments.AsQueryable();

            if (!string.IsNullOrWhiteSpace(status) && Enum.TryParse<TournamentStatus>(status, true, out var st))
            {
                  query = query.Where(t => t.Status == st);
            }

            var list = await query
                .OrderByDescending(t => t.StartDate)
                .Select(t => new
                {
                      t.Id,
                      t.Name,
                      t.StartDate,
                      t.EndDate,
                      t.Format,
                      t.EntryFee,
                      t.PrizePool,
                      t.Status,
                      t.Settings,
                      CurrentParticipants = _context.TournamentParticipants.Count(tp => tp.TournamentId == t.Id)
                })
                .ToListAsync();

            var result = list.Select(t => new
            {
                  t.Id,
                  t.Name,
                  t.StartDate,
                  t.EndDate,
                  t.Format,
                  t.EntryFee,
                  t.PrizePool,
                  t.Status,
                  t.Settings,
                  t.CurrentParticipants,
                  MaxParticipants = GetSettingInt(t.Settings, "MaxParticipants")
            });

            return Ok(new { Data = result });
      }

      // GET /api/tournaments/{id}
      [HttpGet("{id}")]
      public async Task<IActionResult> GetTournamentDetail(int id)
      {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();

            var participants = await _context.TournamentParticipants
                .Where(tp => tp.TournamentId == id)
                .Include(tp => tp.Member)
                .Select(tp => new
                {
                      tp.Id,
                      tp.MemberId,
                      MemberName = tp.Member != null ? tp.Member.FullName : "",
                      tp.TeamName,
                      tp.PaymentStatus
                })
                .ToListAsync();

            var matches = await _context.Matches
                .Where(m => m.TournamentId == id)
                .OrderBy(m => m.Date)
                .ThenBy(m => m.StartTime)
                .ToListAsync();

            return Ok(new
            {
                  Tournament = tournament,
                  Participants = participants,
                  Matches = matches,
                  CurrentParticipants = participants.Count,
                  MaxParticipants = GetSettingInt(tournament.Settings, "MaxParticipants")
            });
      }

      // POST /api/tournaments
      [HttpPost]
      [Authorize(Roles = "Admin")]
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

            var maxParticipants = GetSettingInt(tournament.Settings, "MaxParticipants");
            if (maxParticipants.HasValue)
            {
                  var currentCount = await _context.TournamentParticipants.CountAsync(tp => tp.TournamentId == id);
                  if (currentCount >= maxParticipants.Value)
                        return BadRequest("Tournament is full.");
            }

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
                        _tierService.UpdateTier(member);

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

                  await _notificationService.NotifyMemberAsync(
                        member,
                        $"ÄÄƒng kÃ½ giáº£i Ä‘áº¥u thÃ nh cÃ´ng: {tournament.Name}",
                        NotificationType.Success,
                        "Tham gia giáº£i Ä‘áº¥u",
                        "/tournaments"
                  );

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
      [Authorize(Roles = "Admin")]
      public async Task<IActionResult> GenerateSchedule(int id)
      {
            var tournament = await _context.Tournaments.FindAsync(id);
            if (tournament == null) return NotFound();

            var participants = await _context.TournamentParticipants
                .Where(tp => tp.TournamentId == id)
                .ToListAsync();

            if (participants.Count < 2) return BadRequest("Not enough participants.");

            // Remove existing matches for re-generate
            var existingMatches = _context.Matches.Where(m => m.TournamentId == id);
            _context.Matches.RemoveRange(existingMatches);
            await _context.SaveChangesAsync();

            // Shuffle participants
            var rng = new Random();
            participants = participants.OrderBy(_ => rng.Next()).ToList();

            var matches = new List<Match>();
            if (tournament.Format == TournamentFormat.RoundRobin || tournament.Format == TournamentFormat.Hybrid)
            {
                  var numGroups = GetSettingInt(tournament.Settings, "NumGroups") ?? 1;
                  numGroups = Math.Clamp(numGroups, 1, participants.Count);

                  var groups = new List<List<TournamentParticipant>>();
                  for (int i = 0; i < numGroups; i++) groups.Add(new List<TournamentParticipant>());

                  for (int i = 0; i < participants.Count; i++)
                  {
                        groups[i % numGroups].Add(participants[i]);
                  }

                  for (int g = 0; g < groups.Count; g++)
                  {
                        var group = groups[g];
                        var roundName = numGroups > 1 ? $"Group {(char)('A' + g)}" : "Round Robin";

                        for (int i = 0; i < group.Count; i++)
                        {
                              for (int j = i + 1; j < group.Count; j++)
                              {
                                    matches.Add(new Match
                                    {
                                          TournamentId = id,
                                          RoundName = roundName,
                                          Date = tournament.StartDate,
                                          StartTime = TimeSpan.Zero,
                                          Team1_Player1Id = group[i].MemberId,
                                          Team2_Player1Id = group[j].MemberId,
                                          Status = MatchStatus.Scheduled,
                                          WinningSide = WinningSide.None
                                    });
                              }
                        }
                  }
            }

            if (tournament.Format == TournamentFormat.Knockout)
            {
                  var roundName = GetKnockoutRoundName(participants.Count);
                  for (int i = 0; i < participants.Count; i += 2)
                  {
                        if (i + 1 < participants.Count)
                        {
                              matches.Add(new Match
                              {
                                    TournamentId = id,
                                    RoundName = roundName,
                                    Date = tournament.StartDate,
                                    StartTime = TimeSpan.Zero,
                                    Team1_Player1Id = participants[i].MemberId,
                                    Team2_Player1Id = participants[i + 1].MemberId,
                                    Status = MatchStatus.Scheduled,
                                    WinningSide = WinningSide.None
                              });
                        }
                  }
            }

            _context.Matches.AddRange(matches);
            tournament.Status = TournamentStatus.DrawCompleted;
            await _context.SaveChangesAsync();

            await _notificationService.BroadcastMatchScore(new { TournamentId = id, MatchCount = matches.Count });

            return Ok(new { Message = "Schedule generated.", MatchCount = matches.Count });
      }

      // POST /api/matches/{id}/result
      [HttpPost("/api/matches/{id}/result")]
      [Authorize(Roles = "Admin")]
      public async Task<IActionResult> UpdateMatchResult(int id, [FromBody] MatchResultDto result)
      {
            var match = await _context.Matches.FindAsync(id);
            if (match == null) return NotFound();

            match.Score1 = result.Score1;
            match.Score2 = result.Score2;
            match.Details = result.Details;
            match.WinningSide = result.WinningSide;
            match.Status = MatchStatus.Finished;

            if (match.IsRanked && match.WinningSide != WinningSide.None)
            {
                  var delta = 0.1;
                  var team1 = new[] { match.Team1_Player1Id, match.Team1_Player2Id }.Where(x => x.HasValue).Select(x => x!.Value).ToList();
                  var team2 = new[] { match.Team2_Player1Id, match.Team2_Player2Id }.Where(x => x.HasValue).Select(x => x!.Value).ToList();

                  if (match.WinningSide == WinningSide.Team1)
                  {
                        foreach (var id1 in team1) await ApplyRankChangeAsync(id1, delta, match.Id, "Match Win");
                        foreach (var id2 in team2) await ApplyRankChangeAsync(id2, -delta, match.Id, "Match Loss");
                  }
                  else if (match.WinningSide == WinningSide.Team2)
                  {
                        foreach (var id2 in team2) await ApplyRankChangeAsync(id2, delta, match.Id, "Match Win");
                        foreach (var id1 in team1) await ApplyRankChangeAsync(id1, -delta, match.Id, "Match Loss");
                  }
            }

            if (match.TournamentId.HasValue)
            {
                  var tournament = await _context.Tournaments.FindAsync(match.TournamentId.Value);
                  if (tournament != null && tournament.Status == TournamentStatus.DrawCompleted)
                  {
                        tournament.Status = TournamentStatus.Ongoing;
                  }

                  if (tournament != null && tournament.Status != TournamentStatus.Finished &&
                      match.RoundName.Contains("Final", StringComparison.OrdinalIgnoreCase))
                  {
                        var winners = match.WinningSide == WinningSide.Team1
                              ? new[] { match.Team1_Player1Id, match.Team1_Player2Id }
                              : new[] { match.Team2_Player1Id, match.Team2_Player2Id };

                        var winnerIds = winners.Where(x => x.HasValue).Select(x => x!.Value).ToList();
                        await DistributePrizePoolAsync(tournament, winnerIds);
                        tournament.Status = TournamentStatus.Finished;
                  }

                  if (tournament != null && tournament.Status != TournamentStatus.Finished)
                  {
                        var anyRemaining = await _context.Matches.AnyAsync(m => m.TournamentId == tournament.Id && m.Status != MatchStatus.Finished);
                        if (!anyRemaining)
                        {
                              tournament.Status = TournamentStatus.Finished;
                        }
                  }
            }

            await _context.SaveChangesAsync();

            await _notificationService.BroadcastMatchScore(new
            {
                  match.Id,
                  match.TournamentId,
                  match.RoundName,
                  match.Score1,
                  match.Score2,
                  match.WinningSide,
                  match.Status
            });

            var notifyIds = new[] { match.Team1_Player1Id, match.Team1_Player2Id, match.Team2_Player1Id, match.Team2_Player2Id }
                .Where(x => x.HasValue)
                .Select(x => x!.Value)
                .Distinct()
                .ToList();

            foreach (var memberId in notifyIds)
            {
                  var member = await _context.Members.FindAsync(memberId);
                  if (member == null) continue;
                  await _notificationService.NotifyMemberAsync(
                        member,
                        $"Káº¿t quáº£ tráº­n Ä‘áº¥u Ä‘Ã£ cÃ³: {match.Score1}-{match.Score2}",
                        NotificationType.Info,
                        "Cáº­p nháº­t káº¿t quáº£",
                        "/tournaments"
                  );
            }

            return Ok(match);
      }
}
