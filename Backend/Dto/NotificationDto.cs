using Backend.Enums;

namespace Backend.Dto;

public class NotificationResponseDto
{
      public int Id { get; set; }
      public int ReceiverId { get; set; }
      public string? Title { get; set; }
      public string Message { get; set; } = string.Empty;
      public NotificationType Type { get; set; }
      public string? LinkUrl { get; set; }
      public bool IsRead { get; set; }
      public DateTime CreatedDate { get; set; }
}

public class CreateNotificationDto
{
      public int ReceiverId { get; set; }
      public string? Title { get; set; }
      public string Message { get; set; } = string.Empty;
      public NotificationType Type { get; set; }
      public string? LinkUrl { get; set; }
}
