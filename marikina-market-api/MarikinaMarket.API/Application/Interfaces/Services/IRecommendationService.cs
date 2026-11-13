using MarikinaMarket.API.Application.DTOs.Recommendations.Response;

namespace MarikinaMarket.API.Application.Interfaces.Services
{
    public interface IRecommendationService
    {
        Task<RecommendationsResponse> GetLatestAsync();
        Task<RecommendationReviewResponse> MarkReviewedAsync(int id, int adminId);
        Task<RecommendationReviewResponse> DismissAsync(int id, int adminId);
    }
}
