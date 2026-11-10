using MarikinaMarket.API.Application.DTOs.User.Request;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.DTOs.Vendor.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;

namespace MarikinaMarket.API.Application.Services
{
    public class VendorService : IVendorService
    {
        private const int BUSINESS_SEARCH_LIMIT = 20;
        private readonly IVendorRepository _vendorRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMarketSectionRepository _marketSectionRepository;
        private readonly IVendorComplianceScoreService _complianceScoreService;
        private readonly AuditLogContext? _audit;
        private readonly IAuditLogService? _auditService;
        private readonly IUserService? _userService;
        private readonly ITicketRepository? _ticketRepository;

        public VendorService(
            IVendorRepository vendorRepository, 
            IUnitOfWork unitOfWork,
            IMarketSectionRepository marketSectionRepository,
            IVendorComplianceScoreService complianceScoreService,
            AuditLogContext? audit = null, IAuditLogService? auditService = null,
            IUserService? userService = null, ITicketRepository? ticketRepository = null)
        {
            _vendorRepository = vendorRepository;
            _unitOfWork = unitOfWork;
            _marketSectionRepository = marketSectionRepository;
            _complianceScoreService = complianceScoreService;
            _audit = audit;
            _auditService = auditService;
            _userService = userService;
            _ticketRepository = ticketRepository;
        }

        public async Task<VendorDashboardResponse> GetOwnDashboardAsync(int userId)
        {
            var vendor = await GetOwnVendorAsync(userId);
            var tickets = _ticketRepository ?? throw new InvalidOperationException("Ticket repository is required for the vendor dashboard.");
            return new VendorDashboardResponse
            {
                TotalWarnings = await tickets.GetVendorInspectionCountAsync(userId, new() { Type = ViolationType.Warning }),
                TotalTickets = await tickets.GetVendorInspectionCountAsync(userId, new() { Type = ViolationType.Ticket }),
                Tasks = await tickets.GetVendorDashboardTasksAsync(userId),
                Compliance = await GetVendorComplianceScoreAsync(vendor.Id)
            };
        }

        public async Task<VendorSelfProfileResponse> GetOwnProfileAsync(int userId)
        {
            var vendor = await GetOwnVendorAsync(userId);
            var userService = _userService ?? throw new InvalidOperationException("User service is required for vendor profiles.");
            var user = await userService.GetUserInfoAsync(userId);
            if (user.Role != Role.MarketVendor)
                throw new UnauthorizedAccessException("Vendor access is required.");
            return BuildOwnProfile(user, vendor);
        }

        public async Task<VendorSelfProfileResponse> UpdateOwnProfileAsync(int userId, EditUserRequest request)
        {
            var vendor = await GetOwnVendorAsync(userId);
            var userService = _userService ?? throw new InvalidOperationException("User service is required for vendor profiles.");
            var user = await userService.GetUserInfoAsync(userId);
            if (user.Role != Role.MarketVendor)
                throw new UnauthorizedAccessException("Vendor access is required.");
            var updated = await userService.UpdateUserInfo(request, userId);
            return BuildOwnProfile(updated, vendor);
        }

        private async Task<Business> GetOwnVendorAsync(int userId)
        {
            if (userId <= 0)
                throw new ValidationException("User ID must be greater than zero.");
            return await _vendorRepository.GetVendorProfileByUserIdAsync(userId)
                ?? throw new RecordNotFoundException("Vendor profile not found.");
        }

        private static VendorSelfProfileResponse BuildOwnProfile(
            MarikinaMarket.API.Application.DTOs.User.Response.UserProfileResponse user, Business vendor)
            => new()
            {
                User = user,
                Vendor = VendorBusinessProfileResponse.FromEntity(vendor)
            };

        public async Task<PageResponse<GetVendorResponse>> SearchBusinessesAsync(string? search)
        {
            var term = search?.Trim();
            if (string.IsNullOrEmpty(term))
                throw new ValidationException("Enter a business name, stall, owner, address or account number.");
            if (term.Length > 200)
                throw new ValidationException("Search must be 200 characters or fewer.");

            var (vendors, total) = await _vendorRepository.SearchActiveBusinessesAsync(term, BUSINESS_SEARCH_LIMIT);

            return new() { Total = total, HasMore = vendors.Count < total, Items = vendors.Select(v => new GetVendorResponse
            {
                VendorId = v.VendorId,
                Username = v.Username,
                Type = v.Type,
                BusinessAccountNumber = v.BusinessAccountNumber,
                StallNumber = v.StallNumber,
                TradeName = v.TradeName,
                LastName = v.LastName,
                FirstName = v.FirstName,
                MiddleName = v.MiddleName,
                Address = v.Address ?? "",
                MarketSectionId = v.MarketSectionId,
                MarketSectionName = v.MarketSectionName
            }).ToList() };
        }

        public async Task<PageResponse<AdminVendorSummaryResponse>> GetAdminVendorSummariesAsync(
            int offset,
            AdminVendorSummaryFilter filters)
        {
            const int pageSize = 10;
            List<AdminVendorSummary> vendors;
            int total;
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                await _complianceScoreService.RefreshAllAsync(DateTime.UtcNow);
                vendors = await _vendorRepository.GetAdminVendorSummariesAsync(offset, pageSize, filters);
                total = await _vendorRepository.GetAdminVendorSummaryCountAsync(filters);
                if (_auditService is not null) await _auditService.StageCurrentAsync();
                await _unitOfWork.CommitAsync();
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }

            return new PageResponse<AdminVendorSummaryResponse>
            {
                Items = vendors.Select(v => new AdminVendorSummaryResponse
                {
                    VendorId = v.VendorId,
                    BusinessAccountNumber = v.BusinessAccountNumber,
                    VendorName = v.VendorName,
                    BusinessName = v.BusinessName,
                    Type = v.BusinessType,
                    MarketSectionName = v.MarketSectionName,
                    ComplianceScore = v.ComplianceScore,
                    WarningCount = v.WarningCount,
                    TicketCount = v.TicketCount
                }).ToList(),
                HasMore = offset + vendors.Count < total,
                Total = total
            };
        }

        public async Task<AdminVendorComplianceOverviewResponse> GetAdminVendorComplianceOverviewAsync()
        {
            var today = DateTime.UtcNow.Date;
            var daysSinceMonday = ((int)today.DayOfWeek + 6) % 7;
            var weekStart = today.AddDays(-daysSinceMonday);

            var vendorsWithWarnings = await _vendorRepository.GetVendorWarningCountThisWeekAsync(weekStart);
            var vendorsWithTickets = await _vendorRepository.GetVendorTicketCountThisWeekAsync(weekStart);
            var activities = await _vendorRepository.GetRecentVendorActivitiesAsync(5);

            return new AdminVendorComplianceOverviewResponse
            {
                VendorsWithWarningsThisWeek = vendorsWithWarnings,
                VendorsWithTicketsThisWeek = vendorsWithTickets,
                Activities = activities.Select(a => new AdminVendorActivityResponse
                {
                    TicketId = a.TicketId,
                    ControlNumber = a.ControlNumber,
                    BusinessAccountNumber = a.BusinessAccountNumber,
                    VendorName = FormatVendorName(a.FirstName, a.MiddleName, a.LastName),
                    Type = a.Type,
                    IssuedAt = a.IssuedAt
                }).ToList()
            };
        }

        private static string FormatVendorName(string firstName, string? middleName, string lastName)
        {
            var middleInitial = string.IsNullOrWhiteSpace(middleName)
                ? ""
                : $" {middleName.Trim()[0]}.";

            return $"{lastName}, {firstName}{middleInitial}";
        }

        public async Task<VendorProfileResponse> GetVendorProfileAsync(int vendorId)
        {
            var vendor = await _vendorRepository.GetVendorProfileDetailsAsync(vendorId);

            if (vendor is null)
                throw new RecordNotFoundException("Vendor not found.");

            return new VendorProfileResponse
            {
                Name = FormatVendorName(vendor.FirstName, vendor.MiddleName, vendor.LastName),
                BusinessAccountNumber = vendor.BusinessAccountNumber,
                BusinessName = vendor.BusinessName,
                PhoneNumber = vendor.PhoneNumber,
                Email = vendor.Email,
                CreatedAt = vendor.CreatedAt,
                LastViolationIssuedAt = vendor.LastViolationIssuedAt
            };
        }

        public async Task<VendorComplianceScoreResponse> GetVendorComplianceScoreAsync(int vendorId)
        {
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                var response = await _complianceScoreService.RefreshAsync(vendorId, DateTime.UtcNow);
                if (_auditService is not null) await _auditService.StageCurrentAsync();
                await _unitOfWork.CommitAsync();
                return response;
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
        }

        public async Task<PageResponse<AdminPendingTicketSettlementResponse>> GetPendingTicketSettlementsAsync(int offset)
        {
            const int pageSize = 5;
            var settlements = await _vendorRepository.GetPendingTicketSettlementsAsync(offset, pageSize);
            var total = await _vendorRepository.GetPendingTicketSettlementCountAsync();

            return new PageResponse<AdminPendingTicketSettlementResponse>
            {
                Items = settlements.Select(s => new AdminPendingTicketSettlementResponse
                {
                    TicketId = s.TicketId,
                    ControlNumber = s.ControlNumber,
                    BusinessAccountNumber = s.BusinessAccountNumber,
                    VendorName = s.VendorName,
                    MarketSectionName = s.MarketSectionName,
                    Status = s.Status,
                    PenaltyType = s.PenaltyType,
                    TotalPaymentAmount = s.TotalPaymentAmount,
                    CommunityServiceHours = s.CommunityServiceHours,
                    IssuedAt = s.IssuedAt,
                    DueDate = s.DueDate
                }).ToList(),
                HasMore = offset + settlements.Count < total,
                Total = total
            };
        }

        public async Task<PageResponse<BusinessRecordResponse>> GetBusinessesAsync(int offset, AdminVendorSummaryFilter filters)
        {
            if (offset < 0) throw new ValidationException("Offset must not be negative.");
            Validator.ValidateObject(filters, new ValidationContext(filters), true);
            var records = await _vendorRepository.GetBusinessesAsync(offset, 10, filters);
            var total = await _vendorRepository.GetAdminVendorSummaryCountAsync(filters);
            return new() { Items = records.Select(BusinessRecordResponse.FromEntity).ToList(), Total = total,
                HasMore = (long)offset + records.Count < total };
        }

        public async Task<BusinessRecordResponse> GetBusinessAsync(int id)
        {
            if (id < 1) throw new ValidationException("Business ID must be positive.");
            return BusinessRecordResponse.FromEntity(await _vendorRepository.GetVendorProfileForUpdateAsync(id)
                ?? throw new RecordNotFoundException("Business not found."));
        }

        public async Task<BusinessRecordResponse> SaveBusinessAsync(int? id, SaveBusinessRequest request)
        {
            if (id.HasValue && id < 1) throw new ValidationException("Business ID must be positive.");
            request.BusinessAccountNumber = request.BusinessAccountNumber?.Trim() ?? "";
            request.BusinessName = request.BusinessName?.Trim() ?? "";
            request.OwnerFirstName = request.OwnerFirstName?.Trim() ?? "";
            request.OwnerLastName = request.OwnerLastName?.Trim() ?? "";
            request.HouseNumber = request.HouseNumber?.Trim() ?? "";
            request.Street = request.Street?.Trim() ?? "";
            request.Barangay = request.Barangay?.Trim() ?? "";
            request.City = request.City?.Trim() ?? "";
            request.PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim();
            request.Email = string.IsNullOrWhiteSpace(request.Email) ? null : request.Email.Trim();
            request.StallNumber = string.IsNullOrWhiteSpace(request.StallNumber) ? null : request.StallNumber.Trim();
            Validator.ValidateObject(request, new ValidationContext(request), true);
            if (request.BusinessType == BusinessType.Public && request.StallNumber is null)
                throw new ValidationException("Stall number is required for public businesses.");
            var section = await _marketSectionRepository.GetById(request.MarketSectionId);
            if (section is null || !section.IsActive)
                throw new ValidationException("Select an active market section.");

            var business = id.HasValue
                ? await _vendorRepository.GetVendorProfileForUpdateAsync(id.Value)
                    ?? throw new RecordNotFoundException("Business not found.")
                : new Business { BusinessAccountNumber = "", BusinessName = "", CreatedAt = DateTime.UtcNow,
                    Status = VendorStatus.Active, QrCodeValue = Guid.NewGuid().ToString("N"),
                    ScoreUpdatedAt = DateTime.UtcNow };
            if (await _vendorRepository.BusinessAccountNumberExistsAsync(request.BusinessAccountNumber, id))
                throw new InvalidRequestException("Business account number is already in use.");

            await _unitOfWork.BeginTransactionAsync();
            try
            {
                business.BusinessAccountNumber = request.BusinessAccountNumber;
                business.BusinessName = request.BusinessName;
                business.OwnerFirstName = request.OwnerFirstName;
                business.OwnerLastName = request.OwnerLastName;
                business.HouseNumber = request.HouseNumber;
                business.Street = request.Street;
                business.Barangay = request.Barangay;
                business.City = request.City;
                business.PhoneNumber = request.PhoneNumber;
                business.Email = request.Email;
                business.Type = request.BusinessType!.Value;
                business.MarketSectionId = section.Id;
                business.MarketSection = section;
                business.StallNumber = request.StallNumber;
                if (!id.HasValue) await _vendorRepository.CreateVendorAsync(business);
                await _vendorRepository.SaveBusinessChangesAsync();
                if (_audit?.Entry is not null) _audit.Entry.TargetId = business.Id.ToString(System.Globalization.CultureInfo.InvariantCulture);
                if (_auditService is not null) await _auditService.StageCurrentAsync();
                await _unitOfWork.CommitAsync();
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
            return BusinessRecordResponse.FromEntity(business);
        }
    }
}
