namespace MarikinaMarket.API.Application.DTOs.Analytics.Response
{
    public class DashboardSummaryResponse
    {
        public DateTime AsOf { get; set; }
        public required DashboardMetricsResponse Metrics { get; set; }
        public List<DashboardActivityResponse> RecentActivity { get; set; } = [];
        public DashboardOverdueTicketsResponse OverdueTickets { get; set; } = new();
    }

    public class DashboardMetricsResponse
    {
        public int WarningsToday { get; set; }
        public int TicketsToday { get; set; }
        public int OpenTickets { get; set; }
        public int ActiveBusinesses { get; set; }
    }

    public class DashboardActivityResponse
    {
        public int Id { get; set; }
        public DateTime OccurredAt { get; set; }
        public required string Category { get; set; }
        public required string Title { get; set; }
        public required string Description { get; set; }
        public string? ActorName { get; set; }
    }

    public class DashboardOverdueTicketsResponse
    {
        public int Total { get; set; }
        public List<DashboardOverdueTicketResponse> Items { get; set; } = [];
    }

    public class DashboardOverdueTicketResponse
    {
        public int Id { get; set; }
        public string? ControlNumber { get; set; }
        public int? VendorId { get; set; }
        public string? BusinessName { get; set; }
        public int DaysOverdue { get; set; }
    }
}
