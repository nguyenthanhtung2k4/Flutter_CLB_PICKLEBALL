using Backend.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CourtsController : ControllerBase
{
      private readonly AppDbContext _context;

      public CourtsController(AppDbContext context)
      {
            _context = context;
      }

      [HttpGet]
      public async Task<IActionResult> GetCourts()
      {
            var courts = await _context.Courts.Where(c => c.IsActive).ToListAsync();
            return Ok(courts);
      }
}
