namespace MarikinaMarket.API.Application.DTOs.Tickets.Response;

public class InspectionVerificationResponse
{
    public BusinessSnapshotResponse? BusinessSnapshot { get; set; }
    public string? ReviewedBusinessSnapshot { get; set; }
    public required FineSummaryResponse Calculation { get; set; }
    // Review snapshot only, not authorization: submission independently repeats all checks.
    public required string ReviewedCalculation { get; set; }
}
