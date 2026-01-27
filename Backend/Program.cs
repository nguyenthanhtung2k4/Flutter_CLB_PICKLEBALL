using Backend.Data;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddSignalR();

// CORS Configuration for Mobile App
builder.Services.AddCors(options =>
{
      options.AddPolicy("AllowAll", policy =>
      {
            policy.AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
      });
});

// Database Configuration
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("Default")));

// Identity Configuration
builder.Services.AddIdentity<IdentityUser, IdentityRole>(options =>
{
      // Password settings (relaxed for development)
      options.Password.RequireDigit = true;
      options.Password.RequireLowercase = true;
      options.Password.RequireNonAlphanumeric = false; // No special characters required
      options.Password.RequireUppercase = false; // No uppercase required
      options.Password.RequiredLength = 6;
      options.Password.RequiredUniqueChars = 0;
})
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

// JWT Configuration
var jwtSettings = builder.Configuration.GetSection("Jwt");
var key = System.Text.Encoding.ASCII.GetBytes(jwtSettings["Key"]!);

builder.Services.AddAuthentication(options =>
{
      options.DefaultAuthenticateScheme = Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerDefaults.AuthenticationScheme;
      options.DefaultChallengeScheme = Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
      options.RequireHttpsMetadata = false;
      options.SaveToken = true;
      options.TokenValidationParameters = new Microsoft.IdentityModel.Tokens.TokenValidationParameters
      {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(key),
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidIssuer = jwtSettings["Issuer"],
            ValidAudience = jwtSettings["Audience"],
            ClockSkew = TimeSpan.Zero
      };
});

// Swagger Configuration
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
      c.SwaggerDoc("v1", new OpenApiInfo { Title = "Pickleball Club Management API", Version = "v1" });
      // Add Security Definition for JWT later
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
      app.UseSwagger();
      app.UseSwaggerUI();
}

// app.UseHttpsRedirection(); // Tắt HTTPS redirect để cho phép HTTP từ mobile app

// Enable CORS
app.UseCors("AllowAll");

app.UseAuthentication(); // Ensure Auth is used
app.UseAuthorization();

app.MapControllers();
app.MapHub<Backend.Hubs.PcmHub>("/pcmHub");

app.Run();
