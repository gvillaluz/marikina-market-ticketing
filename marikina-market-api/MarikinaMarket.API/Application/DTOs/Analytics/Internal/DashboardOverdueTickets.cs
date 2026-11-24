namespace MarikinaMarket.API.Application.DTOs.Analytics.Internal
{
    public class DashboardOverdueTickets
    {
        public int Total { get; set; }
        public List<DashboardOverdueTicket> Items { get; set; } = [];
    }

    public class DashboardOverdueTicket
    {
        public int Id { get; set; }
        public string? ControlNumber { get; set; }
        public int? VendorId { get; set; }
        public string? BusinessName { get; set; }
        public DateTime IssuedAt { get; set; }
    }
}
