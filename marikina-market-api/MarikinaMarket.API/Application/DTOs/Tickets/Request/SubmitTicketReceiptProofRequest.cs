using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;

namespace MarikinaMarket.API.Application.DTOs.Tickets.Request
{
    public class SubmitTicketReceiptProofRequest
    {
        [FromForm(Name = "submission_id")]
        [Required(ErrorMessage = "Submission ID is required.")]
        public Guid? SubmissionId { get; set; }

        [FromForm(Name = "proof_file")]
        [Required(ErrorMessage = "A settlement receipt is required.")]
        public IFormFile? ProofFile { get; set; }
    }
}
