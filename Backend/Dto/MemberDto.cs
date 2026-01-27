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
