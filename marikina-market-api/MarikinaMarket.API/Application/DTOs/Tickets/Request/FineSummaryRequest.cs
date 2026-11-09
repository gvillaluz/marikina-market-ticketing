using System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Request
{
    public class FineSummaryRequest
    {
        [Required(ErrorMessage = "Ordinance IDs are required.")]
        [MinLength(1, ErrorMessage = "At least one ordinance must be selected.")]
        public required List<int> OrdinanceIds { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Vendor ID must be a valid positive number.")]
        public int? VendorId { get; set; }
        [Range(1, int.MaxValue)] public int? PersonId { get; set; }
    }
}
