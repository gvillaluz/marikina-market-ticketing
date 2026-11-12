using MarikinaMarket.API.Application.DTOs.Recommendations.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Entities;

namespace MarikinaMarket.API.Application.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly IRecommendationRepository _recommendationRepository;
        private readonly IMarketSectionRepository _marketSectionRepository;

        public RecommendationService(
            IRecommendationRepository recommendationRepository,
            IMarketSectionRepository marketSectionRepository)
        {
            _recommendationRepository = recommendationRepository;
            _marketSectionRepository = marketSectionRepository;
        }

        public async Task<RecommendationsResponse> GetLatestAsync()
        {
            var run = await _recommendationRepository.GetLatestRunAsync();
            if (run is null)
                return new RecommendationsResponse();

            var sections = await _marketSectionRepository.GetAllAsync();
            var sectionNames = sections.ToDictionary(section => section.Id, section => section.Name);
            var sectionIdsWithCard = run.SectionRecommendations
                .Select(card => card.MarketSectionId)
                .ToHashSet();

            return new RecommendationsResponse
            {
                Run = new RecommendationRunResponse
                {
                    FinishedAt = run.FinishedAt,
                    WindowStart = run.WindowStart,
                    WindowEnd = run.WindowEnd,
                    RecordCount = run.RecordCount
                },
                Recommendations = run.SectionRecommendations
                    .Select(card => ToResponse(card, sectionNames[card.MarketSectionId]))
                    .OrderByDescending(card => card.RiskScore)
                    .ThenBy(card => card.MarketSectionName, StringComparer.OrdinalIgnoreCase)
                    .ToList(),
                SectionsWithoutRecommendation = sections
                    .Where(section => section.IsActive && !sectionIdsWithCard.Contains(section.Id))
                    .Select(section => section.Name)
                    .OrderBy(name => name, StringComparer.OrdinalIgnoreCase)
                    .ToList()
            };
        }

        private static SectionRecommendationResponse ToResponse(SectionRecommendation card, string sectionName) => new()
        {
            MarketSectionId = card.MarketSectionId,
            MarketSectionName = sectionName,
            CategoryCode = card.CategoryCode,
            CategoryNameEnglish = card.CategoryNameEnglish,
            CategoryNameFilipino = card.CategoryNameFilipino,
            RecommendedAction = card.RecommendedAction,
            CategoryRecordCount = card.CategoryRecordCount,
            SectionRecordCount = card.SectionRecordCount,
            RiskScore = card.RiskScore,
            RiskLevel = card.RiskLevel,
            PatternConfidence = card.PatternConfidence,
            PeakStartHour = card.PeakStartHour,
            HourlyCounts = card.HourlyCounts,
            LastFlaggedAt = card.LastFlaggedAt
        };
    }
}
