using System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.API.Application.DTOs.Auth.Request
{
    public class ChangePasswordRequest
    {
        [Required(ErrorMessage = "Current password is required.")]
        public required string CurrentPassword { get; set; }

        [Required(ErrorMessage = "New password is required.")]
        [RegularExpression(
            @"^(?=.*\d)(?=.*[A-Z]).{8,}$",
            ErrorMessage = "Use at least 8 characters, with a number and a capital letter."
        )]
        public required string NewPassword { get; set; }

        [Required(ErrorMessage = "Please confirm your new password.")]
        [Compare(nameof(NewPassword), ErrorMessage = "New password and confirmation do not match.")]
        public required string ConfirmNewPassword { get; set; }
    }
}
