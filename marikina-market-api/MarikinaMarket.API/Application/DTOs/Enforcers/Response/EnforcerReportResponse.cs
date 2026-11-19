using MarikinaMarket.API.Application.DTOs.Reports.Response;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.DTOs.Enforcers.Response
{
    public class EnforcerReportResponse
    {
        public required ReportDateRangeResponse DateRange { get; set; }
        public required List<EnforcerReportRowResponse> Enforcers { get; set; }
        public required EnforcerReportTotalsResponse Totals { get; set; }
    }

    public class EnforcerReportTotalsResponse
    {
        public int Warnings { get; set; }
        public int Tickets { get; set; }
        public int TotalRecords { get; set; }
        public int SettledTickets { get; set; }
        public int OpenTickets { get; set; }
        public decimal FinesCharged { get; set; }
        public decimal FinesSettled { get; set; }
    }

    public class EnforcerReportRowResponse : EnforcerReportTotalsResponse
    {
        public int EnforcerId { get; set; }
        public required string Username { get; set; }
        public required string FirstName { get; set; }
        public required string LastName { get; set; }
        public AccountStatus Status { get; set; }
        public int DaysWithRecords { get; set; }
        public DateTime? LastRecordAt { get; set; }
    }
}
