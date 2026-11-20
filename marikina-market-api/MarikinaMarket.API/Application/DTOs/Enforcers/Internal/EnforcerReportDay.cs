namespace MarikinaMarket.API.Application.DTOs.Enforcers.Internal
{
    // One enforcer's records on one Philippine calendar day.
    public class EnforcerReportDay
    {
        public int EnforcerId { get; set; }
        public int Warnings { get; set; }
        public int Tickets { get; set; }
        public int SettledTickets { get; set; }
        public decimal FinesCharged { get; set; }
        public decimal FinesSettled { get; set; }
        public DateTime LastRecordAt { get; set; }
    }
}
