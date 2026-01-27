using Backend.Enums;

namespace Backend.Dto;

public class TournamentDto
{
      public int Id { get; set; }
      public string Name { get; set; } = string.Empty;
      public DateTime StartDate { get; set; }
      public DateTime EndDate { get; set; }
      public TournamentFormat Format { get; set; }
      public decimal EntryFee { get; set; }
      public decimal PrizePool { get; set; }
      public TournamentStatus Status { get; set; }
      public string? Settings { get; set; }
}

public class CreateTournamentDto
{
      public string Name { get; set; } = string.Empty;
      public DateTime StartDate { get; set; }
      public DateTime EndDate { get; set; }
      public TournamentFormat Format { get; set; }
      public decimal EntryFee { get; set; }
      public decimal PrizePool { get; set; }
      public string? Settings { get; set; }
}

public class MatchResultDto
{
      public int Score1 { get; set; }
      public int Score2 { get; set; }
      public string? Details { get; set; }
      public WinningSide WinningSide { get; set; }
}
