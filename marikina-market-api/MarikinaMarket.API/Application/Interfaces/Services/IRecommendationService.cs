using MarikinaMarket.API.Application.DTOs.Recommendations.Response;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;

namespace MarikinaMarket.API.Application.Interfaces.Services
{
    public interface IRecommendationService
    {
        Task<RecommendationsResponse> GetLatestAsync();
        Task<PageResponse<DetectedViolationResponse>> GetDetectedViolationsAsync(int offset, DetectedViolationFilters filters);
        Task<RecommendationReviewResponse> MarkReviewedAsync(int id, int adminId);
        Task<RecommendationReviewResponse> DismissAsync(int id, int adminId);
    }
}
