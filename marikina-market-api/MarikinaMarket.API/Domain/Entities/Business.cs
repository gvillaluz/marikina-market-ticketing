using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Domain.Entities
{
    public class Business
    {
        public int Id { get; set; }

        public string OwnerFirstName { get; set; } = "";
        public string OwnerLastName { get; set; } = "";
        public string HouseNumber { get; set; } = "";
        public string Street { get; set; } = "";
        public string Barangay { get; set; } = "";
        public string City { get; set; } = "";
        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }

        public int MarketSectionId { get; set; }
        public MarketSection? MarketSection { get; set; }

        public BusinessType Type { get; set; }
        public required string BusinessAccountNumber { get; set; }
        public required string BusinessName { get; set; }
        public string? StallNumber { get; set; }
        public int ComplianceScore { get; set; }
        public DateTime ScoreUpdatedAt { get; set; }
        public required string QrCodeValue { get; set; }

        public VendorStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }

        public ICollection<Ticket> Tickets { get; set; } = [];
    }
}
