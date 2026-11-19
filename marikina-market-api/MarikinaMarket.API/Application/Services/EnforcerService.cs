using MarikinaMarket.API.Application.DTOs.Enforcers.Internal;
using MarikinaMarket.API.Application.DTOs.Enforcers.Request;
using MarikinaMarket.API.Application.DTOs.Enforcers.Response;
using MarikinaMarket.API.Application.DTOs.Reports.Response;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.Interfaces;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using System.ComponentModel.DataAnnotations;
using System.Globalization;

namespace MarikinaMarket.API.Application.Services
{
    public class EnforcerService : IEnforcerService
    {
        private readonly IUserRepository _userRepository;
        private readonly ITicketRepository _ticketRepository;
        private readonly IStorageService _storageService;
        private readonly TimeProvider _clock;

        private const int PAGE_SIZE = 10;

        public EnforcerService(
            IUserRepository userRepository,
            ITicketRepository ticketRepository,
            IStorageService storageService,
            TimeProvider? clock = null
            )
        {
            _userRepository = userRepository;
            _ticketRepository = ticketRepository;
            _storageService = storageService;
            _clock = clock ?? TimeProvider.System;
        }

        public async Task<PageResponse<AdminEnforcerSummaryResponse>> GetEnforcerSummaryAsync(int offset, EnforcerSummaryFilter filters)
        {
            offset = Math.Max(offset, 0);

            var enforcers = await _userRepository.GetEnforcersAsync(offset, PAGE_SIZE, filters);

            if (enforcers is null || enforcers.Count == 0)
                return new PageResponse<AdminEnforcerSummaryResponse> { Items = [], HasMore = false };

            bool hasMore = enforcers.Count() > PAGE_SIZE;
            if (hasMore)
                enforcers.RemoveAt(enforcers.Count - 1);

            var totalEnforcers = await _userRepository.GetEnforcersCountAsync(filters);

            var enforcerTickets = await _ticketRepository.GetEnforcerTicketCountAsync(enforcers.Select(e => e.Id).ToList());

            var profileKeys = enforcers
                .Select(e => e.ProfilePictureUrl)
                .OfType<string>() 
                .Where(url => !string.IsNullOrEmpty(url))
                .Distinct()
                .ToList()!;

            var profiles = profileKeys.Count > 0
                ? await _storageService.GetPresignedUrlsAsync(B2BucketType.General, profileKeys)
                : new Dictionary<string, string>();

            var items = enforcers.Select(e =>
            {
                var counts = enforcerTickets.FirstOrDefault(t => t.EnforcerId == e.Id);

                string? profileUrl = null;
                if (!string.IsNullOrEmpty(e.ProfilePictureUrl))
                    profiles.TryGetValue(e.ProfilePictureUrl, out profileUrl);

                return new AdminEnforcerSummaryResponse
                {
                    EnforcerId = e.Id,
                    Username = e.UserName ?? "",
                    FirstName = e.FirstName,
                    LastName = e.LastName,
                    Status = e.Status,
                    ProfileUrl = profileUrl ?? "",
                    WarningViolationCount = counts?.WarningCount ?? 0,
                    TicketViolationCount = counts?.TicketCount ?? 0,
                };
            }).ToList();
            
            return new PageResponse<AdminEnforcerSummaryResponse>
            {
                Items = items,
                HasMore = hasMore,
                Total = totalEnforcers
            };
        }

        public async Task<ActivityPanelDataResponse> GetDailyTicketsAverage()
        {
            var now = DateTime.UtcNow;
            var startOfThisMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

            var dailyTickets = await _ticketRepository.GetTicketsWithDateAsync(startOfThisMonth);
            var topEnforcers = await _ticketRepository.GetTopEnforcersAsync(startOfThisMonth);
            
            var activeDays = dailyTickets.Count;

            var totalTickets = dailyTickets.Sum(t => t.TicketCount);
            var totalWarnings = dailyTickets.Sum(t => t.WarningCount);

            var averageTicketPerDay = activeDays == 0 ? 0 : Math.Round((double)totalTickets / activeDays, 2);
            var averageWarningPerDay = activeDays == 0 ? 0 : Math.Round((double)totalWarnings / activeDays, 2);

            return new ActivityPanelDataResponse
            {
                TotalTicketCount = totalTickets,
                TotalWarningCount = totalWarnings,
                AverageTicketsPerDay = averageTicketPerDay,
                AverageWarningsPerDay = averageWarningPerDay,
                TopEnforcers = topEnforcers
            };
        }

        public async Task<PerformanceSummaryResponse> GetPerformanceSummaryAsync(int enforcerId)
        {
            var manilaTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Manila");
            var manilaYear = TimeZoneInfo.ConvertTimeFromUtc(_clock.GetUtcNow().UtcDateTime, manilaTimeZone).Year;
            var yearStart = TimeZoneInfo.ConvertTimeToUtc(new DateTime(manilaYear, 1, 1), manilaTimeZone);
            var yearEnd = TimeZoneInfo.ConvertTimeToUtc(new DateTime(manilaYear + 1, 1, 1), manilaTimeZone);

            return await _ticketRepository.GetEnforcerPerformanceSummaryAsync(enforcerId, yearStart, yearEnd);
        }

        public async Task<EnforcerInfoResponse> GetProfileAsync(int enforcerId)
        {
            var user = await _userRepository.GetUserAsync(enforcerId);

            if (user is null || await _userRepository.GetRoleAsync(user) != Role.MarketEnforcer)
                throw new RecordNotFoundException("Enforcer not found.");

            var lastInspection = await _ticketRepository.GetLastEnforcerInspectionAsync(enforcerId);

            return new EnforcerInfoResponse
            {
                EnforcerId = enforcerId,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Username = user.UserName!,
                MiddleName = user.MiddleName ?? null,
                PhoneNumber = user.PhoneNumber!,
                Email = user.Email!,
                Status = user.Status,
                Role = Role.MarketEnforcer,
                HiredAt = user.CreatedAt,
                ProfileUrl = user.ProfilePictureUrl ?? null,
                LastInspectionDate = lastInspection
            };
        }

        public async Task<PageResponse<InspectionResponse>> GetInspectionHistoryAsync(int enforcerId, int offset)
        {
            offset = Math.Max(offset, 0);

            var inspections = await _ticketRepository.GetEnforcerInspectionHistory(enforcerId, offset, PAGE_SIZE);

            if (inspections is null || inspections.Count == 0)
                return new PageResponse<InspectionResponse> { Items = [], HasMore = false };

            bool hasMore = inspections.Count() > PAGE_SIZE;
            if (hasMore)
                inspections.RemoveAt(inspections.Count - 1);

            var totalInspections = await _ticketRepository.GetTotalIssuedTicketsByEnforcerIdAsync(enforcerId);

            var inspectionResponse = inspections.Select(i => new InspectionResponse
            {
                BusinessSnapshot = i.BusinessSnapshot,
                TicketId = i.Id,
                ControlNumber = i.Type == ViolationType.Warning ? i.ControlNumber : i.PaperReference,
                IssuedAt = i.IssuedAt,
                VendorId = i.VendorId,
                VendorFirstName = i.FirstName,
                VendorLastName = i.LastName,
                StallNumber = i.StallNumber ?? "",
                MarketSectionId = i.MarketSectionId,
                MarketSectionName = i.MarketSectionName,
                Type = i.Type,
                Status = i.Status
            }).ToList();

            return new PageResponse<InspectionResponse>
            {
                Items = inspectionResponse,
                HasMore = hasMore,
                Total = totalInspections
            };
        }

        // Every active enforcer, plus inactive ones with records in the period. Most records first, then by name.
        public async Task<EnforcerReportResponse> GetReportAsync(string? from, string? to)
        {
            var (fromDate, toDate, startUtc, endUtc) = ManilaDateRange(from, to);

            var enforcers = await _userRepository.GetAllEnforcersAsync();
            var days = await _ticketRepository.GetEnforcerReportDaysAsync(startUtc, endUtc);

            var rows = enforcers
                .Select(e => ReportRow(e, days.Where(d => d.EnforcerId == e.Id).ToList()))
                .Where(r => r.Status == AccountStatus.Active || r.TotalRecords > 0)
                .OrderByDescending(r => r.TotalRecords)
                .ThenBy(r => r.LastName)
                .ThenBy(r => r.FirstName)
                .ToList();

            return new EnforcerReportResponse
            {
                DateRange = new ReportDateRangeResponse { From = fromDate, To = toDate },
                Enforcers = rows,
                Totals = new EnforcerReportTotalsResponse
                {
                    Warnings = rows.Sum(r => r.Warnings),
                    Tickets = rows.Sum(r => r.Tickets),
                    TotalRecords = rows.Sum(r => r.TotalRecords),
                    SettledTickets = rows.Sum(r => r.SettledTickets),
                    OpenTickets = rows.Sum(r => r.OpenTickets),
                    FinesCharged = rows.Sum(r => r.FinesCharged),
                    FinesSettled = rows.Sum(r => r.FinesSettled)
                }
            };
        }

        private static EnforcerReportRowResponse ReportRow(User enforcer, List<EnforcerReportDay> days)
        {
            var warnings = days.Sum(d => d.Warnings);
            var tickets = days.Sum(d => d.Tickets);
            var settled = days.Sum(d => d.SettledTickets);

            return new EnforcerReportRowResponse
            {
                EnforcerId = enforcer.Id,
                Username = enforcer.UserName ?? "",
                FirstName = enforcer.FirstName,
                LastName = enforcer.LastName,
                Status = enforcer.Status,
                Warnings = warnings,
                Tickets = tickets,
                TotalRecords = warnings + tickets,
                SettledTickets = settled,
                OpenTickets = tickets - settled,
                FinesCharged = days.Sum(d => d.FinesCharged),
                FinesSettled = days.Sum(d => d.FinesSettled),
                DaysWithRecords = days.Count,
                LastRecordAt = days.Count == 0 ? null : days.Max(d => d.LastRecordAt)
            };
        }

        // The From and To dates as whole Philippine days, and the UTC moments they start and end.
        private static (DateOnly From, DateOnly To, DateTime StartUtc, DateTime EndUtc) ManilaDateRange(string? fromValue, string? toValue)
        {
            if (!DateOnly.TryParseExact(fromValue, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var from) ||
                !DateOnly.TryParseExact(toValue, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var to))
                throw new ValidationException("Dates are required and must use YYYY-MM-DD.");
            if (from > to) throw new ValidationException("From must be on or before to.");
            if (to == DateOnly.MaxValue)
                throw new ValidationException("Dates are outside the supported report range.");

            var zone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Manila");
            var startUtc = TimeZoneInfo.ConvertTimeToUtc(from.ToDateTime(TimeOnly.MinValue), zone);
            var endUtc = TimeZoneInfo.ConvertTimeToUtc(to.AddDays(1).ToDateTime(TimeOnly.MinValue), zone);
            return (from, to, startUtc, endUtc);
        }
    }
}