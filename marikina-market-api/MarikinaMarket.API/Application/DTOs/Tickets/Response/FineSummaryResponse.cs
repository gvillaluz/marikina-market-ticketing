using MarikinaMarket.API.Application.DTOs.Tickets.Internal;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Response
{
    public class FineSummaryResponse
    {
        public decimal? TotalPaymentAmount { get; set; }
        public Severity? HighestSeverity { get; set; }
        public bool AllowBloodDonation { get; set; }
        public bool AllowCommunityService { get; set; }
        public List<OrdinanceFineBreakdownItem> Breakdown { get; set; } = [];
    }
}
