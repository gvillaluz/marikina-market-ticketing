namespace MarikinaMarket.API.Application.DTOs.Person.Response;

public class PersonTicketTotalsResponse
{
    public int OffenseCount { get; set; }
    public int WarningCount { get; set; }
    public decimal OutstandingFine { get; set; }
    public DateTime? LastTicketAt { get; set; }
    public string? LastBusinessName { get; set; }
    public List<string> BusinessNames { get; set; } = [];
}
