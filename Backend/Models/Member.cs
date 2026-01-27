using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Backend.Enums;
using Microsoft.AspNetCore.Identity;

namespace Backend.Models;

public class Member
{
      [Key]
      public int Id { get; set; }

      [Required]
      public string FullName { get; set; } = string.Empty;

      public DateTime JoinDate { get; set; } = DateTime.UtcNow;

      public double RankLevel { get; set; } = 0;

      public bool IsActive { get; set; } = true;

      // Link Identity
      public string UserId { get; set; } = string.Empty;
      [ForeignKey("UserId")]
      public virtual IdentityUser? User { get; set; }

      // Advanced (Wallet & Tier)
      [Column(TypeName = "decimal(18,2)")]
      public decimal WalletBalance { get; set; } = 0;

      public MemberTier Tier { get; set; } = MemberTier.Standard;

      [Column(TypeName = "decimal(18,2)")]
      public decimal TotalSpent { get; set; } = 0;

      public string? AvatarUrl { get; set; }
}
