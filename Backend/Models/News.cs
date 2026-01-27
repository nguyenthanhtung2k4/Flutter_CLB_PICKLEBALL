using System.ComponentModel.DataAnnotations;

namespace Backend.Models;

public class News
{
      [Key]
      public int Id { get; set; }

      [Required]
      public string Title { get; set; } = string.Empty;

      [Required]
      public string Content { get; set; } = string.Empty;

      public bool IsPinned { get; set; } = false;

      public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

      public string? ImageUrl { get; set; }
}
