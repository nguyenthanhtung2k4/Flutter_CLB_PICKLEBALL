using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Backend.Enums;

namespace Backend.Models;

public class TransactionCategory
{
      [Key]
      public int Id { get; set; }

      [Required]
      public string Name { get; set; } = string.Empty;

      public TransactionCategoryType Type { get; set; }
}
