namespace MarikinaMarket.API.Application.DTOs.Person.Response;

public class PersonCandidateResponse : PersonRecordResponse
{
    public List<string> MatchedFields { get; set; } = [];
}
