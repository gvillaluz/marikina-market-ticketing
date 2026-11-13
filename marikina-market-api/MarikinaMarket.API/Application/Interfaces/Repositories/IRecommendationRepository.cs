using MarikinaMarket.API.Domain.Entities;

namespace MarikinaMarket.API.Application.Interfaces.Repositories
{
    public interface IRecommendationRepository
    {
        // The run with the latest FinishedAt, with its section recommendations, or null when no run exists.
        Task<RecommendationRun?> GetLatestRunAsync();

        // One card by its id, or null.
        Task<SectionRecommendation?> GetCardAsync(int id);

        // Every review, each with its run loaded.
        Task<List<RecommendationReview>> GetReviewsAsync();

        // Runs finished after the given time, oldest first, each with its section recommendations.
        Task<List<RecommendationRun>> GetRunsFinishedAfterAsync(DateTime finishedAt);

        Task AddReviewAsync(RecommendationReview review);
    }
}
