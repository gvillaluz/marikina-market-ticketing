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
using System.Text.Encodings.Web;
using System.Security.Cryptography;
using System.Globalization;
using MarikinaMarket.API.Application.DTOs.Audits.Internal;

namespace MarikinaMarket.API.Application.Services
{
    public class VendorService : IVendorService
    {
        private readonly IUserRepository _userRepository;
        private readonly IVendorRepository _vendorRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IMarketSectionRepository _marketSectionRepository;
        private readonly IVendorComplianceScoreService _complianceScoreService;
        private readonly IStorageService _storageService;
        private readonly IEmailService _emailService;
        private readonly INotificationService _notificationService;
        private readonly ILogger<VendorService> _logger;
        private readonly AuditLogContext? _audit;
        private readonly IAuditLogService? _auditService;
        private readonly IUserService? _userService;
        private readonly ITicketRepository? _ticketRepository;

        public VendorService(
            IUserRepository userRepository, 
            IVendorRepository vendorRepository, 
            IUnitOfWork unitOfWork,
            IMarketSectionRepository marketSectionRepository,
            IVendorComplianceScoreService complianceScoreService,
            IStorageService storageService,
            IEmailService emailService,
            INotificationService notificationService,
            ILogger<VendorService> logger, AuditLogContext? audit = null, IAuditLogService? auditService = null,
            IUserService? userService = null, ITicketRepository? ticketRepository = null)
        {
            _userRepository = userRepository;
            _vendorRepository = vendorRepository;
            _unitOfWork = unitOfWork;
            _marketSectionRepository = marketSectionRepository;
            _complianceScoreService = complianceScoreService;
            _storageService = storageService;
            _emailService = emailService;
            _notificationService = notificationService;
            _logger = logger;
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

        public Task<RegisterVendorResponse> CreateVendorRegistryAsync(RegisterVendorRequest request)
        => throw new InvalidRequestException("Vendor login accounts are no longer supported. An administrator must maintain a business record.");

        public Task<RegistrationApprovalResponse> CreateAdminVendorRegistrationAsync(
            AdminRegisterVendorRequest request,
            int adminId)
        => throw new InvalidRequestException("Vendor login accounts are no longer supported. An administrator must maintain a business record.");

        public Task<RegistrationApprovalResponse> ApproveVendorRegistration(int registrationId, RegistrationAdminAction request)
        => throw new InvalidRequestException("Vendor login accounts are no longer supported. An administrator must maintain a business record.");

        public async Task<RegistrationDeclinedResponse> DeclineVendorRegistration(int registrationId, RegistrationAdminAction request)
        {
            await _unitOfWork.BeginTransactionAsync();
            var transactionCommitted = false;

            try
            {
                if (request.RequestStatus is not RequestStatus.Rejected)
                    throw new InvalidRequestException("RequestStatus must be Rejected.");

                var registration = await _vendorRepository.GetRegistrationById(registrationId);

                if (registration is null)
                    throw new RecordNotFoundException("Registration request record not found.");

                ValidateReviewVersion(registration, request.Version);

                if (registration.Status is not (RequestStatus.Pending or RequestStatus.NeedsInformation))
                    throw new AlreadyProcessedException("This request has already been processed.");

                if (string.IsNullOrWhiteSpace(request.ReviewReason))
                    throw new InvalidRequestException("A review reason is required when declining a registration.");

                if (string.IsNullOrWhiteSpace(request.ReviewRemarks))
                    throw new InvalidRequestException("Review remarks are required when declining a registration.");

                registration.Status = request.RequestStatus;
                registration.ReviewedAt = DateTime.UtcNow;
                registration.ReviewedBy = request.AdminId;
                registration.ReviewReason = request.ReviewReason;
                registration.ReviewRemarks = request.ReviewRemarks;
                registration.RemarksOrReason = request.ReviewRemarks;

                await _unitOfWork.SaveChangesAsync();
                if (_auditService is not null) await _auditService.StageCurrentAsync();
                await _unitOfWork.CommitAsync();
                transactionCommitted = true;

                var emailBody = CreateReviewEmail(registration);

                var emailSent = await SendReviewEmailAsync(
                    registration, "Vendor Registration Rejected", emailBody);

                return new RegistrationDeclinedResponse
                {
                    RegistrationId = registration.Id,
                    Status = registration.Status,
                    EmailSent = emailSent,
                    FirstName = registration.FirstName,
                    MiddleName = registration.MiddleName,
                    LastName = registration.LastName,
                    BusinessName = registration.BusinessName,
                    ReviewReason = registration.ReviewReason!,
                    ReviewRemarks = registration.ReviewRemarks!,
                    AdminId = request.AdminId,
                    ReviewedAt = registration.ReviewedAt.Value,
                    Version = registration.Version
                };
            }
            catch (ConcurrencyConflictException)
            {
                if (!transactionCommitted)
                    await _unitOfWork.RollbackAsync();
                throw new ConcurrencyConflictException("This registration was already reviewed by another admin. Please refresh and try again.");
            }
            catch (Exception)
            {
                if (!transactionCommitted)
                    await _unitOfWork.RollbackAsync();
                throw;
            }
        }

        public async Task<RegistrationDeclinedResponse> RequestMoreInformation(
            int registrationId,
            RegistrationAdminAction request)
        {
            await _unitOfWork.BeginTransactionAsync();
            var transactionCommitted = false;

            try
            {
                if (request.RequestStatus is not RequestStatus.NeedsInformation)
                    throw new InvalidRequestException("RequestStatus must be NeedsInformation.");

                var registration = await _vendorRepository.GetRegistrationById(registrationId);

                if (registration is null)
                    throw new RecordNotFoundException("Registration request record not found.");

                ValidateReviewVersion(registration, request.Version);

                if (registration.Status != RequestStatus.Pending)
                    throw new AlreadyProcessedException("This request has already been processed.");

                if (string.IsNullOrWhiteSpace(request.ReviewReason))
                    throw new InvalidRequestException("A review reason is required when requesting information.");

                if (string.IsNullOrWhiteSpace(request.ReviewRemarks))
                    throw new InvalidRequestException("Review remarks are required when requesting information.");

                registration.Status = request.RequestStatus;
                registration.ReviewedAt = DateTime.UtcNow;
                registration.ReviewedBy = request.AdminId;
                registration.ReviewReason = request.ReviewReason;
                registration.ReviewRemarks = request.ReviewRemarks;
                registration.RemarksOrReason = request.ReviewRemarks;

                await _unitOfWork.SaveChangesAsync();
                if (_auditService is not null) await _auditService.StageCurrentAsync();
                await _unitOfWork.CommitAsync();
                transactionCommitted = true;

                var emailBody = CreateReviewEmail(registration);

                var emailSent = await SendReviewEmailAsync(
                    registration, "More Information Required for Vendor Registration", emailBody);

                return new RegistrationDeclinedResponse
                {
                    RegistrationId = registration.Id,
                    Status = registration.Status,
                    EmailSent = emailSent,
                    FirstName = registration.FirstName,
                    MiddleName = registration.MiddleName,
                    LastName = registration.LastName,
                    BusinessName = registration.BusinessName,
                    ReviewReason = registration.ReviewReason,
                    ReviewRemarks = registration.ReviewRemarks,
                    AdminId = request.AdminId,
                    ReviewedAt = registration.ReviewedAt.Value,
                    Version = registration.Version
                };
            }
            catch (ConcurrencyConflictException)
            {
                if (!transactionCommitted)
                    await _unitOfWork.RollbackAsync();
                throw new ConcurrencyConflictException("This registration was already reviewed by another admin. Please refresh and try again.");
            }
            catch (Exception)
            {
                if (!transactionCommitted)
                    await _unitOfWork.RollbackAsync();
                throw;
            }
        }

        private void ValidateReviewVersion(VendorRegistrationRequest registration, uint version)
        {
            if (version == 0)
                throw new InvalidRequestException("A valid registration version is required.");

            if (registration.Version != version)
                throw new ConcurrencyConflictException("This registration was already reviewed by another admin. Please refresh and try again.");

            _vendorRepository.SetOriginalVersion(registration, version);
        }

        private async Task ValidateRegistrationIdentityAsync(string email, string businessAccountNumber)
        {
            if (await _userRepository.FindByEmailAsync(email) is not null)
                throw new InvalidRequestException("Email is already registered.");

            if (await _vendorRepository.RegistrationEmailExistsAsync(email))
                throw new InvalidRequestException("A vendor registration request already uses this email address. Check your existing request or contact the market administration office.");

            if (await _vendorRepository.RegistrationBusinessAccountNumberExistsAsync(businessAccountNumber))
                throw new InvalidRequestException("Business Account Number is already used by a vendor or registration request.");
        }

        private static string CreateReviewEmail(VendorRegistrationRequest registration, string? username = null)
        {
            var (heading, status, statusColor, message, nextStep) = registration.Status switch
            {
                RequestStatus.Approved => (
                    "Your vendor registration is approved", "APPROVED", "#4C8B5A",
                    "Your registration has been approved. Your vendor account is ready to use.",
                    "Open the Marikina Market mobile app and sign in with your username and the password you provided during registration."),
                RequestStatus.Rejected => (
                    "Your vendor registration was rejected", "REJECTED", "#C0392B",
                    "We are unable to approve your registration at this time. Please review the reason and remarks below.",
                    "If you have questions about this decision, please contact the market administration office."),
                RequestStatus.NeedsInformation => (
                    "More information is needed", "NEEDS INFORMATION", "#B8792F",
                    "We need additional information before we can complete the review of your registration.",
                    "Please prepare the information or documents described in the remarks and contact the market administration office for instructions on providing them."),
                _ => throw new InvalidRequestException("Invalid registration review status.")
            };

            var rows = ReviewEmailRow("Store name", registration.BusinessName)
                + ReviewEmailRow("Registered email", registration.Email);
            rows += registration.Status == RequestStatus.Approved
                ? ReviewEmailRow("Username", username)
                : ReviewEmailRow("Reason", registration.ReviewReason)
                    + ReviewEmailRow("Remarks", registration.ReviewRemarks);

            return $@"
          <p style=""margin:0 0 14px;color:{statusColor};font-size:11px;letter-spacing:1px;font-weight:bold;"">{status}</p>
          <h1 style=""margin:0 0 22px;color:#0B2D5B;font-size:26px;line-height:1.3;"">{heading}</h1>
          <p style=""margin:0 0 12px;font-size:15px;line-height:1.7;"">Hello {HtmlEncoder.Default.Encode(registration.FirstName)},</p>
          <p style=""margin:0 0 22px;font-size:15px;line-height:1.7;"">{message}</p>
          <table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""background-color:#E9F0F8;border:1px solid #D9E1EC;border-radius:8px;table-layout:fixed;"">{rows}</table>
          <table role=""presentation"" width=""100%"" cellpadding=""0"" cellspacing=""0"" style=""margin-top:24px;""><tr><td style=""padding:16px 18px;border-left:3px solid {statusColor};background-color:#F8FAFD;"">
            <p style=""margin:0 0 6px;color:#0B2D5B;font-size:14px;font-weight:bold;"">Next steps</p>
            <p style=""margin:0;font-size:14px;line-height:1.7;"">{nextStep}</p>
          </td></tr></table>
          <p style=""margin:24px 0 0;font-size:14px;line-height:1.7;"">Thank you,<br><strong style=""color:#0B2D5B;"">Marikina City Public Market</strong></p>";
        }

        private static string ReviewEmailRow(string label, string? value)
        {
            var lines = (value ?? "").Replace("\r\n", "\n").Replace("\r", "\n").Split('\n');
            var encodedValue = string.Join("<br>", lines.Select(line => HtmlEncoder.Default.Encode(line)));
            return $@"<tr><td valign=""top"" width=""32%"" style=""padding:14px 12px;border-bottom:1px solid #D9E1EC;color:#5B6472;font-size:13px;line-height:1.6;"">{HtmlEncoder.Default.Encode(label)}</td><td valign=""top"" style=""padding:14px 12px;border-bottom:1px solid #D9E1EC;color:#0B2D5B;font-size:14px;font-weight:bold;line-height:1.6;overflow-wrap:anywhere;word-break:break-word;"">{encodedValue}</td></tr>";
        }

        private async Task<bool> SendReviewEmailAsync(
            VendorRegistrationRequest registration, string subject, string body)
        {
            try
            {
                var accentColor = registration.Status switch
                {
                    RequestStatus.Approved => "#4C8B5A",
                    RequestStatus.Rejected => "#C0392B",
                    RequestStatus.NeedsInformation => "#B8792F",
                    _ => "#0B2D5B"
                };
                await _emailService.SendEmailAsync(registration.Email, subject, body, accentColor);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    "Review email failed for vendor registration {RegistrationId}. Error type: {ErrorType}",
                    registration.Id, ex.GetType().Name);
                return false;
            }
        }

        private static int CalculateAge(DateOnly dateOfBirth)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var age = today.Year - dateOfBirth.Year;

            if (dateOfBirth > today.AddYears(-age))
                age--;

            return age;
        }

        private static void ValidateDocumentFile(IFormFile file, string fieldName)
        {
            const long maximumFileSize = 5 * 1024 * 1024;
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            var allowedTypes = new Dictionary<string, string[]>
            {
                [".jpg"] = ["image/jpeg", "image/jpg"],
                [".jpeg"] = ["image/jpeg", "image/jpg"],
                [".png"] = ["image/png"],
                [".pdf"] = ["application/pdf"]
            };

            if (file.Length <= 0)
                throw new ValidationException($"{fieldName} cannot be empty.");

            if (file.Length > maximumFileSize)
                throw new ValidationException($"{fieldName} must not exceed 5 MB.");

            if (!allowedTypes.TryGetValue(extension, out var contentTypes) ||
                !contentTypes.Contains(file.ContentType, StringComparer.OrdinalIgnoreCase))
            {
                throw new ValidationException($"{fieldName} must be a JPG, PNG, or PDF file.");
            }
        }

        private static string CreateRegistrationDocumentKey(IFormFile file)
        {
            var extension = Path.GetExtension(file.FileName);
            var datePath = DateTime.UtcNow.ToString("yyyy/MM");
            return $"vendor-registrations/{datePath}/{Guid.NewGuid()}{extension}";
        }

        private string GenerateUniqueQrToken()
        {
            var bytes = RandomNumberGenerator.GetBytes(16);
            return Convert.ToHexString(bytes).ToLowerInvariant();
        }

        public async Task<List<GetVendorResponse>> GetVendorByBusinessAccountNumberAsync(string businessAccountNumber)
        {
            var vendors = await _vendorRepository.GetVendorByBusinessAccountNumber(businessAccountNumber);

            return vendors.Select(v => new GetVendorResponse
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
            }).ToList();
        }

        public async Task<GetVendorResponse> GetVendorByQrCode(string qrCode)
        {
            var vendor = await _vendorRepository.GetVendorByQrCode(qrCode);

            if (vendor == null)
                throw new RecordNotFoundException("Vendor not found.");

            return new GetVendorResponse
            {
                VendorId = vendor.VendorId,
                Username = vendor.Username,
                Type = vendor.Type,
                BusinessAccountNumber = vendor.BusinessAccountNumber,
                StallNumber = vendor.StallNumber,
                TradeName = vendor.TradeName,
                LastName = vendor.LastName,
                FirstName = vendor.FirstName,
                MiddleName = vendor.MiddleName,
                Address = vendor.Address ?? "",
                MarketSectionId = vendor.MarketSectionId,
                MarketSectionName = vendor.MarketSectionName
            };
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

        public async Task<VendorRegistrationStatusCountsResponse> GetVendorRegistrationStatusCountsAsync()
        {
            var counts = await _vendorRepository.GetVendorRegistrationStatusCountsAsync();

            return new VendorRegistrationStatusCountsResponse
            {
                PendingReview = counts.PendingReview,
                NeedsInformation = counts.NeedsInformation,
                Approved = counts.Approved,
                Rejected = counts.Rejected
            };
        }

        public async Task<PageResponse<VendorRegistrationSummaryResponse>> GetVendorRegistrationSummariesAsync(
            int offset,
            VendorRegistrationRequestFilters filters)
        {
            const int pageSize = 10;
            var requests = await _vendorRepository.GetVendorRegistrationSummariesAsync(
                offset,
                pageSize,
                filters);
            var total = await _vendorRepository.GetVendorRegistrationSummaryCountAsync(filters);

            return new PageResponse<VendorRegistrationSummaryResponse>
            {
                Items = requests.Select(request => new VendorRegistrationSummaryResponse
                {
                    RegistrationId = request.RegistrationId,
                    BusinessAccountNumber = request.BusinessAccountNumber,
                    BusinessName = request.BusinessName,
                    VendorName = request.VendorName,
                    BusinessType = request.BusinessType,
                    MarketSectionName = request.MarketSectionName,
                    StallNumber = request.StallNumber,
                    RequestedAt = request.RequestedAt,
                    Status = request.Status,
                    Version = request.Version
                }).ToList(),
                HasMore = offset + requests.Count < total,
                Total = total
            };
        }

        public async Task<VendorRegistrationDetailsResponse> GetVendorRegistrationDetailsAsync(int registrationId)
        {
            var registration = await GetRegistrationAsync(registrationId);
            var documents = await GetRegistrationDocumentsAsync(registration);

            return new VendorRegistrationDetailsResponse
            {
                RegistrationId = registration.Id,
                Version = registration.Version,
                BusinessAccountNumber = registration.BusinessAccountNumber,
                BusinessName = registration.BusinessName,
                NatureOfBusiness = registration.NatureOfBusiness,
                BusinessType = registration.Type,
                MarketSectionName = registration.MarketSection?.Name ?? "",
                StallNumber = registration.StallNumber,
                FirstName = registration.FirstName,
                MiddleName = registration.MiddleName,
                LastName = registration.LastName,
                DateOfBirth = registration.DateOfBirth,
                Age = registration.Age,
                GovernmentIdType = registration.GovernmentIdType,
                GovernmentIdNumber = registration.GovernmentIdNumber,
                PhoneNumber = registration.PhoneNumber,
                Email = registration.Email,
                HouseNumber = registration.HouseNumber,
                Street = registration.Street,
                Barangay = registration.Barangay,
                City = registration.City,
                Status = registration.Status,
                RequestedAt = registration.RequestedAt,
                ReviewedAt = registration.ReviewedAt,
                ReviewerName = registration.ReviewedByUser is null
                    ? null
                    : FormatVendorName(
                        registration.ReviewedByUser.FirstName,
                        registration.ReviewedByUser.MiddleName,
                        registration.ReviewedByUser.LastName),
                RemarksOrReason = registration.RemarksOrReason,
                ReviewReason = registration.ReviewReason,
                ReviewRemarks = registration.ReviewRemarks,
                Documents = documents
            };
        }

        public async Task<List<VendorRegistrationDocumentResponse>> GetVendorRegistrationDocumentsAsync(
            int registrationId)
        {
            var registration = await GetRegistrationAsync(registrationId);
            return await GetRegistrationDocumentsAsync(registration);
        }

        private async Task<VendorRegistrationRequest> GetRegistrationAsync(int registrationId)
        {
            var registration = await _vendorRepository.GetRegistrationById(registrationId);

            if (registration is null)
                throw new RecordNotFoundException("Vendor registration request not found.");

            return registration;
        }

        private async Task<List<VendorRegistrationDocumentResponse>> GetRegistrationDocumentsAsync(
            VendorRegistrationRequest registration)
        {
            var documents = new[]
            {
                ("Government ID", registration.GovernmentIdPhotoUrl),
                ("Business document", registration.BusinessDocumentPhotoUrl)
            };

            var result = new List<VendorRegistrationDocumentResponse>();

            foreach (var (documentType, key) in documents)
            {
                if (string.IsNullOrWhiteSpace(key))
                    continue;

                var metadata = await _storageService.GetFileMetadataAsync(B2BucketType.Documents, key);
                if (metadata is null)
                    continue;

                var url = await _storageService.GetPresignedUrlAsync(B2BucketType.Documents, key);

                result.Add(new VendorRegistrationDocumentResponse
                {
                    DocumentType = documentType,
                    FileName = Path.GetFileName(key),
                    ContentType = metadata.ContentType,
                    Size = metadata.Size,
                    Url = url
                });
            }

            return result;
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
