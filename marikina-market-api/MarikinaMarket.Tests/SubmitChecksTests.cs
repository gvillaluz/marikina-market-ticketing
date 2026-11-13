using System.Reflection;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Tickets.Request;
using MarikinaMarket.API.Application.DTOs.Tickets.Response;
using MarikinaMarket.API.Application.DTOs.Vendor.Internal;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarikinaMarket.Tests;

// Submit with no Verify step: the server checks everything when the enforcer presses Submit.
// The ticket, ordinance and person queries are the real ones, run over an in-memory list of
// tickets, so a ticket saved here is seen by the next Submit. Photo storage is faked.
public class SubmitChecksTests
{
    [Fact]
    public async Task Submit_saves_a_ticket_with_no_reviewed_values()
    {
        using var world = new World();

        // One earlier ticket on Sec. 12 (another day): this one is the 2nd offense, P1,000.00.
        var saved = await world.Service.CreateTicketAsync(world.Submit());

        Assert.Equal(2, world.Tickets.Count);
        var ticket = world.Tickets.Single(t => t.Id == saved.Id);
        Assert.Equal(1000m, ticket.TotalPaymentAmount);
        var violation = Assert.Single(ticket.TicketViolations);
        Assert.Equal(2, violation.OffenseCount);
        Assert.Equal(1000m, violation.PenaltyAmount);
        Assert.Equal(1, world.UploadCalls);
        Assert.Equal(1, world.Commits);
    }

    [Fact]
    public async Task The_saved_fine_uses_the_history_at_the_moment_of_Submit()
    {
        using var world = new World();
        // Another officer's ticket on Sec. 12 (already paid, another day) was saved before this Submit:
        // this one is now the 3rd offense, P1,500.00.
        world.AddTicket(id: 2, ordinance: world.Sec12, status: TicketStatus.Paid,
            issuedAt: new DateTime(2026, 11, 2, 2, 0, 0, DateTimeKind.Utc), paperReference: "000200", vendorId: 17);

        var saved = await world.Service.CreateTicketAsync(world.Submit());

        var ticket = world.Tickets.Single(t => t.Id == saved.Id);
        Assert.Equal(3, Assert.Single(ticket.TicketViolations).OffenseCount);
        Assert.Equal(1500m, ticket.TotalPaymentAmount);
    }

    [Fact]
    public async Task The_saved_fine_uses_the_fine_the_office_set_at_the_moment_of_Submit()
    {
        using var world = new World();
        world.Sec12.PenaltyTiers.Single(tier => tier.OffenseNumber == 2).PenaltyAmount = 1200m;

        var saved = await world.Service.CreateTicketAsync(world.Submit());

        Assert.Equal(1200m, world.Tickets.Single(t => t.Id == saved.Id).TotalPaymentAmount);
    }

    [Fact]
    public async Task Sending_the_same_ticket_again_after_a_lost_answer_adds_no_second_offense()
    {
        using var world = new World();

        // The first Submit is saved: Juan now has two Sec. 12 tickets; both photos were uploaded once.
        await world.Service.CreateTicketAsync(world.Submit());
        Assert.Equal(2, world.Tickets.Count);
        Assert.Equal(2, world.Sec12.TicketViolations.Count);
        Assert.Equal(1, world.UploadCalls);
        Assert.Equal(2, world.UploadedFiles);

        // The phone never heard back and sends exactly the same ticket again.
        var repeat = await Assert.ThrowsAsync<ConcurrencyConflictException>(
            () => world.Service.CreateTicketAsync(world.Submit()));
        Assert.Equal("A citation with this control number already exists. Review the control number before submitting.", repeat.Message);

        // The enforcer types a new control number and sends the same ticket once more.
        var retyped = world.Submit();
        retyped.PaperReference = "000457";
        var duplicate = await Assert.ThrowsAsync<DuplicateOrdinanceException>(() => world.Service.CreateTicketAsync(retyped));
        Assert.Equal(world.Sec12.Id, Assert.Single(duplicate.DuplicateOrdinances).OrdinanceId);
        Assert.Equal("This person already has an active citation for a selected ordinance today. Review the ordinances.", duplicate.Message);

        // Still one new ticket and one new offense; no more photos were uploaded.
        Assert.Equal(2, world.Tickets.Count);
        Assert.Equal(2, world.Sec12.TicketViolations.Count);
        Assert.Equal(1, world.UploadCalls);
        Assert.Equal(1, world.Commits);
    }

    [Fact]
    public async Task Submit_repeats_the_same_day_duplicate_check_for_an_unregistered_vendor()
    {
        using var world = new World();
        // Another officer saves a Sec. 13 ticket for Juan, with no business, before this Submit.
        world.AddTicket(id: 2, ordinance: world.Sec13, status: TicketStatus.Pending,
            issuedAt: DateTime.UtcNow, paperReference: "000300", vendorId: null);

        var submit = world.Submit();
        submit.VendorId = null;
        submit.MarketSectionId = World.ActiveSection;
        submit.Ordinances = [world.Sec13.Id];
        var error = await Assert.ThrowsAsync<DuplicateOrdinanceException>(() => world.Service.CreateTicketAsync(submit));
        Assert.Equal(world.Sec13.Id, Assert.Single(error.DuplicateOrdinances).OrdinanceId);

        // Refused before any photo was uploaded; nothing was saved.
        Assert.Equal(2, world.Tickets.Count);
        Assert.Equal(0, world.UploadCalls);
        Assert.Equal(0, world.Commits);
    }

    [Theory]
    [InlineData("used control number", typeof(ConcurrencyConflictException), "A citation with this control number already exists. Review the control number before submitting.")]
    [InlineData("no control number", typeof(System.ComponentModel.DataAnnotations.ValidationException), "Enter the control number and issue place before submitting.")]
    [InlineData("no paper photo", typeof(InvalidRequestException), "Exactly one paper ticket photo and at least one supporting photo are required for tickets.")]
    [InlineData("no supporting photo", typeof(InvalidRequestException), "Exactly one paper ticket photo and at least one supporting photo are required for tickets.")]
    [InlineData("2 service hours", typeof(InvalidRequestException), "Community service requires a minimum of 3 hours.")]
    public async Task Submit_refuses_each_incomplete_ticket_before_any_photo_is_uploaded(string problem, Type expected, string message)
    {
        using var world = new World();
        var submit = world.Submit();
        switch (problem)
        {
            case "used control number": submit.PaperReference = "000100"; break;
            case "no control number": submit.PaperReference = " "; break;
            case "no paper photo": submit.PaperTicketPhoto = []; break;
            case "no supporting photo": submit.SupportingEvidenceFiles = []; break;
            case "2 service hours": submit.PenaltyType = PenaltyType.CommunityService; submit.CommunityServiceHours = 2; break;
        }

        var error = await Assert.ThrowsAsync(expected, () => world.Service.CreateTicketAsync(submit));

        Assert.Equal(message, error.Message);
        Assert.Single(world.Tickets);
        Assert.Equal(0, world.UploadCalls);
        Assert.Equal(0, world.Commits);
    }

    [Fact]
    public async Task A_save_that_collides_with_another_citation_says_to_check_the_history_and_submit_again()
    {
        using var world = new World();
        world.CommitError = new DbUpdateException("Synthetic conflicting save",
            new Npgsql.PostgresException("Synthetic conflict", "ERROR", "ERROR", Npgsql.PostgresErrorCodes.SerializationFailure));

        var error = await Assert.ThrowsAsync<ConcurrencyConflictException>(() => world.Service.CreateTicketAsync(world.Submit()));

        Assert.Equal("Another citation changed this person’s history. Check this person’s history and submit again.", error.Message);
    }

    [Fact]
    public void The_verify_route_and_the_reviewed_values_no_longer_exist()
    {
        var api = typeof(TicketService).Assembly;
        Assert.Null(typeof(ITicketService).GetMethod("VerifyInspectionAsync"));
        Assert.Null(typeof(CreateTicketRequest).GetProperty("ReviewedCalculation"));
        Assert.Null(typeof(CreateTicketRequest).GetProperty("ReviewedBusinessSnapshot"));
        Assert.Null(api.GetType("MarikinaMarket.API.Application.DTOs.Tickets.Request.VerifyInspectionRequest"));
        Assert.Null(api.GetType("MarikinaMarket.API.Application.DTOs.Tickets.Response.InspectionVerificationResponse"));
        var routes = typeof(MarikinaMarket.API.Presentation.Controllers.EnforcerTicketController).GetMethods()
            .SelectMany(method => method.GetCustomAttributes<Microsoft.AspNetCore.Mvc.Routing.HttpMethodAttribute>())
            .Select(attribute => attribute.Template);
        Assert.DoesNotContain("verify", routes);
    }

    // Juan Dela Cruz (person 31) at Reyes Fresh Fish (business 17). Sec. 12 has fixed fines of
    // P500.00, P1,000.00 and P1,500.00 for the 1st, 2nd and 3rd offense; he has one earlier,
    // paid ticket on it (control number 000100). Sec. 13 has a P200.00 1st-offense fine.
    // Section 3 (Meat and Poultry) is the active market section for an unregistered vendor.
    private sealed class World : IDisposable
    {
        public const int ActiveSection = 3;
        public List<Ticket> Tickets { get; } = [];
        public Ordinance Sec12 { get; } = Ordinance(5, "12", "Market ID", 500m, 1000m, 1500m);
        public Ordinance Sec13 { get; } = Ordinance(6, "13", "Public places", 200m);
        public int UploadCalls, UploadedFiles, Commits;
        public Exception? CommitError;
        public TicketService Service { get; }
        private readonly AppDbContext _context = new(new DbContextOptionsBuilder<AppDbContext>().Options);

        public World()
        {
            _context.Tickets = new AccountDatabaseSet<Ticket>(Tickets);
            _context.Ordinances = new AccountDatabaseSet<Ordinance>([Sec12, Sec13]);
            _context.Persons = new AccountDatabaseSet<Person>([new() { Id = 31, FullName = "Juan Dela Cruz", Address = "12 Market Lane" }]);
            AddTicket(id: 1, ordinance: Sec12, status: TicketStatus.Paid,
                issuedAt: new DateTime(2026, 10, 1, 2, 0, 0, DateTimeKind.Utc), paperReference: "000100", vendorId: 17);

            // The real ticket queries; only adding a ticket and the in-app number need a database.
            var realTickets = new TicketRepository(_context);
            var tickets = ReviewBoundaryProxy.Create<ITicketRepository>((method, args) => method.Name switch
            {
                nameof(ITicketRepository.AddTicketAsync) => Task.FromResult(Save((Ticket)args[0]!)),
                nameof(ITicketRepository.GetNewControlNumber) => Task.FromResult(Tickets.Count + 1),
                _ => method.Invoke(realTickets, args)
            });
            var business = ReviewBoundaryProxy.Create<IVendorRepository>((method, args) =>
                Task.FromResult<VendorTicketSummary?>((int)args[0]! != 17 ? null : new()
                {
                    Id = 17, FirstName = "Juan", LastName = "Reyes", Email = "", BusinessAccountNumber = "MM-17",
                    BusinessName = "Reyes Fresh Fish", MarketSectionId = 1, MarketSectionName = "Fish and Seafood",
                    BusinessAddress = "14 Market Street Santo Nino Marikina", StallNumber = "F-014", Type = BusinessType.Public
                }));
            var sections = ReviewBoundaryProxy.Create<IMarketSectionRepository>((method, args) =>
                Task.FromResult<MarketSection?>((int)args[0]! != ActiveSection ? null
                    : new() { Id = ActiveSection, Name = "Meat and Poultry", Description = "Synthetic" }));
            var unit = ReviewBoundaryProxy.Create<IUnitOfWork>((method, args) =>
            {
                if (method.Name == nameof(IUnitOfWork.CommitAsync))
                {
                    if (CommitError is not null) throw CommitError;
                    Commits++;
                }
                return Done(method);
            });
            var storage = ReviewBoundaryProxy.Create<IStorageService>((method, args) =>
            {
                UploadCalls++;
                if (args[0] is Dictionary<IFormFile, string> files) UploadedFiles += files.Count;
                return Done(method);
            });
            var notifications = ReviewBoundaryProxy.Create<INotificationService>((method, args) => Done(method));
            var compliance = ReviewBoundaryProxy.Create<IVendorComplianceScoreService>((method, args) => Done(method));
            Service = new TicketService(tickets, new OrdinanceRepository(_context), business, unit,
                storage, notifications, compliance, personRepository: new PersonRepository(_context),
                marketSectionRepository: sections);
        }

        public void AddTicket(int id, Ordinance ordinance, TicketStatus status, DateTime issuedAt, string paperReference, int? vendorId)
        {
            var ticket = new Ticket
            {
                Id = id, PersonId = 31, PaperViolatorName = "Juan Cruz", VendorId = vendorId, Type = ViolationType.Ticket,
                Status = status, IssuedAt = issuedAt, PaperReference = paperReference, Description = "Synthetic citation",
                TicketViolations = [new TicketViolation { OrdinanceId = ordinance.Id }]
            };
            Save(ticket);
        }

        // What the phone sends: the details and the photos.
        public CreateTicketRequest Submit() => new()
        {
            VendorId = 17, EnforcerId = 8, Type = ViolationType.Ticket, PersonId = 31, PaperViolatorName = "Juan Cruz",
            PaperReference = "000456", IssuePlace = "Fish aisle near F-014",
            Description = "Market identification card not displayed", PenaltyType = PenaltyType.CashFine,
            Ordinances = [Sec12.Id], PaperTicketPhoto = [Photo("paper.jpg")], SupportingEvidenceFiles = [Photo("stall.jpg")]
        };

        // Stands in for the database insert: the ticket gets the next id and its offense lines are
        // linked to their ordinances, so the next offense count includes it.
        private Ticket Save(Ticket ticket)
        {
            if (ticket.Id == 0) ticket.Id = Tickets.Count == 0 ? 1 : Tickets.Max(t => t.Id) + 1;
            foreach (var line in ticket.TicketViolations)
            {
                var ordinance = new[] { Sec12, Sec13 }.Single(o => o.Id == line.OrdinanceId);
                line.TicketId = ticket.Id;
                line.Ticket = ticket;
                line.Ordinance = ordinance;
                ordinance.TicketViolations.Add(line);
            }
            Tickets.Add(ticket);
            return ticket;
        }

        private static object Done(MethodInfo method) => method.ReturnType.IsGenericType
            ? typeof(Task).GetMethod(nameof(Task.FromResult))!.MakeGenericMethod(method.ReturnType.GetGenericArguments()[0]).Invoke(null, [null])!
            : Task.CompletedTask;

        private static IFormFile Photo(string name) => new FormFile(new MemoryStream([0xff, 0xd8, 0xff, 0xd9]), 0, 4, "photo", name)
            { Headers = new HeaderDictionary(), ContentType = "image/jpeg" };

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
