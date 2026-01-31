using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddBookingHold : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ProofImageUrl",
                table: "729_WalletTransactions",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "729_Notifications",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "AuthorId",
                table: "729_News",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "729_News",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "PublishedDate",
                table: "729_News",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "729_RankHistories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    OldRank = table.Column<double>(type: "float", nullable: false),
                    NewRank = table.Column<double>(type: "float", nullable: false),
                    ChangedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Reason = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    MatchId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_729_RankHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_729_RankHistories_729_Matches_MatchId",
                        column: x => x.MatchId,
                        principalTable: "729_Matches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_729_RankHistories_729_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "729_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_729_News_AuthorId",
                table: "729_News",
                column: "AuthorId");

            migrationBuilder.CreateIndex(
                name: "IX_729_RankHistories_MatchId",
                table: "729_RankHistories",
                column: "MatchId");

            migrationBuilder.CreateIndex(
                name: "IX_729_RankHistories_MemberId",
                table: "729_RankHistories",
                column: "MemberId");

            migrationBuilder.AddForeignKey(
                name: "FK_729_News_729_Members_AuthorId",
                table: "729_News",
                column: "AuthorId",
                principalTable: "729_Members",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_729_News_729_Members_AuthorId",
                table: "729_News");

            migrationBuilder.DropTable(
                name: "729_RankHistories");

            migrationBuilder.DropIndex(
                name: "IX_729_News_AuthorId",
                table: "729_News");

            migrationBuilder.DropColumn(
                name: "ProofImageUrl",
                table: "729_WalletTransactions");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "729_Notifications");

            migrationBuilder.DropColumn(
                name: "AuthorId",
                table: "729_News");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "729_News");

            migrationBuilder.DropColumn(
                name: "PublishedDate",
                table: "729_News");
        }
    }
}
