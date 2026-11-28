using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Vendor.Internal
{
    public class VendorComplianceTicket
    {
        public int VendorId { get; set; }
        public DateTime IssuedAt { get; set; }
        public int? SeverityLevel { get; set; }
        public PenaltyType? PenaltyType { get; set; }
        public decimal? TotalPaymentAmount { get; set; }
        public TicketStatus? Status { get; set; }
        public DateTime? ResolvedAt { get; set; }
    }
}
