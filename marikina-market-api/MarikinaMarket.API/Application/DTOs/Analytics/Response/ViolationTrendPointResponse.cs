namespace MarikinaMarket.API.Application.DTOs.Analytics.Response
{
    public class ViolationTrendPointResponse
    {
        public int Year { get; set; }
        public int Month { get; set; }
        public required string MonthName { get; set; }
        public int Level1Count { get; set; }
        public int Level2Count { get; set; }
        public int Level3Count { get; set; }
        public int Level4Count { get; set; }
        public int Level5Count { get; set; }
    }
}
