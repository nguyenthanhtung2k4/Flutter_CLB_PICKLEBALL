using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class TournamentParticipant
{
      [Key]
      public int Id { get; set; }

      public int TournamentId { get; set; }
      [ForeignKey("TournamentId")]
      public virtual Tournament? Tournament { get; set; }

      public int MemberId { get; set; }
      [ForeignKey("MemberId")]
      public virtual Member? Member { get; set; }

      public string? TeamName { get; set; } // For doubles

      public bool PaymentStatus { get; set; } // EntryFee deducted
}
