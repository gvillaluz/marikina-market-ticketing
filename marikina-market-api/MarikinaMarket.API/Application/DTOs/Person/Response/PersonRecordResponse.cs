namespace MarikinaMarket.API.Application.DTOs.Person.Response;

public class PersonRecordResponse
{
    public int Id { get; set; }
    public required string FullName { get; set; }
    public required string Address { get; set; }
    public string? PhoneNumber { get; set; }
    public DateTime CreatedAt { get; set; }
}
