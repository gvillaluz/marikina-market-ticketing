using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Request
{
    public class ChangePenaltyRequest
    {
        // Nullable so a missing value fails Required instead of meaning CashFine.
        [Required(ErrorMessage = "Invalid penalty type value.")]
        [EnumDataType(typeof(PenaltyType), ErrorMessage = "Invalid penalty type value.")]
        public PenaltyType? PenaltyType { get; set; }

        public int? CommunityServiceHours { get; set; }

        [Required(ErrorMessage = "Select a reason for the change.")]
        [EnumDataType(typeof(PenaltyChangeReason), ErrorMessage = "Select a reason for the change.")]
        public PenaltyChangeReason? Reason { get; set; }

        [Required(ErrorMessage = "Version is required for concurrency control.")]
        public uint Version { get; set; }
    }
}
