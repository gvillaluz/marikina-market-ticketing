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
    }
}
