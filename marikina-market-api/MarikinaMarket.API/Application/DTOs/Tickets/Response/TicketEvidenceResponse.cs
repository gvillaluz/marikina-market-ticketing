using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response;

public class TicketEvidenceResponse
{
    public int Id { get; set; }
    public TicketEvidenceRole? Role { get; set; }
    public int? SortOrder { get; set; }
    public required string Url { get; set; }
}
