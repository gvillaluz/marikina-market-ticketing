using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response;

public class PersonTicketHistoryResponse
{
    public int TicketId { get; set; }
    public string? ControlNumber { get; set; }
    public string? PaperViolatorName { get; set; }
    public required string BusinessName { get; set; }
    public required string RegisteredOwnerName { get; set; }
    public required string EnforcerName { get; set; }
    public DateTime IssuedAt { get; set; }
    public TicketStatus? Status { get; set; }
    public PenaltyType? PenaltyType { get; set; }
    public decimal? AssessedCashFine { get; set; }
    public decimal OutstandingCashFine { get; set; }
    public List<string> Ordinances { get; set; } = [];
}
