using Backend.Data;
using Backend.Dto;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
      private readonly UserManager<IdentityUser> _userManager;
      private readonly SignInManager<IdentityUser> _signInManager;
      private readonly IConfiguration _configuration;
      private readonly AppDbContext _context;

      public AuthController(UserManager<IdentityUser> userManager, SignInManager<IdentityUser> signInManager, IConfiguration configuration, AppDbContext context)
      {
            _userManager = userManager;
            _signInManager = signInManager;
            _configuration = configuration;
            _context = context;
      }

      [HttpPost("login")]
      public async Task<IActionResult> Login([FromBody] LoginDto model)
      {
            var user = await _userManager.FindByNameAsync(model.Username);
            if (user != null && await _userManager.CheckPasswordAsync(user, model.Password))
            {
                  var userRoles = await _userManager.GetRolesAsync(user);

                  var authClaims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, user.UserName!),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(ClaimTypes.NameIdentifier, user.Id)
            };

                  foreach (var role in userRoles)
                  {
                        authClaims.Add(new Claim(ClaimTypes.Role, role));
                  }

                  var authSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));

                  var token = new JwtSecurityToken(
                      issuer: _configuration["Jwt:Issuer"],
                      audience: _configuration["Jwt:Audience"],
                      expires: DateTime.Now.AddMinutes(double.Parse(_configuration["Jwt:ExpireMinutes"]!)),
                      claims: authClaims,
                      signingCredentials: new SigningCredentials(authSigningKey, SecurityAlgorithms.HmacSha256)
                  );

                  return Ok(new
                  {
                        token = new JwtSecurityTokenHandler().WriteToken(token),
                        expiration = token.ValidTo,
                        user = new { user.Id, user.UserName, user.Email }
                  });
            }
            return Unauthorized();
      }

      [HttpGet("me")]
      [Authorize]
      public async Task<IActionResult> GetMe()
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

            if (member == null) return NotFound("Member profile not found.");

            return Ok(new
            {
                  member.Id,
                  member.FullName,
                  member.WalletBalance,
                  member.AvatarUrl,
                  member.Tier,
                  member.RankLevel,
                  // Include other necessary info
                  UserEmail = User.Identity?.Name
            });
      }

      [HttpPost("register")]
      public async Task<IActionResult> Register([FromBody] RegisterDto model)
      {
            var userExists = await _userManager.FindByNameAsync(model.Username);
            if (userExists != null)
                  return StatusCode(StatusCodes.Status500InternalServerError, new { Status = "Error", Message = "User already exists!" });

            IdentityUser user = new()
            {
                  Email = model.Email,
                  SecurityStamp = Guid.NewGuid().ToString(),
                  UserName = model.Username
            };
            var result = await _userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
                  return StatusCode(StatusCodes.Status500InternalServerError, new { Status = "Error", Message = "User creation failed! Please check user details and try again." });

            // Create Member Profile linked to this User
            var member = new Backend.Models.Member
            {
                  UserId = user.Id,
                  FullName = model.Username, // Use Username as default FullName
                  JoinDate = DateTime.UtcNow,
                  WalletBalance = 0,
                  Tier = Backend.Enums.MemberTier.Standard,
                  IsActive = true
            };

            _context.Members.Add(member);
            await _context.SaveChangesAsync();

            return Ok(new { Status = "Success", Message = "User created successfully!" });
      }
}
