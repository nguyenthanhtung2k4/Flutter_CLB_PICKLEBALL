using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Backend.Enums;

namespace Backend.Models;

public class WalletTransaction
{
      [Key]
      public int Id { get; set; }

      public int MemberId { get; set; }
      [ForeignKey("MemberId")]
      public virtual Member? Member { get; set; }

      [Column(TypeName = "decimal(18,2)")]
      public decimal Amount { get; set; }

      public TransactionType Type { get; set; }

      public TransactionStatus Status { get; set; }

      public string? RelatedId { get; set; } // BookingId or TournamentId

      public string? Description { get; set; }

      public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
