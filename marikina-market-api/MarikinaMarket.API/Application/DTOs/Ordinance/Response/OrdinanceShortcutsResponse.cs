namespace MarikinaMarket.API.Application.DTOs.Ordinance.Response
{
    public class OrdinanceShortcutsResponse
    {
        public List<int> PersonOrdinanceIds { get; set; } = [];
        public List<int> MyRecentOrdinanceIds { get; set; } = [];
        public List<int> MostViolatedOrdinanceIds { get; set; } = [];
    }
}
