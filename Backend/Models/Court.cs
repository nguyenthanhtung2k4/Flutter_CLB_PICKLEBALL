using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class Court
{
      [Key]
      public int Id { get; set; }

      [Required]
      public string Name { get; set; } = string.Empty;

      public bool IsActive { get; set; } = true;

      public string? Description { get; set; }

      [Column(TypeName = "decimal(18,2)")]
      public decimal PricePerHour { get; set; }
}
