using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

using Backend.Enums;

namespace Backend.Models;

public class Match
{
      [Key]
      public int Id { get; set; }

      public int? TournamentId { get; set; }
      [ForeignKey("TournamentId")]
      public virtual Tournament? Tournament { get; set; }

      public string RoundName { get; set; } = string.Empty; // Group A, QF, SF, Final

      public DateTime Date { get; set; }
      public TimeSpan StartTime { get; set; } // Or combine into DateTime

      // Participants (Singles or Doubles)
      public int? Team1_Player1Id { get; set; }
      public int? Team1_Player2Id { get; set; } // Nullable

      public int? Team2_Player1Id { get; set; }
      public int? Team2_Player2Id { get; set; } // Nullable

      // Result
      public int Score1 { get; set; }
      public int Score2 { get; set; }

      public string? Details { get; set; } // JSON: "11-9, 5-11, 11-8" (Set scores)

      public WinningSide WinningSide { get; set; }

      public bool IsRanked { get; set; } // Updates DUPR/RankLevel?

      // Status is often derived or explicit. PDF says Status: Scheduled, InProgress, Finished.
      public MatchStatus Status { get; set; } = MatchStatus.Scheduled;
}
