using Backend.Data;
using Backend.Dto;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class NewsController : ControllerBase
{
      private readonly AppDbContext _context;

      public NewsController(AppDbContext context)
      {
            _context = context;
      }

      // GET /api/news
      [HttpGet]
      public async Task<IActionResult> GetNews([FromQuery] int page = 1, [FromQuery] int pageSize = 10, [FromQuery] bool? pinnedOnly = null)
      {
            var query = _context.News.Where(n => n.IsActive);

            if (pinnedOnly == true)
            {
                  query = query.Where(n => n.IsPinned);
            }

            var totalItems = await query.CountAsync();
            var totalPages = (int)Math.Ceiling(totalItems / (double)pageSize);

            var news = await query
                .OrderByDescending(n => n.IsPinned)
                .ThenByDescending(n => n.PublishedDate ?? n.CreatedDate)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Include(n => n.Author)
                .Select(n => new NewsResponseDto
                {
                      Id = n.Id,
                      Title = n.Title,
                      Content = n.Content,
                      AuthorId = n.AuthorId,
                      AuthorName = n.Author != null ? n.Author.FullName : null,
                      IsPinned = n.IsPinned,
                      IsActive = n.IsActive,
                      CreatedDate = n.CreatedDate,
                      PublishedDate = n.PublishedDate,
                      ImageUrl = n.ImageUrl
                })
                .ToListAsync();

            return Ok(new
            {
                  TotalItems = totalItems,
                  TotalPages = totalPages,
                  Page = page,
                  PageSize = pageSize,
                  Data = news
            });
      }

      // GET /api/news/{id}
      [HttpGet("{id}")]
      public async Task<IActionResult> GetNewsById(int id)
      {
            var news = await _context.News
                .Include(n => n.Author)
                .Where(n => n.Id == id && n.IsActive)
                .Select(n => new NewsResponseDto
                {
                      Id = n.Id,
                      Title = n.Title,
                      Content = n.Content,
                      AuthorId = n.AuthorId,
                      AuthorName = n.Author != null ? n.Author.FullName : null,
                      IsPinned = n.IsPinned,
                      IsActive = n.IsActive,
                      CreatedDate = n.CreatedDate,
                      PublishedDate = n.PublishedDate,
                      ImageUrl = n.ImageUrl
                })
                .FirstOrDefaultAsync();

            if (news == null) return NotFound("News not found.");

            return Ok(news);
      }

      // POST /api/news (Admin only)
      [HttpPost]
      [Authorize(Roles = "Admin")]
      public async Task<IActionResult> CreateNews([FromBody] CreateNewsDto request)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null) return BadRequest("Member not found.");

            var news = new News
            {
                  Title = request.Title,
                  Content = request.Content,
                  AuthorId = member.Id,
                  IsPinned = request.IsPinned,
                  IsActive = true,
                  CreatedDate = DateTime.UtcNow,
                  PublishedDate = request.PublishedDate ?? DateTime.UtcNow,
                  ImageUrl = request.ImageUrl
            };

            _context.News.Add(news);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "News created successfully.", NewsId = news.Id });
      }

      // PUT /api/news/{id} (Admin only)
      [HttpPut("{id}")]
      [Authorize(Roles = "Admin")]
      public async Task<IActionResult> UpdateNews(int id, [FromBody] UpdateNewsDto request)
      {
            var news = await _context.News.FindAsync(id);
            if (news == null) return NotFound("News not found.");

            if (request.Title != null) news.Title = request.Title;
            if (request.Content != null) news.Content = request.Content;
            if (request.IsPinned.HasValue) news.IsPinned = request.IsPinned.Value;
            if (request.IsActive.HasValue) news.IsActive = request.IsActive.Value;
            if (request.ImageUrl != null) news.ImageUrl = request.ImageUrl;
            if (request.PublishedDate.HasValue) news.PublishedDate = request.PublishedDate;

            await _context.SaveChangesAsync();

            return Ok(new { Message = "News updated successfully." });
      }

      // DELETE /api/news/{id} (Admin only - Soft delete)
      [HttpDelete("{id}")]
      [Authorize(Roles = "Admin")]
      public async Task<IActionResult> DeleteNews(int id)
      {
            var news = await _context.News.FindAsync(id);
            if (news == null) return NotFound("News not found.");

            news.IsActive = false;
            await _context.SaveChangesAsync();

            return Ok(new { Message = "News deleted successfully." });
      }
}
