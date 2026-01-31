using Backend.Data;
using Backend.Dto;
using Backend.Models;
using Backend.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class NotificationsController : ControllerBase
{
      private readonly AppDbContext _context;

      public NotificationsController(AppDbContext context)
      {
            _context = context;
      }

      // GET /api/notifications
      [HttpGet]
      public async Task<IActionResult> GetNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null) return BadRequest("Member not found.");

            var query = _context.Notifications
                .Where(n => n.ReceiverId == member.Id)
                .OrderByDescending(n => n.CreatedDate);

            var totalItems = await query.CountAsync();
            var totalPages = (int)Math.Ceiling(totalItems / (double)pageSize);

            var notifications = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new NotificationResponseDto
                {
                      Id = n.Id,
                      ReceiverId = n.ReceiverId,
                      Title = n.Title,
                      Message = n.Message,
                      Type = n.Type,
                      LinkUrl = n.LinkUrl,
                      IsRead = n.IsRead,
                      CreatedDate = n.CreatedDate
                })
                .ToListAsync();

            return Ok(new
            {
                  TotalItems = totalItems,
                  TotalPages = totalPages,
                  Page = page,
                  PageSize = pageSize,
                  Data = notifications
            });
      }

      // PUT /api/notifications/{id}/read
      [HttpPut("{id}/read")]
      public async Task<IActionResult> MarkAsRead(int id)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null) return BadRequest("Member not found.");

            var notification = await _context.Notifications.FindAsync(id);
            if (notification == null) return NotFound("Notification not found.");

            if (notification.ReceiverId != member.Id) return Forbid();

            notification.IsRead = true;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Notification marked as read." });
      }

      // PUT /api/notifications/read-all
      [HttpPut("read-all")]
      public async Task<IActionResult> MarkAllAsRead()
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null) return BadRequest("Member not found.");

            var unreadNotifications = await _context.Notifications
                .Where(n => n.ReceiverId == member.Id && !n.IsRead)
                .ToListAsync();

            foreach (var notification in unreadNotifications)
            {
                  notification.IsRead = true;
            }

            await _context.SaveChangesAsync();

            return Ok(new { Message = "All notifications marked as read.", Count = unreadNotifications.Count });
      }

      // GET /api/notifications/unread-count
      [HttpGet("unread-count")]
      public async Task<IActionResult> GetUnreadCount()
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null) return BadRequest("Member not found.");

            var count = await _context.Notifications
                .CountAsync(n => n.ReceiverId == member.Id && !n.IsRead);

            return Ok(new { UnreadCount = count });
      }
}
