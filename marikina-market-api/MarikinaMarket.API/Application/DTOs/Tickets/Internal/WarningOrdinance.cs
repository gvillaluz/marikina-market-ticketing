namespace MarikinaMarket.API.Application.DTOs.Tickets.Internal
{
    public class WarningOrdinance
    {
        public int OrdinanceId { get; set; }
        public required string OrdinanceNo { get; set; }
        public string? Section { get; set; }
        public string? SpecificCategory { get; set; }
    }
}
