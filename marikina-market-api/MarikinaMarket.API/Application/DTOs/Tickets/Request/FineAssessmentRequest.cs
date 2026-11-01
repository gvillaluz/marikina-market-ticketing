using System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Request;

public class FineAssessmentRequest
{
    [Range(1, int.MaxValue)] public int OrdinanceId { get; set; }
    [Required] public decimal? AssessedAmount { get; set; }
}
