using Backend.Data;
using Backend.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddSingleton<IUserIdProvider, NameIdentifierUserIdProvider>();
builder.Services.AddScoped<MemberTierService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddHostedService<BookingHoldCleanupService>();

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
      options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
      {
            OnMessageReceived = context =>
            {
                  var accessToken = context.Request.Query["access_token"];
                  var path = context.HttpContext.Request.Path;
                  if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/pcmHub"))
                  {
                        context.Token = accessToken;
                  }
                  return Task.CompletedTask;
            }
      };
});

// Swagger Configuration
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
      c.SwaggerDoc("v1", new OpenApiInfo { Title = "Pickleball Club Management API", Version = "v1" });
      c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
      {
            Name = "Authorization",
            Type = SecuritySchemeType.Http,
            Scheme = "Bearer",
            BearerFormat = "JWT",
            In = ParameterLocation.Header,
            Description = "JWT Authorization header using the Bearer scheme."
      });
      c.AddSecurityRequirement(new OpenApiSecurityRequirement
      {
            {
                  new OpenApiSecurityScheme
                  {
                        Reference = new OpenApiReference
                        {
                              Type = ReferenceType.SecurityScheme,
                              Id = "Bearer"
                        }
                  },
                  Array.Empty<string>()
            }
      });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
      app.UseSwagger();
      app.UseSwaggerUI();
}

// app.UseHttpsRedirection(); // Tắt HTTPS redirect để cho phép HTTP từ mobile app

app.UseStaticFiles();

// Enable CORS
app.UseCors("AllowAll");

app.UseAuthentication(); // Ensure Auth is used
app.UseAuthorization();

app.MapControllers();
app.MapHub<Backend.Hubs.PcmHub>("/pcmHub");

// Seed Data
using (var scope = app.Services.CreateScope())
{
      var services = scope.ServiceProvider;
      try
      {
            await Backend.Data.DbSeeder.Initialize(services);
      }
      catch (Exception ex)
      {
            var logger = services.GetRequiredService<ILogger<Program>>();
            logger.LogError(ex, "An error occurred seeding the DB.");
      }
}

app.Run();
