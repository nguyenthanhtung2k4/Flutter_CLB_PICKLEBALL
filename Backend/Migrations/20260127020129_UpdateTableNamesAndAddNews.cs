using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend.Migrations
{
    /// <inheritdoc />
    public partial class UpdateTableNamesAndAddNews : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Bookings_Courts_CourtId",
                table: "Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_Bookings_Members_MemberId",
                table: "Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_Bookings_WalletTransactions_TransactionId",
                table: "Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_Matches_Tournaments_TournamentId",
                table: "Matches");

            migrationBuilder.DropForeignKey(
                name: "FK_Members_AspNetUsers_UserId",
                table: "Members");

            migrationBuilder.DropForeignKey(
                name: "FK_Notifications_Members_ReceiverId",
                table: "Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_TournamentParticipants_Members_MemberId",
                table: "TournamentParticipants");

            migrationBuilder.DropForeignKey(
                name: "FK_TournamentParticipants_Tournaments_TournamentId",
                table: "TournamentParticipants");

            migrationBuilder.DropForeignKey(
                name: "FK_WalletTransactions_Members_MemberId",
                table: "WalletTransactions");

            migrationBuilder.DropPrimaryKey(
                name: "PK_WalletTransactions",
                table: "WalletTransactions");

            migrationBuilder.DropPrimaryKey(
                name: "PK_TransactionCategories",
                table: "TransactionCategories");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Tournaments",
                table: "Tournaments");

            migrationBuilder.DropPrimaryKey(
                name: "PK_TournamentParticipants",
                table: "TournamentParticipants");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Notifications",
                table: "Notifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Members",
                table: "Members");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Matches",
                table: "Matches");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Courts",
                table: "Courts");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Bookings",
                table: "Bookings");

            migrationBuilder.RenameTable(
                name: "WalletTransactions",
                newName: "729_WalletTransactions");

            migrationBuilder.RenameTable(
                name: "TransactionCategories",
                newName: "729_TransactionCategories");

            migrationBuilder.RenameTable(
                name: "Tournaments",
                newName: "729_Tournaments");

            migrationBuilder.RenameTable(
                name: "TournamentParticipants",
                newName: "729_TournamentParticipants");

            migrationBuilder.RenameTable(
                name: "Notifications",
                newName: "729_Notifications");

            migrationBuilder.RenameTable(
                name: "Members",
                newName: "729_Members");

            migrationBuilder.RenameTable(
                name: "Matches",
                newName: "729_Matches");

            migrationBuilder.RenameTable(
                name: "Courts",
                newName: "729_Courts");

            migrationBuilder.RenameTable(
                name: "Bookings",
                newName: "729_Bookings");

            migrationBuilder.RenameIndex(
                name: "IX_WalletTransactions_MemberId",
                table: "729_WalletTransactions",
                newName: "IX_729_WalletTransactions_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_TournamentParticipants_TournamentId",
                table: "729_TournamentParticipants",
                newName: "IX_729_TournamentParticipants_TournamentId");

            migrationBuilder.RenameIndex(
                name: "IX_TournamentParticipants_MemberId",
                table: "729_TournamentParticipants",
                newName: "IX_729_TournamentParticipants_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_Notifications_ReceiverId",
                table: "729_Notifications",
                newName: "IX_729_Notifications_ReceiverId");

            migrationBuilder.RenameIndex(
                name: "IX_Members_UserId",
                table: "729_Members",
                newName: "IX_729_Members_UserId");

            migrationBuilder.RenameIndex(
                name: "IX_Matches_TournamentId",
                table: "729_Matches",
                newName: "IX_729_Matches_TournamentId");

            migrationBuilder.RenameIndex(
                name: "IX_Bookings_TransactionId",
                table: "729_Bookings",
                newName: "IX_729_Bookings_TransactionId");

            migrationBuilder.RenameIndex(
                name: "IX_Bookings_MemberId",
                table: "729_Bookings",
                newName: "IX_729_Bookings_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_Bookings_CourtId",
                table: "729_Bookings",
                newName: "IX_729_Bookings_CourtId");

            migrationBuilder.AlterColumn<int>(
                name: "Status",
                table: "729_Matches",
                type: "int",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_WalletTransactions",
                table: "729_WalletTransactions",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_TransactionCategories",
                table: "729_TransactionCategories",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_Tournaments",
                table: "729_Tournaments",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_TournamentParticipants",
                table: "729_TournamentParticipants",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_Notifications",
                table: "729_Notifications",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_Members",
                table: "729_Members",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_Matches",
                table: "729_Matches",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_Courts",
                table: "729_Courts",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_729_Bookings",
                table: "729_Bookings",
                column: "Id");

            migrationBuilder.CreateTable(
                name: "729_News",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Title = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    IsPinned = table.Column<bool>(type: "bit", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_729_News", x => x.Id);
                });

            migrationBuilder.AddForeignKey(
                name: "FK_729_Bookings_729_Courts_CourtId",
                table: "729_Bookings",
                column: "CourtId",
                principalTable: "729_Courts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_729_Bookings_729_Members_MemberId",
                table: "729_Bookings",
                column: "MemberId",
                principalTable: "729_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_729_Bookings_729_WalletTransactions_TransactionId",
                table: "729_Bookings",
                column: "TransactionId",
                principalTable: "729_WalletTransactions",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_729_Matches_729_Tournaments_TournamentId",
                table: "729_Matches",
                column: "TournamentId",
                principalTable: "729_Tournaments",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_729_Members_AspNetUsers_UserId",
                table: "729_Members",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_729_Notifications_729_Members_ReceiverId",
                table: "729_Notifications",
                column: "ReceiverId",
                principalTable: "729_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_729_TournamentParticipants_729_Members_MemberId",
                table: "729_TournamentParticipants",
                column: "MemberId",
                principalTable: "729_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_729_TournamentParticipants_729_Tournaments_TournamentId",
                table: "729_TournamentParticipants",
                column: "TournamentId",
                principalTable: "729_Tournaments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_729_WalletTransactions_729_Members_MemberId",
                table: "729_WalletTransactions",
                column: "MemberId",
                principalTable: "729_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_729_Bookings_729_Courts_CourtId",
                table: "729_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_729_Bookings_729_Members_MemberId",
                table: "729_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_729_Bookings_729_WalletTransactions_TransactionId",
                table: "729_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_729_Matches_729_Tournaments_TournamentId",
                table: "729_Matches");

            migrationBuilder.DropForeignKey(
                name: "FK_729_Members_AspNetUsers_UserId",
                table: "729_Members");

            migrationBuilder.DropForeignKey(
                name: "FK_729_Notifications_729_Members_ReceiverId",
                table: "729_Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_729_TournamentParticipants_729_Members_MemberId",
                table: "729_TournamentParticipants");

            migrationBuilder.DropForeignKey(
                name: "FK_729_TournamentParticipants_729_Tournaments_TournamentId",
                table: "729_TournamentParticipants");

            migrationBuilder.DropForeignKey(
                name: "FK_729_WalletTransactions_729_Members_MemberId",
                table: "729_WalletTransactions");

            migrationBuilder.DropTable(
                name: "729_News");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_WalletTransactions",
                table: "729_WalletTransactions");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_TransactionCategories",
                table: "729_TransactionCategories");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_Tournaments",
                table: "729_Tournaments");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_TournamentParticipants",
                table: "729_TournamentParticipants");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_Notifications",
                table: "729_Notifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_Members",
                table: "729_Members");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_Matches",
                table: "729_Matches");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_Courts",
                table: "729_Courts");

            migrationBuilder.DropPrimaryKey(
                name: "PK_729_Bookings",
                table: "729_Bookings");

            migrationBuilder.RenameTable(
                name: "729_WalletTransactions",
                newName: "WalletTransactions");

            migrationBuilder.RenameTable(
                name: "729_TransactionCategories",
                newName: "TransactionCategories");

            migrationBuilder.RenameTable(
                name: "729_Tournaments",
                newName: "Tournaments");

            migrationBuilder.RenameTable(
                name: "729_TournamentParticipants",
                newName: "TournamentParticipants");

            migrationBuilder.RenameTable(
                name: "729_Notifications",
                newName: "Notifications");

            migrationBuilder.RenameTable(
                name: "729_Members",
                newName: "Members");

            migrationBuilder.RenameTable(
                name: "729_Matches",
                newName: "Matches");

            migrationBuilder.RenameTable(
                name: "729_Courts",
                newName: "Courts");

            migrationBuilder.RenameTable(
                name: "729_Bookings",
                newName: "Bookings");

            migrationBuilder.RenameIndex(
                name: "IX_729_WalletTransactions_MemberId",
                table: "WalletTransactions",
                newName: "IX_WalletTransactions_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_729_TournamentParticipants_TournamentId",
                table: "TournamentParticipants",
                newName: "IX_TournamentParticipants_TournamentId");

            migrationBuilder.RenameIndex(
                name: "IX_729_TournamentParticipants_MemberId",
                table: "TournamentParticipants",
                newName: "IX_TournamentParticipants_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_729_Notifications_ReceiverId",
                table: "Notifications",
                newName: "IX_Notifications_ReceiverId");

            migrationBuilder.RenameIndex(
                name: "IX_729_Members_UserId",
                table: "Members",
                newName: "IX_Members_UserId");

            migrationBuilder.RenameIndex(
                name: "IX_729_Matches_TournamentId",
                table: "Matches",
                newName: "IX_Matches_TournamentId");

            migrationBuilder.RenameIndex(
                name: "IX_729_Bookings_TransactionId",
                table: "Bookings",
                newName: "IX_Bookings_TransactionId");

            migrationBuilder.RenameIndex(
                name: "IX_729_Bookings_MemberId",
                table: "Bookings",
                newName: "IX_Bookings_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_729_Bookings_CourtId",
                table: "Bookings",
                newName: "IX_Bookings_CourtId");

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                table: "Matches",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddPrimaryKey(
                name: "PK_WalletTransactions",
                table: "WalletTransactions",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_TransactionCategories",
                table: "TransactionCategories",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Tournaments",
                table: "Tournaments",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_TournamentParticipants",
                table: "TournamentParticipants",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Notifications",
                table: "Notifications",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Members",
                table: "Members",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Matches",
                table: "Matches",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Courts",
                table: "Courts",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Bookings",
                table: "Bookings",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Bookings_Courts_CourtId",
                table: "Bookings",
                column: "CourtId",
                principalTable: "Courts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Bookings_Members_MemberId",
                table: "Bookings",
                column: "MemberId",
                principalTable: "Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Bookings_WalletTransactions_TransactionId",
                table: "Bookings",
                column: "TransactionId",
                principalTable: "WalletTransactions",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Matches_Tournaments_TournamentId",
                table: "Matches",
                column: "TournamentId",
                principalTable: "Tournaments",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Members_AspNetUsers_UserId",
                table: "Members",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Notifications_Members_ReceiverId",
                table: "Notifications",
                column: "ReceiverId",
                principalTable: "Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TournamentParticipants_Members_MemberId",
                table: "TournamentParticipants",
                column: "MemberId",
                principalTable: "Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TournamentParticipants_Tournaments_TournamentId",
                table: "TournamentParticipants",
                column: "TournamentId",
                principalTable: "Tournaments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_WalletTransactions_Members_MemberId",
                table: "WalletTransactions",
                column: "MemberId",
                principalTable: "Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
