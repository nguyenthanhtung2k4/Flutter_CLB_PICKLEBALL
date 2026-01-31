using Backend.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace Backend.Data;

public class AppDbContext : IdentityDbContext<IdentityUser>
{
      public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
      {
      }

      public DbSet<Member> Members { get; set; }
      public DbSet<WalletTransaction> WalletTransactions { get; set; }
      public DbSet<Court> Courts { get; set; }
      public DbSet<Booking> Bookings { get; set; }
      public DbSet<Tournament> Tournaments { get; set; }
      public DbSet<TournamentParticipant> TournamentParticipants { get; set; }
      public DbSet<Match> Matches { get; set; }
      public DbSet<Notification> Notifications { get; set; }
      public DbSet<TransactionCategory> TransactionCategories { get; set; }
      public DbSet<News> News { get; set; }
      public DbSet<RankHistory> RankHistories { get; set; }

      protected override void OnModelCreating(ModelBuilder builder)
      {
            base.OnModelCreating(builder);

            // Table Names with 3-digit MSSV prefix: 729
            builder.Entity<Member>().ToTable("729_Members");
            builder.Entity<WalletTransaction>().ToTable("729_WalletTransactions");
            builder.Entity<News>().ToTable("729_News");
            builder.Entity<TransactionCategory>().ToTable("729_TransactionCategories");
            builder.Entity<Court>().ToTable("729_Courts");
            builder.Entity<Booking>().ToTable("729_Bookings");
            builder.Entity<Tournament>().ToTable("729_Tournaments");
            builder.Entity<TournamentParticipant>().ToTable("729_TournamentParticipants");
            builder.Entity<Match>().ToTable("729_Matches");
            builder.Entity<Notification>().ToTable("729_Notifications");
            builder.Entity<RankHistory>().ToTable("729_RankHistories");

            // Configure relationships/constraints if needed
            builder.Entity<Booking>()
                .Property(b => b.TotalPrice)
                .HasColumnType("decimal(18,2)");

            // Decimal configurations to avoid warnings
            builder.Entity<Member>()
                .Property(m => m.WalletBalance)
                .HasColumnType("decimal(18,2)");
            builder.Entity<Member>()
                .Property(m => m.TotalSpent)
                .HasColumnType("decimal(18,2)");
            builder.Entity<WalletTransaction>()
                .Property(w => w.Amount)
                .HasColumnType("decimal(18,2)");
            builder.Entity<Court>()
                 .Property(c => c.PricePerHour)
                 .HasColumnType("decimal(18,2)");
            builder.Entity<Tournament>()
                 .Property(t => t.EntryFee)
                 .HasColumnType("decimal(18,2)");
            builder.Entity<Tournament>()
                 .Property(t => t.PrizePool)
                 .HasColumnType("decimal(18,2)");
      }
}
