using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Backend.Enums;

namespace Backend.Models;

public class Booking
{
      [Key]
      public int Id { get; set; }

      public int CourtId { get; set; }
      [ForeignKey("CourtId")]
      public virtual Court? Court { get; set; }

      public int MemberId { get; set; }
      [ForeignKey("MemberId")]
      public virtual Member? Member { get; set; }

      public DateTime StartTime { get; set; }
      public DateTime EndTime { get; set; }

      [Column(TypeName = "decimal(18,2)")]
      public decimal TotalPrice { get; set; }

      public int? TransactionId { get; set; }
      [ForeignKey("TransactionId")]
      public virtual WalletTransaction? Transaction { get; set; }

      // Recurring Logic
      public bool IsRecurring { get; set; }
      public string? RecurrenceRule { get; set; } // e.g., "Weekly;Tue,Thu"
      public int? ParentBookingId { get; set; }

      // Hold Slot (5 minutes)
      public DateTime? HoldUntil { get; set; }

      public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;
}
