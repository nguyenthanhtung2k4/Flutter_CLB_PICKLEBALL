using Microsoft.AspNetCore.SignalR;

namespace Backend.Hubs;

public class PcmHub : Hub
{
      public async Task SendNotification(string message)
      {
            await Clients.All.SendAsync("ReceiveNotification", message);
      }

      public async Task UpdateCalendar()
      {
            await Clients.All.SendAsync("UpdateCalendar");
      }

      public async Task UpdateMatchScore(object matchData)
      {
            await Clients.All.SendAsync("UpdateMatchScore", matchData);
      }
}
