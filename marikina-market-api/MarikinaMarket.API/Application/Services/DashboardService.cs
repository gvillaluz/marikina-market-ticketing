using MarikinaMarket.API.Application.DTOs.Analytics.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.DTOs.User.Response;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;

namespace MarikinaMarket.API.Application.Services
{
    public class DashboardService : IDashboardService
    {
        private const int RECENT_ACTIVITY_LIMIT = 5;
        private const int OVERDUE_TICKET_LIMIT = 5;
        private const int OVERDUE_AFTER_DAYS = 5;
        private readonly ITicketRepository _ticketRepository;
        private readonly IVendorRepository _vendorRepository;
        private readonly IAuditLogRepository _auditLogRepository;
        private readonly IUserRepository _userRepository;

        public DashboardService(
            ITicketRepository ticketRepository,
            IVendorRepository vendorRepository,
            IAuditLogRepository auditLogRepository,
            IUserRepository userRepository)
        {
            _ticketRepository = ticketRepository;
            _vendorRepository = vendorRepository;
            _auditLogRepository = auditLogRepository;
            _userRepository = userRepository;
        }

        public async Task<DashboardSummaryResponse> GetSummaryAsync()
        {
            var asOf = DateTime.UtcNow;
            var manilaTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Asia/Manila");
            var localToday = TimeZoneInfo.ConvertTimeFromUtc(asOf, manilaTimeZone).Date;
            var startUtc = TimeZoneInfo.ConvertTimeToUtc(
                DateTime.SpecifyKind(localToday, DateTimeKind.Unspecified), manilaTimeZone);
            var endUtc = TimeZoneInfo.ConvertTimeToUtc(
                DateTime.SpecifyKind(localToday.AddDays(1), DateTimeKind.Unspecified), manilaTimeZone);

            var ticketCounts = await _ticketRepository.GetDashboardTicketCountsAsync(startUtc, endUtc);
            var activeBusinesses = await _vendorRepository.GetActiveBusinessCountAsync();
            var activities = await _auditLogRepository.GetRecentDashboardActivitiesAsync(RECENT_ACTIVITY_LIMIT);
            var overdueTickets = await _ticketRepository.GetDashboardOverdueTicketsAsync(OVERDUE_TICKET_LIMIT);

            var actorIds = activities
                .Where(activity => activity.UserId.HasValue)
                .Select(activity => activity.UserId!.Value)
                .Distinct()
                .ToArray();
            var actorNames = actorIds.Length == 0
                ? new Dictionary<int, UserNamesResponse>()
                : await _userRepository.GetNamesByIdsAsync(actorIds);

            return new DashboardSummaryResponse
            {
                AsOf = asOf,
                Metrics = new DashboardMetricsResponse
                {
                    WarningsToday = ticketCounts.WarningsToday,
                    TicketsToday = ticketCounts.TicketsToday,
                    OpenTickets = ticketCounts.OpenTickets,
                    ActiveBusinesses = activeBusinesses
                },
                RecentActivity = activities.Select(activity => MapActivity(activity, actorNames)).ToList(),
                OverdueTickets = new DashboardOverdueTicketsResponse
                {
                    Total = overdueTickets.Total,
                    Items = overdueTickets.Items.Select(ticket => new DashboardOverdueTicketResponse
                    {
                        Id = ticket.Id,
                        ControlNumber = ticket.ControlNumber,
                        VendorId = ticket.VendorId,
                        BusinessName = ticket.BusinessName,
                        DaysOverdue = CountDaysOverdue(ticket.IssuedAt, asOf)
                    }).ToList()
                }
            };
        }

        // Whole Manila days since the due date (5 days after issue). A ticket set to Overdue by hand
        // before its due date counts as 0.
        public static int CountDaysOverdue(DateTime issuedAtUtc, DateTime asOfUtc)
        {
            var manila = TimeZoneInfo.FindSystemTimeZoneById("Asia/Manila");
            var dueDate = TimeZoneInfo.ConvertTimeFromUtc(issuedAtUtc.AddDays(OVERDUE_AFTER_DAYS), manila).Date;
            var today = TimeZoneInfo.ConvertTimeFromUtc(asOfUtc, manila).Date;
            return Math.Max(0, (today - dueDate).Days);
        }

        private static DashboardActivityResponse MapActivity(
            AuditLog activity,
            IReadOnlyDictionary<int, UserNamesResponse> actorNames)
        {
            var category = activity.Module switch
            {
                Module.Tickets when activity.Action == "SaveNewInspection" => "Inspection",
                Module.Tickets => "Ticket",
                Module.Vendors => "VendorRegistration",
                Module.Users or Module.Security => "Account",
                _ => "Account"
            };
            var title = category == "Inspection"
                ? activity.Result == LogResult.Success ? "Inspection completed" : "Inspection failed"
                : Humanize(activity.Action);
            string? actorName = null;
            if (activity.UserId.HasValue && actorNames.TryGetValue(activity.UserId.Value, out var user))
                actorName = $"{user.FirstName} {user.LastName}";

            return new DashboardActivityResponse
            {
                Id = activity.Id,
                OccurredAt = activity.Timestamp,
                Category = category,
                Title = title,
                Description = activity.Details,
                ActorName = actorName
            };
        }

        private static string Humanize(string action)
        {
            if (string.IsNullOrWhiteSpace(action)) return "Activity";
            var title = new System.Text.StringBuilder(action.Length + 8);
            for (var index = 0; index < action.Length; index++)
            {
                if (index > 0 && char.IsUpper(action[index]) && char.IsLower(action[index - 1]))
                    title.Append(' ');
                title.Append(action[index]);
            }
            return title.ToString();
        }
    }
}
