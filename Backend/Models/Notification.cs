using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Backend.Enums;

namespace Backend.Models;

public class Notification
{
      [Key]
      public int Id { get; set; }

      public int ReceiverId { get; set; }
      [ForeignKey("ReceiverId")]
      public virtual Member? Receiver { get; set; }

      [Required]
      public string Message { get; set; } = string.Empty;

      public NotificationType Type { get; set; }

      public string? LinkUrl { get; set; }

      public bool IsRead { get; set; } = false;

      public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
}
