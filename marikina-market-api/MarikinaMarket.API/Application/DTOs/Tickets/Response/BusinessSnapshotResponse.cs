namespace MarikinaMarket.API.Application.DTOs.Tickets.Response;

// A server-read review/citation value, never client authority for registry data.
public record BusinessSnapshotResponse
{
    public string? BusinessAccountNumber { get; set; }
    public string? BusinessName { get; set; }
    public string? RegisteredOwnerName { get; set; }
    public string? BusinessType { get; set; }
    public string? StallNumber { get; set; }
    public string? MarketSectionName { get; set; }
    public string? BusinessAddress { get; set; }
}
