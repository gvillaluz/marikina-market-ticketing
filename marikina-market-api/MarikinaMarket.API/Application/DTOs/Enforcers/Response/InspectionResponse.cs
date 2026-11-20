using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Enforcers.Response
{
    public class InspectionResponse
    {
        public BusinessSnapshotResponse? BusinessSnapshot { get; set; }
        public int TicketId { get; set; }
        // Empty for an unregistered vendor.
        public int? VendorId { get; set; }
        public string? ControlNumber { get; set; }
        public DateTime IssuedAt { get; set; }
        // The violator: the name written on a ticket, and the confirmed person (the only name a warning has).
        public string? PaperViolatorName { get; set; }
        public string? PersonFullName { get; set; }
        // The business as it is now (a ticket also carries its snapshot from when it was issued).
        public string? BusinessName { get; set; }
        public string? RegisteredOwnerName { get; set; }
        public int MarketSectionId { get; set; }
        public required string MarketSectionName { get; set; }
        public ViolationType Type { get; set; }
        public TicketStatus? Status { get; set; }
    }
}
