using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Request;

public class VerifyInspectionRequest
{
    [Range(1, int.MaxValue)] public int VendorId { get; set; }
    [Range(1, int.MaxValue)] public int PersonId { get; set; }
    [Required, StringLength(200)] public required string PaperViolatorName { get; set; }
    [Required, MinLength(1)] public required List<int> OrdinanceIds { get; set; }
    [Required, StringLength(1000)] public required string Description { get; set; }
    [EnumDataType(typeof(PenaltyType))] public PenaltyType PenaltyType { get; set; }
    public int? CommunityServiceHours { get; set; }
    [Range(1, int.MaxValue)] public int EvidenceCount { get; set; }
}
