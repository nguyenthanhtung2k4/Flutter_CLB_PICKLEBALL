using Microsoft.AspNetCore.Identity;
using Backend.Models;
using Backend.Enums;

namespace Backend.Data;

public static class DbSeeder
{
      public static async Task Initialize(IServiceProvider serviceProvider)
      {
            var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();
            var userManager = serviceProvider.GetRequiredService<UserManager<IdentityUser>>();
            var context = serviceProvider.GetRequiredService<AppDbContext>();

            // Ensure database is created
            context.Database.EnsureCreated();

            // Seed Roles
            string[] roles = { "Admin", "User" };
            foreach (var roleName in roles)
            {
                  if (!await roleManager.RoleExistsAsync(roleName))
                  {
                        await roleManager.CreateAsync(new IdentityRole(roleName));
                  }
            }

            // Seed Admin User
            var adminUser = new IdentityUser
            {
                  UserName = "tungnt",
                  Email = "tungnt@example.com", // Dummy email
                  EmailConfirmed = true
            };

            var user = await userManager.FindByNameAsync(adminUser.UserName);
            if (user == null)
            {
                  var createPowerUser = await userManager.CreateAsync(adminUser, "tung292004");
                  if (createPowerUser.Succeeded)
                  {
                        await userManager.AddToRoleAsync(adminUser, "Admin");

                        // Also create a Member record for this user
                        var member = new Member
                        {
                              UserId = adminUser.Id,
                              FullName = "Nguyen Thanh Tung",
                              // Email not present in Member
                              JoinDate = DateTime.UtcNow,
                              WalletBalance = 10000000, // Rich admin
                              RankLevel = 100, // Max rank
                              Tier = MemberTier.Diamond
                        };
                        context.Members.Add(member);
                        await context.SaveChangesAsync();
                  }
            }
            else
            {
                  // Ensure existing user has Admin role
                  if (!await userManager.IsInRoleAsync(user, "Admin"))
                  {
                        await userManager.AddToRoleAsync(user, "Admin");
                  }
            }

            // Seed Courts
            if (!context.Courts.Any())
            {
                var courts = new List<Models.Court>
                {
                    new Models.Court { Name = "Sân 1", PricePerHour = 50000, IsActive = true, Description = "Sân tiêu chuẩn" },
                    new Models.Court { Name = "Sân 2", PricePerHour = 50000, IsActive = true, Description = "Sân tiêu chuẩn" },
                    new Models.Court { Name = "Sân 3", PricePerHour = 50000, IsActive = true, Description = "Sân tiêu chuẩn" },
                    new Models.Court { Name = "Sân VIP", PricePerHour = 80000, IsActive = true, Description = "Sân VIP có mái che" },
                };
                context.Courts.AddRange(courts);
                await context.SaveChangesAsync();
            }
      }
}
