using Backend.Enums;

namespace Backend.Dto;

public class CreateBookingDto
{
      public int CourtId { get; set; }
      public DateTime StartTime { get; set; }
      public DateTime EndTime { get; set; }
}

public class HoldBookingDto : CreateBookingDto
{
      // Hold duration in minutes (optional, default 5)
      public int HoldMinutes { get; set; } = 5;
}

public class RecurringBookingDto : CreateBookingDto
{
      // "Daily", "Weekly"
      public string Frequency { get; set; } = "Weekly";
      public DateTime RecurUntil { get; set; }
      public List<DayOfWeek> DaysOfWeek { get; set; } = new();
}

public class BookingDto
{
      public int Id { get; set; }
      public int CourtId { get; set; }
      public string CourtName { get; set; } = string.Empty;
      public DateTime StartTime { get; set; }
      public DateTime EndTime { get; set; }
      public BookingStatus Status { get; set; }
      public string MemberName { get; set; } = string.Empty;
      public int MemberId { get; set; }
      public DateTime? HoldUntil { get; set; }
}
