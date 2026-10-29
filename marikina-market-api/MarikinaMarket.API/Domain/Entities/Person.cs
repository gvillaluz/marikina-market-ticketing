namespace MarikinaMarket.API.Domain.Entities;

public class Person
{
    public int Id { get; set; }
    public required string FullName { get; set; }
    public required string Address { get; set; }
    public string? PhoneNumber { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
