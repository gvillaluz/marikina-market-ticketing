using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Request
{
    public class CreateTicketRequest
    {
        [FromForm(Name = "vendor_id")]
        [Required(ErrorMessage = "Vendor's information is required.")]
        [Range(1, int.MaxValue, ErrorMessage = "Vendor's information is required.")]
        public int VendorId { get; set; }

        [FromForm(Name = "person_id"), Range(1, int.MaxValue)]
        public int? PersonId { get; set; }
        [FromForm(Name = "paper_violator_name"), StringLength(200)]
        public string? PaperViolatorName { get; set; }
        [FromForm(Name = "paper_reference"), StringLength(200)]
        public string? PaperReference { get; set; }
        [FromForm(Name = "issue_place"), StringLength(500)]
        public string? IssuePlace { get; set; }
        [FromForm(Name = "reviewed_business_snapshot"), StringLength(4000)]
        public string? ReviewedBusinessSnapshot { get; set; }
        [FromForm(Name = "reviewed_calculation"), StringLength(20000)]
        public string? ReviewedCalculation { get; set; }

        [FromForm(Name = "market_section_id")]
        [Required(ErrorMessage = "Market section is required.")]
        public int MarketSectionId { get; set; }

        [FromForm(Name = "enforcer_id")]
        [Required(ErrorMessage = "Enforcer's information is required.")]
        public int EnforcerId { get; set; }

        [FromForm(Name = "type")]
        [Required(ErrorMessage = "Ticket type is required.")]
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public ViolationType Type { get; set; }

        [FromForm(Name = "description")]
        [Required(ErrorMessage = "Description is required.")]
        public required string Description { get; set; }

        [FromForm(Name = "penalty_type")]
        [Required(ErrorMessage = "Penalty type is required.")]
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public PenaltyType PenaltyType { get; set; }

        [FromForm(Name = "community_service_hours")]
        public int? CommunityServiceHours { get; set; }

        [FromForm(Name = "ordinances")]
        [Required(ErrorMessage = "At least one ordinance is required..")]
        public required List<int> Ordinances { get; set; } = [];

        [FromForm(Name = "ticket_evidence_files")]
        public List<IFormFile> TicketEvidenceFiles { get; set; } = [];

        // Bind all occurrences so a second paper file cannot be silently ignored.
        [FromForm(Name = "paper_ticket_photo")]
        public List<IFormFile> PaperTicketPhoto { get; set; } = [];

        [FromForm(Name = "supporting_evidence_files")]
        public List<IFormFile> SupportingEvidenceFiles { get; set; } = [];
    }
}
