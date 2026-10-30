namespace MarikinaMarket.API.Application.DTOs.Tickets.Response
{
    public class CommunityServiceLogResponse
    {
        public Guid? SubmissionId { get; set; }
        public DateTime ServiceDate { get; set; }
        public decimal HoursWorked { get; set; }
        public required string ProofUrl { get; set; }
    }
}