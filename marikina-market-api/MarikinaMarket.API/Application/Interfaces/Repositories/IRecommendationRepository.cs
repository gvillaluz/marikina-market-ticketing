using MarikinaMarket.API.Domain.Entities;

namespace MarikinaMarket.API.Application.Interfaces.Repositories
{
    public interface IRecommendationRepository
    {
        // The run with the latest FinishedAt, with its section recommendations, or null when no run exists.
        Task<RecommendationRun?> GetLatestRunAsync();
    }
}
