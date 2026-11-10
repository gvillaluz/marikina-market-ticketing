using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// Review and Verify (criterion 5): Verify checks the corrected details again against the
// tickets as they are now, and saves nothing. The ticket and ordinance queries are the real ones,
// run over an in-memory list of tickets, so a ticket added between two Verifies is seen.
public class ReviewVerifyTests
{
    [Fact]
    public async Task Verify_reads_the_offense_history_as_it_is_now()
    {
        using var world = new World();

        // One earlier ticket on Sec. 12: this one is the 2nd offense, P1,000.00.
        var first = Assert.Single((await world.Service.VerifyInspectionAsync(world.Request())).Calculation.Breakdown);
        Assert.Equal(2, first.OffenseNumber);
        Assert.Equal(1000m, first.PaymentAmount);

        // Another officer's ticket for the same person and section is saved before the second Verify.
        world.AddTicket(id: 2, ordinance: world.Sec12, status: TicketStatus.Paid,
            issuedAt: new DateTime(2026, 11, 2, 2, 0, 0, DateTimeKind.Utc), paperReference: "000200");

        // Now it is the 3rd offense, P1,500.00.
        var again = await world.Service.VerifyInspectionAsync(world.Request());
        var line = Assert.Single(again.Calculation.Breakdown);
        Assert.Equal(3, line.OffenseNumber);
        Assert.Equal(1500m, line.PaymentAmount);
        Assert.Equal(1500m, again.Calculation.TotalPaymentAmount);
    }

    [Fact]
    public async Task Verify_twice_saves_nothing_and_adds_no_offense()
    {
        using var world = new World();

        var first = await world.Service.VerifyInspectionAsync(world.Request());
        var second = await world.Service.VerifyInspectionAsync(world.Request());

        // The first Verify did not count as an offense: both say 2nd offense, P1,000.00.
        Assert.Equal(2, Assert.Single(first.Calculation.Breakdown).OffenseNumber);
        Assert.Equal(2, Assert.Single(second.Calculation.Breakdown).OffenseNumber);
        Assert.Equal(1000m, second.Calculation.TotalPaymentAmount);
        // Still only the one earlier ticket; nothing was saved, uploaded or sent.
        Assert.Single(world.Tickets);
        Assert.Single(world.Sec12.TicketViolations);
        Assert.Equal(0, world.SaveCalls);
        Assert.Equal(0, world.UploadCalls);
        Assert.Equal(0, world.NotificationCalls);
    }

    [Fact]
    public async Task Verify_checks_a_corrected_control_number_again()
    {
        using var world = new World();
        var request = world.Request();
        request.PaperReference = "000100"; // already on the earlier ticket

        var error = await Assert.ThrowsAsync<ConcurrencyConflictException>(() => world.Service.VerifyInspectionAsync(request));
        Assert.Equal("A citation with this control number already exists. Review the control number before submitting.", error.Message);

        // The enforcer goes Back, fixes the number and verifies again.
        request.PaperReference = " 000457 ";
        var verified = await world.Service.VerifyInspectionAsync(request);
        Assert.Equal(1000m, verified.Calculation.TotalPaymentAmount);
        Assert.Single(world.Tickets);
    }

    [Fact]
    public async Task Verify_checks_corrected_ordinances_for_a_same_day_duplicate_again()
    {
        using var world = new World();
        // A pending ticket from this morning for the same person on Sec. 13.
        world.AddTicket(id: 3, ordinance: world.Sec13, status: TicketStatus.Pending,
            issuedAt: DateTime.UtcNow, paperReference: "000300");
        var request = world.Request();
        request.OrdinanceIds = [world.Sec13.Id];

        var error = await Assert.ThrowsAsync<DuplicateOrdinanceException>(() => world.Service.VerifyInspectionAsync(request));
        Assert.Equal(world.Sec13.Id, Assert.Single(error.DuplicateOrdinances).OrdinanceId);

        // The enforcer goes Back, picks Sec. 12 instead and verifies again.
        request.OrdinanceIds = [world.Sec12.Id];
        var line = Assert.Single((await world.Service.VerifyInspectionAsync(request)).Calculation.Breakdown);
        Assert.Equal(world.Sec12.Id, line.OrdinanceId);
        Assert.Equal(2, line.OffenseNumber);
        Assert.Equal(2, world.Tickets.Count);
    }

    // Juan Dela Cruz (person 31) at Reyes Fresh Fish (business 17). Sec. 12 has fixed fines of
    // P500.00, P1,000.00 and P1,500.00 for the 1st, 2nd and 3rd offense; he has one earlier,
    // paid ticket on it (control number 000100). Sec. 13 has a P200.00 1st-offense fine.
    private sealed class World : IDisposable
    {
        public List<Ticket> Tickets { get; } = [];
        public Ordinance Sec12 { get; } = Ordinance(5, "12", "Market ID", 500m, 1000m, 1500m);
        public Ordinance Sec13 { get; } = Ordinance(6, "13", "Public places", 200m);
        public int SaveCalls, UploadCalls, NotificationCalls;
        public TicketService Service { get; }
        private readonly AppDbContext _context = new(new DbContextOptionsBuilder<AppDbContext>().Options);

        public World()
        {
            _context.Tickets = new AccountDatabaseSet<Ticket>(Tickets);
            _context.Ordinances = new AccountDatabaseSet<Ordinance>([Sec12, Sec13]);
            _context.Persons = new AccountDatabaseSet<Person>([new() { Id = 31, FullName = "Juan Dela Cruz", Address = "12 Market Lane" }]);
            AddTicket(id: 1, ordinance: Sec12, status: TicketStatus.Paid,
                issuedAt: new DateTime(2026, 10, 1, 2, 0, 0, DateTimeKind.Utc), paperReference: "000100");

            var business = ReviewBoundaryProxy.Create<IVendorRepository>((method, args) =>
                Task.FromResult<VendorTicketSummary?>((int)args[0]! != 17 ? null : new()
                {
                    Id = 17, FirstName = "Juan", LastName = "Reyes", Email = "", BusinessAccountNumber = "MM-17",
                    BusinessName = "Reyes Fresh Fish", MarketSectionId = 1, MarketSectionName = "Fish and Seafood",
                    BusinessAddress = "14 Market Street Santo Nino Marikina", StallNumber = "F-014", Type = BusinessType.Public
                }));
            var unit = ReviewBoundaryProxy.Create<IUnitOfWork>((method, args) =>
            {
                SaveCalls++;
                return method.ReturnType == typeof(Task<int>) ? Task.FromResult(1) : Task.CompletedTask;
            });
            var storage = ReviewBoundaryProxy.Create<IStorageService>((method, args) =>
                { UploadCalls++; return Task.FromResult(new List<string>()); });
            var notifications = ReviewBoundaryProxy.Create<INotificationService>((method, args) =>
                { NotificationCalls++; return Task.CompletedTask; });
            var compliance = ReviewBoundaryProxy.Create<IVendorComplianceScoreService>((method, args) =>
                throw new InvalidOperationException(method.Name));
            Service = new TicketService(new TicketRepository(_context), new OrdinanceRepository(_context), business, unit,
                storage, notifications, compliance, personRepository: new PersonRepository(_context));
        }

        public void AddTicket(int id, Ordinance ordinance, TicketStatus status, DateTime issuedAt, string paperReference)
        {
            var ticket = new Ticket
            {
                Id = id, PersonId = 31, PaperViolatorName = "Juan Cruz", VendorId = 17, Type = ViolationType.Ticket,
                Status = status, IssuedAt = issuedAt, PaperReference = paperReference, Description = "Synthetic citation"
            };
            var line = new TicketViolation { TicketId = id, Ticket = ticket, OrdinanceId = ordinance.Id, Ordinance = ordinance };
            ticket.TicketViolations = [line];
            ordinance.TicketViolations.Add(line);
            Tickets.Add(ticket);
        }

        public VerifyInspectionRequest Request() => new()
        {
            VendorId = 17, PersonId = 31, PaperViolatorName = "Juan Cruz", PaperReference = "000456",
            IssuePlace = "Fish aisle near F-014", OrdinanceIds = [Sec12.Id], Description = "Market identification card not displayed",
            PenaltyType = PenaltyType.CashFine, EvidenceCount = 2, PaperTicketPhotoCount = 1, SupportingEvidenceCount = 1
        };

        private static Ordinance Ordinance(int id, string section, string title, params decimal[] fines) => new()
        {
            Id = id, OrdinanceNo = "011", Series = "2014", Section = section, Title = title, Severity = Severity.Minor,
            Category = ViolationCategory.Licensing,
            PenaltyTiers = fines.Select((fine, index) => new OrdinancePenaltyTier
            {
                OrdinanceId = id, OffenseNumber = index + 1, FineKind = FineKind.Fixed, PenaltyAmount = fine
            }).ToList()
        };

        public void Dispose() => _context.Dispose();
    }
}
