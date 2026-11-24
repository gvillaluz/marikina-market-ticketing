using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Mvc;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Request
{
    public class DetectedViolationFilters
    {
        [MaxLength(200, ErrorMessage = "Search term must be 200 characters or fewer.")]
        public string? Search { get; set; }

        [EnumDataType(typeof(ViolationType), ErrorMessage = "Invalid violation type.")]
        public ViolationType? Type { get; set; }

        [FromQuery(Name = "market_section_id")]
        [Range(1, int.MaxValue, ErrorMessage = "Market street must be a positive number.")]
        public int? MarketSectionId { get; set; }

        [FromQuery(Name = "category_code")]
        [MaxLength(64, ErrorMessage = "Violation must be 64 characters or fewer.")]
        public string? CategoryCode { get; set; }
    }
}
