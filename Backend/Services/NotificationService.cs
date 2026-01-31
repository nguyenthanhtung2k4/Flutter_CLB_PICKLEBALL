using Backend.Data;
using Backend.Enums;
using Backend.Hubs;
using Backend.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public class NotificationService
{
      private readonly AppDbContext _context;
      private readonly IHubContext<PcmHub> _hub;

      public NotificationService(AppDbContext context, IHubContext<PcmHub> hub)
      {
            _context = context;
            _hub = hub;
      }

      public async Task<Notification> NotifyMemberAsync(Member member, string message, NotificationType type, string? title = null, string? linkUrl = null)
      {
            var notification = new Notification
            {
                  ReceiverId = member.Id,
                  Title = title,
                  Message = message,
                  Type = type,
                  LinkUrl = linkUrl,
                  IsRead = false,
                  CreatedDate = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            if (!string.IsNullOrWhiteSpace(member.UserId))
            {
                  await _hub.Clients.User(member.UserId).SendAsync("ReceiveNotification", new
                  {
                        notification.Id,
                        notification.Title,
                        notification.Message,
                        notification.Type,
                        notification.LinkUrl,
                        notification.CreatedDate
                  });
            }
            else
            {
                  await _hub.Clients.All.SendAsync("ReceiveNotification", new
                  {
                        notification.Id,
                        notification.Title,
                        notification.Message,
                        notification.Type,
                        notification.LinkUrl,
                        notification.CreatedDate
                  });
            }

            return notification;
      }

      public Task BroadcastCalendarUpdate()
      {
            return _hub.Clients.All.SendAsync("UpdateCalendar");
      }

      public Task BroadcastMatchScore(object matchData)
      {
            return _hub.Clients.All.SendAsync("UpdateMatchScore", matchData);
      }
}
