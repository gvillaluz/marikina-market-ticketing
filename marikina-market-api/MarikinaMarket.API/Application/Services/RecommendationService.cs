using MarikinaMarket.API.Application.DTOs.Recommendations.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using System.ComponentModel.DataAnnotations;

namespace MarikinaMarket.API.Application.Services
{
    public class RecommendationService : IRecommendationService
    {
        private readonly IRecommendationRepository _recommendationRepository;
        private readonly IMarketSectionRepository _marketSectionRepository;
        private readonly IUserRepository _userRepository;
        private readonly IUnitOfWork _unitOfWork;

        public RecommendationService(
            IRecommendationRepository recommendationRepository,
            IMarketSectionRepository marketSectionRepository,
            IUserRepository userRepository,
            IUnitOfWork unitOfWork)
        {
            _recommendationRepository = recommendationRepository;
            _marketSectionRepository = marketSectionRepository;
            _userRepository = userRepository;
            _unitOfWork = unitOfWork;
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
            var reviews = await EffectiveReviewsAsync(run.SectionRecommendations);

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
                    .Select(card => ToResponse(card, sectionNames[card.MarketSectionId], reviews.GetValueOrDefault(Identity(card))))
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

        public Task<RecommendationReviewResponse> MarkReviewedAsync(int id, int adminId)
            => RecordAsync(id, adminId, RecommendationDecision.Reviewed);

        public Task<RecommendationReviewResponse> DismissAsync(int id, int adminId)
            => RecordAsync(id, adminId, RecommendationDecision.Dismissed);

        private async Task<RecommendationReviewResponse> RecordAsync(int id, int adminId, RecommendationDecision decision)
        {
            if (id <= 0) throw new ValidationException("Recommendation ID must be greater than zero.");
            if (adminId <= 0) throw new UnauthorizedAccessException("A valid administrator claim is required.");
            var names = await _userRepository.GetNamesByIdsAsync([adminId]);
            if (!names.TryGetValue(adminId, out var admin))
                throw new UnauthorizedAccessException("Administrator account not found.");

            await _unitOfWork.BeginTransactionAsync();
            try
            {
                var card = await _recommendationRepository.GetCardAsync(id)
                    ?? throw new RecordNotFoundException("Recommendation not found.");
                var latestRun = await _recommendationRepository.GetLatestRunAsync();
                if (latestRun?.Id != card.RecommendationRunId)
                    throw new InvalidRequestException("This recommendation was updated. Refresh the page.");

                var current = (await EffectiveReviewsAsync([card])).GetValueOrDefault(Identity(card));
                if (current?.Decision == RecommendationDecision.Dismissed)
                    throw new InvalidRequestException("This recommendation has already been dismissed.");
                if (current?.Decision == RecommendationDecision.Reviewed && decision == RecommendationDecision.Reviewed)
                    throw new InvalidRequestException("This recommendation has already been marked as reviewed.");

                var review = new RecommendationReview
                {
                    MarketSectionId = card.MarketSectionId,
                    CategoryCode = card.CategoryCode,
                    Decision = decision,
                    ReviewedById = adminId,
                    ReviewedByName = $"{admin.FirstName} {admin.LastName}",
                    ReviewedAt = DateTime.UtcNow,
                    RecommendationRunId = card.RecommendationRunId
                };
                await _recommendationRepository.AddReviewAsync(review);
                await _unitOfWork.SaveChangesAsync();
                await _unitOfWork.CommitAsync();
                return ToResponse(review);
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
        }

        // The review that counts for each card, by section and category. A review made on an earlier run counts only when
        // every run after it also had a card for that section and category. The newest of the reviews that count wins.
        private async Task<Dictionary<(int, string), RecommendationReview>> EffectiveReviewsAsync(
            IEnumerable<SectionRecommendation> cards)
        {
            var identities = cards.Select(Identity).ToHashSet();
            var reviews = (await _recommendationRepository.GetReviewsAsync())
                .Where(review => identities.Contains(Identity(review)))
                .ToList();
            if (reviews.Count == 0)
                return new();

            var laterRuns = await _recommendationRepository.GetRunsFinishedAfterAsync(
                reviews.Min(review => review.RecommendationRun!.FinishedAt));
            return reviews
                .Where(review => laterRuns
                    .Where(run => run.FinishedAt > review.RecommendationRun!.FinishedAt)
                    .All(run => run.SectionRecommendations.Any(card => Identity(card) == Identity(review))))
                .GroupBy(Identity)
                .ToDictionary(
                    group => group.Key,
                    group => group.OrderByDescending(review => review.ReviewedAt).ThenByDescending(review => review.Id).First());
        }

        private static (int, string) Identity(SectionRecommendation card) => (card.MarketSectionId, card.CategoryCode);

        private static (int, string) Identity(RecommendationReview review) => (review.MarketSectionId, review.CategoryCode);

        private static RecommendationReviewResponse ToResponse(RecommendationReview review) => new()
        {
            Decision = review.Decision,
            ReviewedByName = review.ReviewedByName,
            ReviewedAt = review.ReviewedAt
        };

        private static SectionRecommendationResponse ToResponse(
            SectionRecommendation card, string sectionName, RecommendationReview? review) => new()
        {
            Id = card.Id,
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
            LastFlaggedAt = card.LastFlaggedAt,
            Review = review is null ? null : ToResponse(review)
        };
    }
}
