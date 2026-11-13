using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MarikinaMarket.API.Infrastructure.Repositories
{
    public class RecommendationRepository : IRecommendationRepository
    {
        private readonly AppDbContext _context;

        public RecommendationRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<RecommendationRun?> GetLatestRunAsync()
        {
            return await _context.RecommendationRuns
                .AsNoTracking()
                .Include(run => run.SectionRecommendations)
                .OrderByDescending(run => run.FinishedAt)
                .FirstOrDefaultAsync();
        }

        public Task<SectionRecommendation?> GetCardAsync(int id)
        {
            return _context.SectionRecommendations
                .AsNoTracking()
                .SingleOrDefaultAsync(card => card.Id == id);
        }

        public Task<List<RecommendationReview>> GetReviewsAsync()
        {
            return _context.RecommendationReviews
                .AsNoTracking()
                .Include(review => review.RecommendationRun)
                .ToListAsync();
        }

        public Task<List<RecommendationRun>> GetRunsFinishedAfterAsync(DateTime finishedAt)
        {
            return _context.RecommendationRuns
                .AsNoTracking()
                .Include(run => run.SectionRecommendations)
                .Where(run => run.FinishedAt > finishedAt)
                .OrderBy(run => run.FinishedAt)
                .ToListAsync();
        }

        public async Task AddReviewAsync(RecommendationReview review)
        {
            await _context.RecommendationReviews.AddAsync(review);
        }
    }
}
