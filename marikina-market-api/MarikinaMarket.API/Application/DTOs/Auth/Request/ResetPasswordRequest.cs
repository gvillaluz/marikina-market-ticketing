using System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.API.Application.DTOs.Auth.Request
{
    public class ResetPasswordRequest
    {
        [Required(ErrorMessage = "Username must not be empty.")]
        [StringLength(50, ErrorMessage = "Username must not exceed 50 characters.")]
        public required string Username { get; set; }
        
        [Required(ErrorMessage = "New password must not be empty.")]
        [RegularExpression(@"^(?=.*\d)(?=.*[A-Z]).{8,}$", ErrorMessage = "Use at least 8 characters, with a number and a capital letter.")]
        public required string NewPassword { get; set; }

        [Required(ErrorMessage = "Reset token must not be empty.")]
        public required string ResetToken { get; set; }
    }
}