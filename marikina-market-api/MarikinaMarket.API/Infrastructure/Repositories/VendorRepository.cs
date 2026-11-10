using MarikinaMarket.API.Application;
using Npgsql;
using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MarikinaMarket.API.Infrastructure.Repositories
{
    public class VendorRepository : IVendorRepository
    {
        private readonly AppDbContext _context;

        public VendorRepository(AppDbContext context) => _context = context;

        public Task<Business?> GetVendorProfileByUserIdAsync(int userId) => Task.FromResult<Business?>(null);

        public Task<int?> GetVendorIdByUserIdAsync(int userId) => Task.FromResult<int?>(null);

        public Task<int?> GetVendorUserIdAsync(int vendorId) => Task.FromResult<int?>(null);

        public async Task<VendorTicketSummary?> GetByIdAsync(int id)
        {
            return await _context.Businesses
                .Where(u => u.Id == id)
                .Select(v => new VendorTicketSummary
                {
                    Id = v.Id,
                    LastName = v.OwnerLastName,
                    FirstName = v.OwnerFirstName,
                    Email = v.Email ?? "",
                    MarketSectionId = v.MarketSectionId,
                    MarketSectionName = v.MarketSection!.Name,
                    BusinessName = v.BusinessName,
                    BusinessAccountNumber = v.BusinessAccountNumber,
                    BusinessAddress = (v.HouseNumber + " " + v.Street + " " + v.Barangay + " " + v.City).Trim(),
                    StallNumber = v.StallNumber,
                    Type = v.Type
                })
                .FirstOrDefaultAsync();
        }

        public Task<bool> IsActiveBusinessAsync(int id)
            => _context.Businesses.AnyAsync(v => v.Id == id && v.Status == VendorStatus.Active);

        public async Task<Business> CreateVendorAsync(Business vendorProfile)
        {
            await _context.Businesses.AddAsync(vendorProfile);
            return vendorProfile;
        }

        public Task<int> GetActiveBusinessCountAsync()
            => _context.Businesses
                .AsNoTracking()
                .CountAsync(business => business.Status == VendorStatus.Active);

        public async Task SaveChangesAsync()
        {
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
            {
                Console.WriteLine(ex.Message);
                throw new Exception("A database error occured while saving the changes.");
            }
        }

        // Matches business name, account number, stall, owner name (first-last or last-first) or address.
        // Exact stall or account-number matches come first, then the rest by business name.
        public async Task<(List<VendorLookupResult> Items, int Total)> SearchActiveBusinessesAsync(string search, int limit)
        {
            var term = search.ToLower();
            var query = _context.Businesses.Where(v => v.Status == VendorStatus.Active
                && (v.BusinessName.ToLower().Contains(term)
                    || v.BusinessAccountNumber.ToLower().Contains(term)
                    || (v.StallNumber != null && v.StallNumber.ToLower().Contains(term))
                    || (v.OwnerFirstName + " " + v.OwnerLastName).ToLower().Contains(term)
                    || (v.OwnerLastName + " " + v.OwnerFirstName).ToLower().Contains(term)
                    || (v.HouseNumber + ", " + v.Street + ", " + v.Barangay + ", " + v.City).ToLower().Contains(term)));
            var total = await query.CountAsync();
            var items = await query
                .OrderBy(v => (v.StallNumber != null && v.StallNumber.ToLower() == term) || v.BusinessAccountNumber.ToLower() == term ? 0 : 1)
                .ThenBy(v => v.BusinessName).ThenBy(v => v.Id)
                .Take(limit)
                .Select(v => new VendorLookupResult
                {
                    VendorId = v.Id,
                    Username = null,
                    Type = v.Type,
                    BusinessAccountNumber = v.BusinessAccountNumber,
                    StallNumber = v.StallNumber,
                    TradeName = v.BusinessName,
                    LastName = v.OwnerLastName,
                    FirstName = v.OwnerFirstName,
                    MiddleName = null,
                    Address = v.HouseNumber + ", " + v.Street + ", " + v.Barangay + ", " + v.City,
                    MarketSectionId = v.MarketSectionId,
                    MarketSectionName = v.MarketSection!.Name
                })
                .ToListAsync();
            return (items, total);
        }

        public async Task<VendorProfileDetails?> GetVendorProfileDetailsAsync(int vendorId)
        {
            return await _context.Businesses
                .AsNoTracking()
                .Where(v => v.Id == vendorId)
                .Select(v => new VendorProfileDetails
                {
                    FirstName = v.OwnerFirstName,
                    MiddleName = null,
                    LastName = v.OwnerLastName,
                    BusinessAccountNumber = v.BusinessAccountNumber,
                    BusinessName = v.BusinessName,
                    PhoneNumber = v.PhoneNumber,
                    Email = v.Email,
                    CreatedAt = v.CreatedAt,
                    LastViolationIssuedAt = v.Tickets
                        .Where(t => t.Type == ViolationType.Ticket)
                        .OrderByDescending(t => t.IssuedAt)
                        .Select(t => (DateTime?)t.IssuedAt)
                        .FirstOrDefault()
                })
                .FirstOrDefaultAsync();
        }

        public async Task<List<Business>> GetVendorProfilesForComplianceUpdateAsync()
            => await _context.Businesses.OrderBy(v => v.Id).ToListAsync();

        public async Task<Business?> GetVendorProfileForUpdateAsync(int vendorId)
        {
            return await _context.Businesses
                .Include(business => business.MarketSection)
                .FirstOrDefaultAsync(v => v.Id == vendorId);
        }

        public async Task<List<AdminVendorSummary>> GetAdminVendorSummariesAsync(
            int offset,
            int pageSize,
            AdminVendorSummaryFilter filters)
        {
            var vendors = ApplyAdminVendorFilters(_context.Businesses.AsNoTracking(), filters);

            return await vendors
                .OrderBy(v => v.BusinessAccountNumber)
                .Skip(offset)
                .Take(pageSize)
                .Select(v => new AdminVendorSummary
                {
                    VendorId = v.Id,
                    BusinessAccountNumber = v.BusinessAccountNumber,
                    VendorName = v.OwnerLastName + ", " + v.OwnerFirstName,
                    BusinessName = v.BusinessName,
                    BusinessType = v.Type,
                    MarketSectionName = v.MarketSection!.Name,
                    ComplianceScore = v.ComplianceScore,
                    WarningCount = v.Tickets.Count(t => t.Type == ViolationType.Warning),
                    TicketCount = v.Tickets.Count(t => t.Type == ViolationType.Ticket)
                })
                .ToListAsync();
        }

        public async Task<int> GetAdminVendorSummaryCountAsync(AdminVendorSummaryFilter filters)
        {
            return await ApplyAdminVendorFilters(_context.Businesses.AsNoTracking(), filters)
                .CountAsync();
        }

        public async Task<int> GetVendorWarningCountThisWeekAsync(DateTime weekStart)
        {
            return await _context.Tickets
                .Where(t => t.Type == ViolationType.Warning && t.IssuedAt >= weekStart && t.VendorId != null)
                .Select(t => t.VendorId)
                .Distinct()
                .CountAsync();
        }

        public async Task<int> GetVendorTicketCountThisWeekAsync(DateTime weekStart)
        {
            return await _context.Tickets
                .Where(t => t.Type == ViolationType.Ticket && t.IssuedAt >= weekStart && t.VendorId != null)
                .Select(t => t.VendorId)
                .Distinct()
                .CountAsync();
        }

        public async Task<List<AdminVendorActivity>> GetRecentVendorActivitiesAsync(int limit)
        {
            return await _context.Tickets
                .AsNoTracking()
                .Where(t => t.VendorId != null)
                .OrderByDescending(t => t.IssuedAt)
                .Take(limit)
                .Select(t => new AdminVendorActivity
                {
                    TicketId = t.Id,
                    ControlNumber = t.Type == ViolationType.Warning ? t.ControlNumber : t.PaperReference,
                    BusinessAccountNumber = t.Vendor!.BusinessAccountNumber,
                    FirstName = t.Vendor.OwnerFirstName,
                    MiddleName = null,
                    LastName = t.Vendor.OwnerLastName,
                    Type = t.Type,
                    IssuedAt = t.IssuedAt
                })
                .ToListAsync();
        }

        public async Task<List<AdminPendingTicketSettlement>> GetPendingTicketSettlementsAsync(
            int offset,
            int pageSize)
        {
            return await _context.Tickets
                .AsNoTracking()
                .Where(t => t.Type == ViolationType.Ticket &&
                    (t.Status == TicketStatus.Pending || t.Status == TicketStatus.Overdue))
                .OrderByDescending(t => t.IssuedAt)
                .Skip(offset)
                .Take(pageSize)
                .Select(t => new AdminPendingTicketSettlement
                {
                    TicketId = t.Id,
                    ControlNumber = t.PaperReference,
                    BusinessAccountNumber = t.Vendor == null ? null : t.Vendor.BusinessAccountNumber,
                    VendorName = t.Vendor == null ? null : t.Vendor.OwnerLastName + ", " + t.Vendor.OwnerFirstName,
                    MarketSectionName = t.MarketSection!.Name,
                    Status = t.Status ?? TicketStatus.Pending,
                    PenaltyType = t.PenaltyType,
                    TotalPaymentAmount = t.TotalPaymentAmount,
                    CommunityServiceHours = t.CommunityServiceHours,
                    IssuedAt = t.IssuedAt,
                    DueDate = t.IssuedAt.AddDays(5)
                })
                .ToListAsync();
        }

        public async Task<int> GetPendingTicketSettlementCountAsync()
        {
            return await _context.Tickets
                .CountAsync(t => t.Type == ViolationType.Ticket &&
                    (t.Status == TicketStatus.Pending || t.Status == TicketStatus.Overdue));
        }

        private static IQueryable<Business> ApplyAdminVendorFilters(
            IQueryable<Business> vendors,
            AdminVendorSummaryFilter filters)
        {
            if (filters.MarketSectionId.HasValue)
                vendors = vendors.Where(v => v.MarketSectionId == filters.MarketSectionId.Value);

            if (filters.ComplianceScoreRange is not null)
            {
                vendors = filters.ComplianceScoreRange switch
                {
                    "85-100" => vendors.Where(v => v.ComplianceScore >= 85 && v.ComplianceScore <= 100),
                    "70-84" => vendors.Where(v => v.ComplianceScore >= 70 && v.ComplianceScore <= 84),
                    "50-69" => vendors.Where(v => v.ComplianceScore >= 50 && v.ComplianceScore <= 69),
                    "Below 50" => vendors.Where(v => v.ComplianceScore >= 0 && v.ComplianceScore < 50),
                    _ => vendors
                };
            }

            if (!string.IsNullOrWhiteSpace(filters.Search))
            {
                var search = filters.Search.Trim().ToLower();
                vendors = vendors.Where(v =>
                    v.BusinessAccountNumber.ToLower().Contains(search) ||
                    v.BusinessName.ToLower().Contains(search) ||
                    (v.StallNumber != null && v.StallNumber.ToLower().Contains(search)) ||
                    v.OwnerFirstName.ToLower().Contains(search) ||
                    v.OwnerLastName.ToLower().Contains(search));
            }

            return vendors;
        }

        public Task<List<Business>> GetBusinessesAsync(int offset, int pageSize, AdminVendorSummaryFilter filters)
            => ApplyAdminVendorFilters(_context.Businesses.AsNoTracking(), filters)
                .Include(business => business.MarketSection)
                .OrderBy(business => business.BusinessAccountNumber).ThenBy(business => business.Id)
                .Skip(offset).Take(pageSize).ToListAsync();

        public Task<bool> BusinessAccountNumberExistsAsync(string accountNumber, int? excludingId)
        {
            var normalized = accountNumber.Trim().ToLowerInvariant();
            return _context.Businesses.AnyAsync(business => business.Id != excludingId &&
                business.BusinessAccountNumber.Trim().ToLower() == normalized);
        }

        public async Task SaveBusinessChangesAsync()
        {
            try { await _context.SaveChangesAsync(); }
            catch (DbUpdateException exception) when (exception.InnerException is PostgresException
                { SqlState: PostgresErrorCodes.UniqueViolation,
                    ConstraintName: "ix_businesses_account_number_key" or "ix_businesses_business_account_number" })
            {
                throw new InvalidRequestException("Business account number is already in use.");
            }
            catch (DbUpdateException exception) when (exception.InnerException is PostgresException
                { SqlState: PostgresErrorCodes.SerializationFailure })
            {
                throw new ConcurrencyConflictException("Business records changed during saving. Refresh and try again.");
            }
        }
    }
}
