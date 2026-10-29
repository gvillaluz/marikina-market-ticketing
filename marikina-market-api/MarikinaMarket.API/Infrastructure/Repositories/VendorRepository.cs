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
                    StallNumber = v.StallNumber,
                    Type = v.Type
                })
                .FirstOrDefaultAsync();
        }

        public async Task<Business> CreateVendorAsync(Business vendorProfile)
        {
            await _context.Businesses.AddAsync(vendorProfile);
            return vendorProfile;
        }

        public async Task<VendorRegistrationRequest> AddVendorRegistryAsync(VendorRegistrationRequest vendor)
        {
            await _context.VendorRegistrationRequests.AddAsync(vendor);
            return vendor;
        }

        public async Task<VendorRegistrationRequest?> GetRegistrationById(int registrationId)
        {
            return await _context.VendorRegistrationRequests
                .Include(v => v.MarketSection)
                .Include(v => v.ReviewedByUser)
                .FirstOrDefaultAsync(v => v.Id == registrationId);
        }

        public async Task<bool> RegistrationEmailExistsAsync(string email)
        {
            var normalizedEmail = email.Trim().ToLowerInvariant();
            return await _context.VendorRegistrationRequests.AnyAsync(request =>
                request.Email.Trim().ToLower() == normalizedEmail);
        }

        public async Task<bool> RegistrationBusinessAccountNumberExistsAsync(string businessAccountNumber)
        {
            var normalizedAccountNumber = businessAccountNumber.Trim().ToLowerInvariant();
            return await _context.VendorRegistrationRequests.AnyAsync(request =>
                    request.BusinessAccountNumber.Trim().ToLower() == normalizedAccountNumber)
                || await _context.Businesses.AnyAsync(vendor =>
                    vendor.BusinessAccountNumber.Trim().ToLower() == normalizedAccountNumber);
        }

        public async Task<VendorRegistrationStatusCounts> GetVendorRegistrationStatusCountsAsync()
        {
            var counts = await _context.VendorRegistrationRequests
                .AsNoTracking()
                .GroupBy(request => 1)
                .Select(group => new VendorRegistrationStatusCounts
                {
                    PendingReview = group.Count(request => request.Status == RequestStatus.Pending),
                    NeedsInformation = group.Count(request => request.Status == RequestStatus.NeedsInformation),
                    Approved = group.Count(request => request.Status == RequestStatus.Approved),
                    Rejected = group.Count(request => request.Status == RequestStatus.Rejected)
                })
                .FirstOrDefaultAsync();

            return counts ?? new VendorRegistrationStatusCounts();
        }

        public async Task<DashboardVendorCounts> GetDashboardVendorCountsAsync()
        {
            var activeVendors = await _context.Businesses
                .AsNoTracking()
                .CountAsync(vendor => vendor.Status == VendorStatus.Active);
            var pendingRegistrations = await _context.VendorRegistrationRequests
                .AsNoTracking()
                .CountAsync(request => request.Status == RequestStatus.Pending);

            return new DashboardVendorCounts
            {
                ActiveVendors = activeVendors,
                PendingRegistrations = pendingRegistrations
            };
        }

        public async Task<List<VendorRegistrationSummary>> GetVendorRegistrationSummariesAsync(
            int offset,
            int pageSize,
            VendorRegistrationRequestFilters filters)
        {
            var requests = ApplyVendorRegistrationFilters(
                _context.VendorRegistrationRequests.AsNoTracking(),
                filters);

            return await requests
                .OrderByDescending(request => request.RequestedAt)
                .ThenByDescending(request => request.Id)
                .Skip(offset)
                .Take(pageSize)
                .Select(request => new VendorRegistrationSummary
                {
                    RegistrationId = request.Id,
                    BusinessAccountNumber = request.BusinessAccountNumber,
                    BusinessName = request.BusinessName,
                    VendorName = request.LastName + ", " + request.FirstName,
                    BusinessType = request.Type,
                    MarketSectionName = request.MarketSection!.Name,
                    StallNumber = request.StallNumber,
                    RequestedAt = request.RequestedAt,
                    Status = request.Status,
                    Version = request.Version
                })
                .ToListAsync();
        }

        public async Task<int> GetVendorRegistrationSummaryCountAsync(
            VendorRegistrationRequestFilters filters)
        {
            return await ApplyVendorRegistrationFilters(
                    _context.VendorRegistrationRequests.AsNoTracking(),
                    filters)
                .CountAsync();
        }

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

        public async Task<List<VendorLookupResult>> GetVendorByBusinessAccountNumber(string businessAccountNumber)
        {
            return await _context.Businesses
                .Where(v => v.BusinessAccountNumber.ToLower().Contains(businessAccountNumber.ToLower()) && v.Status == VendorStatus.Active)
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
        }

        public async Task<VendorLookupResult?> GetVendorByQrCode(string codeValue)
        {
            return await _context.Businesses
                .Where(v => v.QrCodeValue == codeValue && v.Status == VendorStatus.Active)
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
                .FirstOrDefaultAsync();
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
                .Where(t => t.Type == ViolationType.Warning && t.IssuedAt >= weekStart)
                .Select(t => t.VendorId)
                .Distinct()
                .CountAsync();
        }

        public async Task<int> GetVendorTicketCountThisWeekAsync(DateTime weekStart)
        {
            return await _context.Tickets
                .Where(t => t.Type == ViolationType.Ticket && t.IssuedAt >= weekStart)
                .Select(t => t.VendorId)
                .Distinct()
                .CountAsync();
        }

        public async Task<List<AdminVendorActivity>> GetRecentVendorActivitiesAsync(int limit)
        {
            return await _context.Tickets
                .AsNoTracking()
                .OrderByDescending(t => t.IssuedAt)
                .Take(limit)
                .Select(t => new AdminVendorActivity
                {
                    TicketId = t.Id,
                    ControlNumber = t.ControlNumber,
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
                    ControlNumber = t.ControlNumber,
                    BusinessAccountNumber = t.Vendor!.BusinessAccountNumber,
                    VendorName = t.Vendor.OwnerLastName + ", " + t.Vendor.OwnerFirstName,
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

        private static IQueryable<VendorRegistrationRequest> ApplyVendorRegistrationFilters(
            IQueryable<VendorRegistrationRequest> requests,
            VendorRegistrationRequestFilters filters)
        {
            if (filters.Status.HasValue)
                requests = requests.Where(request => request.Status == filters.Status.Value);

            if (filters.BusinessType.HasValue)
                requests = requests.Where(request => request.Type == filters.BusinessType.Value);

            return requests;
        }

        public void SetOriginalVersion(VendorRegistrationRequest registration, uint version)
        {
            _context.Entry(registration)
                .Property(r => r.Version)
                .OriginalValue = version;
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
