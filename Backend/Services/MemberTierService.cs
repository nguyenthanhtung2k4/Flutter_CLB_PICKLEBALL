using Backend.Enums;
using Backend.Models;
using Microsoft.Extensions.Configuration;

namespace Backend.Services;

public class MemberTierService
{
      private readonly IConfiguration _configuration;

      public MemberTierService(IConfiguration configuration)
      {
            _configuration = configuration;
      }

      public MemberTier CalculateTier(decimal totalSpent)
      {
            var tierSection = _configuration.GetSection("TierSettings");

            var silver = tierSection.GetValue<decimal?>("Silver") ?? 2000000m;
            var gold = tierSection.GetValue<decimal?>("Gold") ?? 5000000m;
            var diamond = tierSection.GetValue<decimal?>("Diamond") ?? 10000000m;

            if (totalSpent >= diamond) return MemberTier.Diamond;
            if (totalSpent >= gold) return MemberTier.Gold;
            if (totalSpent >= silver) return MemberTier.Silver;
            return MemberTier.Standard;
      }

      public bool UpdateTier(Member member)
      {
            var newTier = CalculateTier(member.TotalSpent);
            if (member.Tier != newTier)
            {
                  member.Tier = newTier;
                  return true;
            }

            return false;
      }

      public bool IsVip(Member member)
      {
            return member.Tier == MemberTier.Gold || member.Tier == MemberTier.Diamond;
      }
}
