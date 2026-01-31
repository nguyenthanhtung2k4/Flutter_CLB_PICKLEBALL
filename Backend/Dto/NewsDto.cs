namespace Backend.Dto;

public class NewsResponseDto
{
      public int Id { get; set; }
      public string Title { get; set; } = string.Empty;
      public string Content { get; set; } = string.Empty;
      public int? AuthorId { get; set; }
      public string? AuthorName { get; set; }
      public bool IsPinned { get; set; }
      public bool IsActive { get; set; }
      public DateTime CreatedDate { get; set; }
      public DateTime? PublishedDate { get; set; }
      public string? ImageUrl { get; set; }
}

public class CreateNewsDto
{
      public string Title { get; set; } = string.Empty;
      public string Content { get; set; } = string.Empty;
      public bool IsPinned { get; set; } = false;
      public string? ImageUrl { get; set; }
      public DateTime? PublishedDate { get; set; }
}

public class UpdateNewsDto
{
      public string? Title { get; set; }
      public string? Content { get; set; }
      public bool? IsPinned { get; set; }
      public bool? IsActive { get; set; }
      public string? ImageUrl { get; set; }
      public DateTime? PublishedDate { get; set; }
}
