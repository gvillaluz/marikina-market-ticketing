using MarikinaMarket.API.Application.DTOs.Reports.Response;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Enforcers.Response
{
    // One enforcer's records over a period: the summary row plus four breakdowns.
    public class EnforcerActivityReportResponse
    {
        public required ReportDateRangeResponse DateRange { get; set; }
        public required EnforcerReportRowResponse Enforcer { get; set; }
        public required List<EnforcerPenaltyKindResponse> PenaltyKinds { get; set; }
        public required List<EnforcerViolationTypeResponse> ViolationTypes { get; set; }
        public required List<EnforcerMarketStreetResponse> MarketStreets { get; set; }
        public required List<EnforcerReportDateResponse> Days { get; set; }
    }

    // Tickets by the penalty chosen when they were issued. A null penalty type means none was recorded.
    public class EnforcerPenaltyKindResponse
    {
        public PenaltyType? PenaltyType { get; set; }
        public int Tickets { get; set; }
        public int SettledTickets { get; set; }
        public int OpenTickets { get; set; }
        public decimal FinesCharged { get; set; }
    }

    public class EnforcerRecordCountResponse
    {
        public int Warnings { get; set; }
        public int Tickets { get; set; }
        public int Total { get; set; }
    }

    // A null category means the record has no ordinance recorded.
    public class EnforcerViolationTypeResponse : EnforcerRecordCountResponse
    {
        public ViolationCategory? Category { get; set; }
    }

    public class EnforcerMarketStreetResponse : EnforcerRecordCountResponse
    {
        public int MarketSectionId { get; set; }
        public required string MarketSectionName { get; set; }
    }

    // A Philippine calendar day.
    public class EnforcerReportDateResponse : EnforcerRecordCountResponse
    {
        public DateOnly Date { get; set; }
    }
}
