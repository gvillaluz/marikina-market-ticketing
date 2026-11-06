namespace MarikinaMarket.API.Application.DTOs.Person.Response;

public class PersonCandidateResponse : PersonSummaryResponse
{
    public List<string> MatchedFields { get; set; } = [];
}
