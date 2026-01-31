using Backend.Enums;

namespace Backend.Dto;

public class MemberDto
{
      public int Id { get; set; }
      public string FullName { get; set; } = string.Empty;
      public string? AvatarUrl { get; set; }
      public double RankLevel { get; set; }
      public MemberTier Tier { get; set; }
      public bool IsActive { get; set; }
}

public class MemberProfileDto : MemberDto
{
      public DateTime JoinDate { get; set; }
      public decimal WalletBalance { get; set; }
      public decimal TotalSpent { get; set; }
      // Add more profile specific fields
}

public class RankHistoryDto
{
      public int Id { get; set; }
      public double OldRank { get; set; }
      public double NewRank { get; set; }
      public DateTime ChangedDate { get; set; }
      public string? Reason { get; set; }
      public int? MatchId { get; set; }
}

public class MemberProfileDetailDto
{
      public MemberProfileDto? Member { get; set; }
      public List<RankHistoryDto> RankHistory { get; set; } = new();
      public List<object> RecentMatches { get; set; } = new(); // Will be Match objects
}

public class UpdateMemberProfileDto
{
      public string? FullName { get; set; }
      public string? AvatarUrl { get; set; }
}

