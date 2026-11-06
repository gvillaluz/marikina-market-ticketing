namespace MarikinaMarket.API.Application.DTOs.Person.Response;

public class PersonSummaryResponse : PersonRecordResponse
{
    public PersonTicketTotalsResponse TicketTotals { get; set; } = new();
}
