using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Backend.Enums;

namespace Backend.Models;

public class Tournament
{
      [Key]
      public int Id { get; set; }

      [Required]
      public string Name { get; set; } = string.Empty;

      public DateTime StartDate { get; set; }
      public DateTime EndDate { get; set; }

      public TournamentFormat Format { get; set; }

      [Column(TypeName = "decimal(18,2)")]
      public decimal EntryFee { get; set; }

      [Column(TypeName = "decimal(18,2)")]
      public decimal PrizePool { get; set; }

      public TournamentStatus Status { get; set; }

      public string? Settings { get; set; } // JSON: { "NumGroups": 4, "KnockoutTeams": 8 }
}
