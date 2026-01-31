namespace Backend.Dto;

public class AdminDashboardStatsDto
{
      public decimal TotalRevenue { get; set; }
      public decimal MonthlyRevenue { get; set; }
      public int TotalBookings { get; set; }
      public int MonthlyBookings { get; set; }
      public int TotalMembers { get; set; }
      public int ActiveMembers { get; set; }
      public int PendingDeposits { get; set; }
}

public class RevenueChartDto
{
      public string Date { get; set; } = string.Empty;
      public decimal DepositAmount { get; set; }
      public decimal PaymentAmount { get; set; }
      public decimal RefundAmount { get; set; }
}

public class BookingStatsDto
{
      public int TotalBookings { get; set; }
      public int ConfirmedBookings { get; set; }
      public int CancelledBookings { get; set; }
      public Dictionary<string, int> BookingsByMonth { get; set; } = new();
}

public class MemberStatsDto
{
      public int TotalMembers { get; set; }
      public Dictionary<string, int> MembersByTier { get; set; } = new();
      public Dictionary<string, int> MembersByRankRange { get; set; } = new();
}

public class PendingDepositDto
{
      public int TransactionId { get; set; }
      public int MemberId { get; set; }
      public string MemberName { get; set; } = string.Empty;
      public decimal Amount { get; set; }
      public string? Description { get; set; }
      public string? ProofImageUrl { get; set; }
      public DateTime CreatedDate { get; set; }
}
