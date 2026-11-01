using MarikinaMarket.API.Application.DTOs.Ordinance.Internal;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MarikinaMarket.API.Infrastructure.Repositories
{
    public class OrdinanceRepository : IOrdinanceRepository
    {
        private readonly AppDbContext _context;

        public OrdinanceRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<OrdinanceOffenseSummary>> GetByIdsAsync(List<int> ordinanceIds, int vendorId)
        {
            return await _context.Ordinances
                .Where(o => ordinanceIds.Contains(o.Id) && o.IsActive)
                .Select(o => new OrdinanceOffenseSummary
                {
                    OrdinanceId = o.Id,
                    OrdinanceNo = o.OrdinanceNo,
                    Series = o.Series,
                    Section = o.Section, SpecificCategory = o.SpecificCategory,
                    Title = o.Title,
                    Category = o.Category,
                    Severity = o.Severity, WarningEligible = o.WarningEligible,
                    PenaltyTiers = o.PenaltyTiers
                        .Select(pt => new PenaltyTierSummary
                        {
                            OrdinanceId = pt.OrdinanceId,
                            OffenseNumber = pt.OffenseNumber,
                            FineKind = pt.FineKind, PenaltyAmount = pt.PenaltyAmount,
                            MaximumFine = pt.MaximumFine, PenaltyTerms = pt.PenaltyTerms,
                            AllowBloodDonation = pt.AllowBloodDonation, AllowCommunityService = pt.AllowCommunityService
                        }).ToList(),
                    OffenseCount = o.TicketViolations
                        .Count(tv => tv.Ticket!.VendorId == vendorId
                            && tv.Ticket.Type == ViolationType.Ticket)
                })
                .ToListAsync();
        }

        public async Task<List<Ordinance>> GetOrdinances()
        {
            return await _context.Ordinances
                .Include(o => o.PenaltyTiers)
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<List<OrdinanceOffenseSummary>> GetByPersonIdsAsync(List<int> ordinanceIds, int personId)
        {
            // Deactivated ordinances cannot be summarized, warned or cited.
            return await _context.Ordinances.Where(o => ordinanceIds.Contains(o.Id) && o.IsActive)
                .Select(o => new OrdinanceOffenseSummary
                {
                    OrdinanceId = o.Id, OrdinanceNo = o.OrdinanceNo, Series = o.Series,
                    Section = o.Section, SpecificCategory = o.SpecificCategory, Title = o.Title, Category = o.Category,
                    Severity = o.Severity, WarningEligible = o.WarningEligible,
                    PenaltyTiers = o.PenaltyTiers.Select(pt => new PenaltyTierSummary
                    {
                        OrdinanceId = pt.OrdinanceId, OffenseNumber = pt.OffenseNumber,
                        FineKind = pt.FineKind, PenaltyAmount = pt.PenaltyAmount,
                        MaximumFine = pt.MaximumFine, PenaltyTerms = pt.PenaltyTerms,
                        AllowBloodDonation = pt.AllowBloodDonation, AllowCommunityService = pt.AllowCommunityService
                    }).ToList(),
                    OffenseCount = o.TicketViolations
                        .Where(tv => tv.Ticket!.PersonId == personId && tv.Ticket.Type == ViolationType.Ticket)
                        .Select(tv => tv.TicketId).Distinct().Count()
                }).ToListAsync();
        }

        public async Task<Ordinance?> GetByIdAsync(int id)
        {
            return await _context.Ordinances.Include(o => o.PenaltyTiers)
                .FirstOrDefaultAsync(o => o.Id == id);
        }

        public async Task AddAsync(Ordinance ordinance)
        {
            await _context.Ordinances.AddAsync(ordinance);
        }

        public async Task AddTiersAsync(IEnumerable<OrdinancePenaltyTier> tiers)
        {
            await _context.OrdinancePenaltyTiers.AddRangeAsync(tiers);
        }

        public void RemoveTiers(IEnumerable<OrdinancePenaltyTier> tiers)
        {
            _context.OrdinancePenaltyTiers.RemoveRange(tiers);
        }

        public async Task<int> GetActiveCountAsync()
        {
            return await _context.Ordinances.CountAsync(ordinance => ordinance.IsActive);
        }
    }
}
