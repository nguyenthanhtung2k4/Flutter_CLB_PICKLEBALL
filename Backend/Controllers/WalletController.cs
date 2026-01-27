using Backend.Data;
using Backend.Enums;
using Backend.Models;
using Backend.Dto;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class WalletController : ControllerBase
{
      private readonly AppDbContext _context;

      public WalletController(AppDbContext context)
      {
            _context = context;
      }

      // POST /api/wallet/deposit
      [HttpPost("deposit")]
      [Authorize] // Require login
      public async Task<IActionResult> Deposit([FromBody] DepositRequestDto request)
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            // Find member by Identity UserId
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member profile not found for current user.");

            if (request.Amount <= 0) return BadRequest("Amount must be greater than 0.");

            var transaction = new WalletTransaction
            {
                  MemberId = member.Id,
                  Amount = request.Amount,
                  Type = TransactionType.Deposit,
                  Status = TransactionStatus.Pending,
                  Description = "Nạp tiền vào ví: " + request.Description,
                  // In a real app, handle ProofImage upload logic here or accept a URL
                  CreatedDate = DateTime.UtcNow
            };

            _context.WalletTransactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Deposit request submitted successfully.", TransactionId = transaction.Id });
      }

      // GET /api/wallet/transactions
      [HttpGet("transactions")]
      [Authorize]
      public async Task<IActionResult> GetTransactions()
      {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member == null) return BadRequest("Member not found.");

            var transactions = await _context.WalletTransactions
                .Where(t => t.MemberId == member.Id)
                .OrderByDescending(t => t.CreatedDate)
                .ToListAsync();

            return Ok(transactions);
      }

      // PUT /api/admin/wallet/approve/{id}
      // Note: This route structure implies it might be better in an Admin controller, but passing here is fine for now.
      // Ideally use [Route("/api/admin/wallet/approve/{id}")]
      [HttpPut("/api/admin/wallet/approve/{id}")]
      // [Authorize(Roles = "Admin")] // Uncomment when roles are set up
      public async Task<IActionResult> ApproveDeposit(int id)
      {
            var transaction = await _context.WalletTransactions.FindAsync(id);
            if (transaction == null) return NotFound("Transaction not found.");

            if (transaction.Status != TransactionStatus.Pending)
                  return BadRequest("Transaction is not in pending status.");

            if (transaction.Type != TransactionType.Deposit && transaction.Type != TransactionType.Reward)
                  return BadRequest("Only Deposit or Reward can be approved to add funds manually here.");

            var member = await _context.Members.FindAsync(transaction.MemberId);
            if (member == null) return BadRequest("Member linked to transaction not found.");

            // Execute Transaction
            member.WalletBalance += transaction.Amount;
            transaction.Status = TransactionStatus.Completed;

            // Save
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Transaction approved and funds added.", NewBalance = member.WalletBalance });
      }
}
