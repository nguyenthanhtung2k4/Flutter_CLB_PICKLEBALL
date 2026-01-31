using Backend.Data;
using Backend.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace Backend.Services;

public class BookingHoldCleanupService : BackgroundService
{
      private readonly IServiceScopeFactory _scopeFactory;

      public BookingHoldCleanupService(IServiceScopeFactory scopeFactory)
      {
            _scopeFactory = scopeFactory;
      }

      protected override async Task ExecuteAsync(CancellationToken stoppingToken)
      {
            while (!stoppingToken.IsCancellationRequested)
            {
                  try
                  {
                        using var scope = _scopeFactory.CreateScope();
                        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                        var now = DateTime.UtcNow;
                        var expiredHolds = await context.Bookings
                            .Where(b => b.Status == BookingStatus.Holding && b.HoldUntil != null && b.HoldUntil < now)
                            .ToListAsync(stoppingToken);

                        if (expiredHolds.Count > 0)
                        {
                              foreach (var booking in expiredHolds)
                              {
                                    booking.Status = BookingStatus.Cancelled;
                                    booking.HoldUntil = null;
                              }

                              await context.SaveChangesAsync(stoppingToken);
                        }
                  }
                  catch
                  {
                        // Swallow exceptions to keep service running
                  }

                  await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
      }
}
