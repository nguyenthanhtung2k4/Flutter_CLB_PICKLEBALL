using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Backend.Models;

public class News
{
      [Key]
      public int Id { get; set; }

      [Required]
      public string Title { get; set; } = string.Empty;

      [Required]
      public string Content { get; set; } = string.Empty;

      public int? AuthorId { get; set; } // Member who created this news (Admin)
      [ForeignKey("AuthorId")]
      public virtual Member? Author { get; set; }

      public bool IsPinned { get; set; } = false;

      public bool IsActive { get; set; } = true; // Soft delete

      public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

      public DateTime? PublishedDate { get; set; }

      public string? ImageUrl { get; set; }
}
