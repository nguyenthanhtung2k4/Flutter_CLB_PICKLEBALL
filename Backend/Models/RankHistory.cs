using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class RankHistory
{
      [Key]
      public int Id { get; set; }

      public int MemberId { get; set; }
      [ForeignKey("MemberId")]
      public virtual Member? Member { get; set; }

      public double OldRank { get; set; }
      public double NewRank { get; set; }

      public DateTime ChangedDate { get; set; } = DateTime.UtcNow;

      public string? Reason { get; set; } // "Match Win", "Match Loss", "Tournament", etc.

      public int? MatchId { get; set; }
      [ForeignKey("MatchId")]
      public virtual Match? Match { get; set; }
}
