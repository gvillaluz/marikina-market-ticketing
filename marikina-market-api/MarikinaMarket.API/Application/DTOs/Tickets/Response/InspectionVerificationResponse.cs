namespace MarikinaMarket.API.Application.DTOs.Tickets.Response;

public class InspectionVerificationResponse
{
    public required FineSummaryResponse Calculation { get; set; }
    // Review snapshot only, not authorization: submission independently repeats all checks.
    public required string ReviewedCalculation { get; set; }
}
