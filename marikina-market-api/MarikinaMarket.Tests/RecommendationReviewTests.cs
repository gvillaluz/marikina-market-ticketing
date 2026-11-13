using System.ComponentModel.DataAnnotations;
using System.Net;
using System.Text.Json;
using MarikinaMarket.API.Application;
using MarikinaMarket.API.Application.DTOs.Recommendations.Response;
using MarikinaMarket.API.Application.DTOs.User.Response;
using MarikinaMarket.API.Application.Interfaces.Repositories;
using MarikinaMarket.API.Application.Interfaces.Services;
using MarikinaMarket.API.Application.Services;
using MarikinaMarket.API.Domain.Entities;
using MarikinaMarket.API.Domain.Enums;
using MarikinaMarket.API.Infrastructure.Persistence;
using MarikinaMarket.API.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace MarikinaMarket.Tests;

// Step 4 of Recommended Actions: an administrator marks a card Reviewed or Dismissed.
// Runs are written once a day, so the tests use three or four daily runs, 11 to 14 November 2026.
// Cards are named by id: the first digit is the run, the rest the card (101 = run 1, 102 = run 1, 201 = run 2, ...).
public class RecommendationReviewTests
{
    private static readonly DateTime Run1At = new(2026, 11, 11, 5, 12, 40, DateTimeKind.Utc);
    private static readonly DateTime Run2At = Run1At.AddDays(1);
    private static readonly DateTime Run3At = Run1At.AddDays(2);
    private static readonly DateTime Run4At = Run1At.AddDays(3);

    private const int FishSection = 1;
    private const int DrySection = 2;
    private const string Scales = "weights_and_measures";
    private const string Cleanliness = "cleanliness";

    private const string RefreshMessage = "This recommendation was updated. Refresh the page.";
    private const string DismissedMessage = "This recommendation has already been dismissed.";
    private const string ReviewedMessage = "This recommendation has already been marked as reviewed.";

    // 1. Marking a card reviewed shows who and when.
    // Admin 7 is Juan Dela Cruz. Card 101 becomes Reviewed by him between "before" and "after"; card 102 stays untouched.
    [Fact]
    public async Task Reviewing_a_card_shows_who_and_when()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales), Card(102, DrySection, Cleanliness));
        var service = ServiceFor(store);
        var before = DateTime.UtcNow;

        var result = await service.MarkReviewedAsync(101, 7);
        var after = DateTime.UtcNow;

        Assert.Equal(RecommendationDecision.Reviewed, result.Decision);
        Assert.Equal("Juan Dela Cruz", result.ReviewedByName);
        Assert.InRange(result.ReviewedAt, before, after);
        Assert.Equal(DateTimeKind.Utc, result.ReviewedAt.Kind);

        var page = await service.GetLatestAsync();
        var fish = page.Recommendations.Single(card => card.Id == 101);
        Assert.NotNull(fish.Review);
        Assert.Equal(RecommendationDecision.Reviewed, fish.Review.Decision);
        Assert.Equal("Juan Dela Cruz", fish.Review.ReviewedByName);
        Assert.Equal(result.ReviewedAt, fish.Review.ReviewedAt);
        Assert.Null(page.Recommendations.Single(card => card.Id == 102).Review);

        var saved = Assert.Single(store.Reviews);
        Assert.Equal(FishSection, saved.MarketSectionId);
        Assert.Equal(Scales, saved.CategoryCode);
        Assert.Equal(7, saved.ReviewedById);
        Assert.Equal(1, saved.RecommendationRunId);
    }

    // 2. Dismissing a card shows it as dismissed. Admin 8 is Maria Santos.
    [Fact]
    public async Task Dismissing_a_card_shows_it_as_dismissed()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales), Card(102, DrySection, Cleanliness));
        var service = ServiceFor(store);
        var before = DateTime.UtcNow;

        var result = await service.DismissAsync(102, 8);
        var after = DateTime.UtcNow;

        Assert.Equal(RecommendationDecision.Dismissed, result.Decision);
        Assert.Equal("Maria Santos", result.ReviewedByName);
        Assert.InRange(result.ReviewedAt, before, after);

        var page = await service.GetLatestAsync();
        var dry = page.Recommendations.Single(card => card.Id == 102);
        Assert.NotNull(dry.Review);
        Assert.Equal(RecommendationDecision.Dismissed, dry.Review.Decision);
        Assert.Equal("Maria Santos", dry.Review.ReviewedByName);
        Assert.Equal(result.ReviewedAt, dry.Review.ReviewedAt);
        Assert.Null(page.Recommendations.Single(card => card.Id == 101).Review);

        var saved = Assert.Single(store.Reviews);
        Assert.Equal(DrySection, saved.MarketSectionId);
        Assert.Equal(Cleanliness, saved.CategoryCode);
        Assert.Equal(8, saved.ReviewedById);
    }

    // 3. Carry-over. Fish and Seafood keeps showing the same problem (scales) on the next run: the review is still there.
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task A_decision_carries_over_to_the_next_run_when_section_and_category_continue(bool dismiss)
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);
        var made = dismiss ? await service.DismissAsync(101, 7) : await service.MarkReviewedAsync(101, 7);

        store.AddRun(2, Run2At, Card(201, FishSection, Scales));
        var page = await service.GetLatestAsync();

        var card = Assert.Single(page.Recommendations);
        Assert.Equal(201, card.Id);
        Assert.NotNull(card.Review);
        Assert.Equal(dismiss ? RecommendationDecision.Dismissed : RecommendationDecision.Reviewed, card.Review.Decision);
        Assert.Equal("Juan Dela Cruz", card.Review.ReviewedByName);
        Assert.Equal(made.ReviewedAt, card.Review.ReviewedAt);
    }

    // Chain: reviewed on run 1, run 2 has the card, run 3 (latest) has the card -> still reviewed on run 3.
    [Fact]
    public async Task A_decision_carries_over_through_several_runs_that_all_have_the_card()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);
        var made = await service.MarkReviewedAsync(101, 7);
        store.AddRun(2, Run2At, Card(201, FishSection, Scales));
        store.AddRun(3, Run3At, Card(301, FishSection, Scales));

        var page = await service.GetLatestAsync();

        var card = Assert.Single(page.Recommendations);
        Assert.Equal(301, card.Id);
        Assert.NotNull(card.Review);
        Assert.Equal(RecommendationDecision.Reviewed, card.Review.Decision);
        Assert.Equal(made.ReviewedAt, card.Review.ReviewedAt);
    }

    // If several reviews apply, the newest by ReviewedAt counts, whatever order they were stored in.
    // Reviewed on run 1 (11 Nov 06:12), dismissed on run 2 (12 Nov 06:12): the latest run shows Dismissed.
    [Fact]
    public async Task The_newest_applying_review_counts()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        store.AddRun(2, Run2At, Card(201, FishSection, Scales));
        store.Seed(2, FishSection, Scales, RecommendationDecision.Dismissed, 2, Run2At.AddHours(1), 8, "Maria Santos");
        store.Seed(1, FishSection, Scales, RecommendationDecision.Reviewed, 1, Run1At.AddHours(1), 7, "Juan Dela Cruz");
        var service = ServiceFor(store);

        var page = await service.GetLatestAsync();

        var card = Assert.Single(page.Recommendations);
        Assert.NotNull(card.Review);
        Assert.Equal(RecommendationDecision.Dismissed, card.Review.Decision);
        Assert.Equal("Maria Santos", card.Review.ReviewedByName);
        Assert.Equal(Run2At.AddHours(1), card.Review.ReviewedAt);
    }

    // 4. No carry-over. Run 1: Fish reviewed for scales and Dry Goods reviewed for cleanliness. Run 2 has no card for Fish
    // (only Dry Goods). Run 3 has both again. Fish's chain was broken on run 2, so Fish is new again; Dry Goods had a card
    // on every run, so its review is still there.
    [Fact]
    public async Task A_decision_does_not_carry_over_after_a_run_without_the_card()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales), Card(102, DrySection, Cleanliness));
        var service = ServiceFor(store);
        await service.MarkReviewedAsync(101, 7);
        var dry = await service.MarkReviewedAsync(102, 7);
        store.AddRun(2, Run2At, Card(202, DrySection, Cleanliness));
        store.AddRun(3, Run3At, Card(301, FishSection, Scales), Card(302, DrySection, Cleanliness));

        var page = await service.GetLatestAsync();

        Assert.Null(page.Recommendations.Single(card => card.Id == 301).Review);
        var carried = page.Recommendations.Single(card => card.Id == 302).Review;
        Assert.NotNull(carried);
        Assert.Equal(dry.ReviewedAt, carried.ReviewedAt);
    }

    // Run 1: Fish and Dry Goods both reviewed. Run 2: Fish shows a different problem (cleanliness) while Dry Goods keeps
    // its problem. A different category is a different card, so Fish starts unreviewed; Dry Goods stays reviewed.
    [Fact]
    public async Task A_decision_does_not_carry_over_when_the_category_changes()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales), Card(102, DrySection, Cleanliness));
        var service = ServiceFor(store);
        await service.MarkReviewedAsync(101, 7);
        await service.MarkReviewedAsync(102, 7);
        store.AddRun(2, Run2At, Card(201, FishSection, Cleanliness), Card(202, DrySection, Cleanliness));

        var page = await service.GetLatestAsync();

        var fish = page.Recommendations.Single(card => card.Id == 201);
        Assert.Equal(Cleanliness, fish.CategoryCode);
        Assert.Null(fish.Review);
        Assert.NotNull(page.Recommendations.Single(card => card.Id == 202).Review);
    }

    // After a gap the card is new, so it can be reviewed again, and that new review then carries over.
    // Run 1: reviewed. Run 2: no card. Run 3: card 301 is new, reviewing it is allowed. Run 4 has it: shows run 3's review.
    [Fact]
    public async Task After_a_gap_the_card_can_be_reviewed_again_and_that_review_carries_over()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);
        await service.MarkReviewedAsync(101, 7);
        store.AddRun(2, Run2At, Card(202, DrySection, Cleanliness));
        store.AddRun(3, Run3At, Card(301, FishSection, Scales));
        var second = await service.MarkReviewedAsync(301, 8);
        store.AddRun(4, Run4At, Card(401, FishSection, Scales));

        var page = await service.GetLatestAsync();

        var card = Assert.Single(page.Recommendations);
        Assert.Equal(401, card.Id);
        Assert.NotNull(card.Review);
        Assert.Equal("Maria Santos", card.Review.ReviewedByName);
        Assert.Equal(second.ReviewedAt, card.Review.ReviewedAt);
        Assert.Equal(2, store.Reviews.Count);
    }

    // 5. Refusals. Runs 1 and 2 exist, so run 1's card 101 is out of date.
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task A_card_from_an_older_run_is_refused(bool dismiss)
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        store.AddRun(2, Run2At, Card(201, FishSection, Scales));
        var service = ServiceFor(store);

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => Act(service, 101, dismiss));

        Assert.Equal(RefreshMessage, error.Message);
        Assert.Empty(store.Reviews);
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task A_card_that_does_not_exist_is_refused(bool dismiss)
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);

        var error = await Assert.ThrowsAsync<RecordNotFoundException>(() => Act(service, 999, dismiss));

        Assert.Equal("Recommendation not found.", error.Message);
        Assert.Empty(store.Reviews);
    }

    [Theory]
    [InlineData(0, false)]
    [InlineData(-5, true)]
    public async Task A_card_id_that_is_not_positive_is_refused(int id, bool dismiss)
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);

        var error = await Assert.ThrowsAsync<ValidationException>(() => Act(service, id, dismiss));

        Assert.Equal("Recommendation ID must be greater than zero.", error.Message);
        Assert.Empty(store.Reviews);
    }

    // Once dismissed, both actions are refused with the same message.
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task A_dismissed_card_cannot_be_reviewed_or_dismissed_again(bool dismissAgain)
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);
        await service.DismissAsync(101, 7);

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => Act(service, 101, dismissAgain));

        Assert.Equal(DismissedMessage, error.Message);
        Assert.Single(store.Reviews);
    }

    [Fact]
    public async Task A_reviewed_card_cannot_be_reviewed_again()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);
        await service.MarkReviewedAsync(101, 7);

        var error = await Assert.ThrowsAsync<InvalidRequestException>(() => service.MarkReviewedAsync(101, 8));

        Assert.Equal(ReviewedMessage, error.Message);
        Assert.Single(store.Reviews);
    }

    // Reviewed first, dismissed later: allowed. The card then shows Dismissed by the second person.
    [Fact]
    public async Task A_reviewed_card_can_be_dismissed()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);
        await service.MarkReviewedAsync(101, 7);

        var result = await service.DismissAsync(101, 8);

        Assert.Equal(RecommendationDecision.Dismissed, result.Decision);
        Assert.Equal("Maria Santos", result.ReviewedByName);
        var page = await service.GetLatestAsync();
        var review = Assert.Single(page.Recommendations).Review;
        Assert.NotNull(review);
        Assert.Equal(RecommendationDecision.Dismissed, review.Decision);
        Assert.Equal(2, store.Reviews.Count);
    }

    // The state that counts is the carried-over one: a card dismissed on run 1 cannot be reviewed on run 2,
    // and a card reviewed on run 1 cannot be reviewed again on run 2.
    [Fact]
    public async Task A_carried_over_dismissal_blocks_both_actions_on_the_next_run()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);
        await service.DismissAsync(101, 7);
        store.AddRun(2, Run2At, Card(201, FishSection, Scales));

        var review = await Assert.ThrowsAsync<InvalidRequestException>(() => service.MarkReviewedAsync(201, 7));
        var dismiss = await Assert.ThrowsAsync<InvalidRequestException>(() => service.DismissAsync(201, 7));

        Assert.Equal(DismissedMessage, review.Message);
        Assert.Equal(DismissedMessage, dismiss.Message);
        Assert.Single(store.Reviews);
    }

    [Fact]
    public async Task A_carried_over_review_blocks_a_repeat_review_but_allows_dismissing()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);
        await service.MarkReviewedAsync(101, 7);
        store.AddRun(2, Run2At, Card(201, FishSection, Scales));

        var repeat = await Assert.ThrowsAsync<InvalidRequestException>(() => service.MarkReviewedAsync(201, 7));
        var dismissed = await service.DismissAsync(201, 8);

        Assert.Equal(ReviewedMessage, repeat.Message);
        Assert.Equal(RecommendationDecision.Dismissed, dismissed.Decision);
        var saved = store.Reviews.Last();
        Assert.Equal(2, saved.RecommendationRunId);
    }

    // The person comes from the sign-in. A sign-in with no matching account writes nothing.
    [Fact]
    public async Task An_unknown_administrator_is_refused_and_nothing_is_saved()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var service = ServiceFor(store);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() => service.MarkReviewedAsync(101, 99));

        Assert.Empty(store.Reviews);
    }

    // A saved review is committed; a refused one is rolled back and saves nothing.
    [Fact]
    public async Task A_saved_review_is_committed_and_a_refused_one_is_rolled_back()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        var calls = new List<string>();
        var service = ServiceFor(store, calls);

        await service.MarkReviewedAsync(101, 7);
        Assert.Equal(["BeginTransactionAsync", "SaveChangesAsync", "CommitAsync"], calls);

        calls.Clear();
        await Assert.ThrowsAsync<InvalidRequestException>(() => service.MarkReviewedAsync(101, 7));
        Assert.Equal(["BeginTransactionAsync", "RollbackAsync"], calls);
    }

    // 6. Roles. Routes exist for Head Admin and Admin Officer only; an enforcer or vendor gets 403, no sign-in gets 401.
    [Theory]
    [InlineData(null, "review", 401)]
    [InlineData(null, "dismiss", 401)]
    [InlineData("MarketEnforcer", "review", 403)]
    [InlineData("MarketEnforcer", "dismiss", 403)]
    [InlineData("MarketVendor", "review", 403)]
    [InlineData("HeadAdmin", "review", 200)]
    [InlineData("HeadAdmin", "dismiss", 200)]
    [InlineData("AdminOfficer", "review", 200)]
    [InlineData("AdminOfficer", "dismiss", 200)]
    public async Task Only_head_admin_and_admin_officer_can_review_or_dismiss(string? role, string action, int status)
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        await using var host = await HostFor(store);

        using var response = await host.SendAsync(HttpMethod.Post, $"/api/admin/recommendations/101/{action}", role);

        Assert.Equal(status, (int)response.StatusCode);
        Assert.Equal(status == 200 ? 1 : 0, store.Reviews.Count);
    }

    // 7. Audit. Admin 7 clicks; the entry is under Reports, names admin 7 with the role from the token, and the card id.
    // The body claims admin 8: it must be ignored, both in the log and in the saved review.
    [Theory]
    [InlineData("HeadAdmin", "review", "MarkReviewed", RecommendationDecision.Reviewed)]
    [InlineData("HeadAdmin", "dismiss", "Dismiss", RecommendationDecision.Dismissed)]
    [InlineData("AdminOfficer", "review", "MarkReviewed", RecommendationDecision.Reviewed)]
    [InlineData("AdminOfficer", "dismiss", "Dismiss", RecommendationDecision.Dismissed)]
    public async Task Each_click_writes_an_audit_entry_for_the_person_who_clicked(
        string role, string route, string auditAction, RecommendationDecision decision)
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(301, FishSection, Scales));
        await using var host = await HostFor(store);

        using var response = await host.SendAsync(HttpMethod.Post, $"/api/admin/recommendations/301/{route}", role,
            "{\"user_id\":8,\"reviewed_by_id\":8,\"reviewed_by_name\":\"Someone Else\"}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var log = Assert.Single(host.Repository.Logs);
        Assert.Equal(auditAction, log.Action);
        Assert.Equal(API.Domain.Enums.Module.Reports, log.Module);
        Assert.Equal(7, log.UserId);
        Assert.Equal(Enum.Parse<Role>(role), log.Role);
        Assert.Equal("301", log.TargetId);
        Assert.Equal(LogResult.Success, log.Result);
        var saved = Assert.Single(store.Reviews);
        Assert.Equal(7, saved.ReviewedById);
        Assert.Equal("Juan Dela Cruz", saved.ReviewedByName);
        Assert.Equal(decision, saved.Decision);
    }

    // Contract shape: field names are snake_case and the decision is a word. The list shows the same review object.
    [Fact]
    public async Task The_review_response_and_the_list_use_the_agreed_field_names()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales), Card(102, DrySection, Cleanliness));
        await using var host = await HostFor(store);

        using var posted = await host.SendAsync(HttpMethod.Post, "/api/admin/recommendations/101/review");
        using var postedJson = JsonDocument.Parse(await posted.Content.ReadAsStringAsync());
        using var listed = await host.SendAsync(HttpMethod.Get, "/api/admin/recommendations");
        using var listedJson = JsonDocument.Parse(await listed.Content.ReadAsStringAsync());

        Assert.Equal(HttpStatusCode.OK, posted.StatusCode);
        Assert.Equal(["decision", "reviewed_by_name", "reviewed_at"],
            postedJson.RootElement.EnumerateObject().Select(property => property.Name));
        Assert.Equal("Reviewed", postedJson.RootElement.GetProperty("decision").GetString());
        Assert.Equal("Juan Dela Cruz", postedJson.RootElement.GetProperty("reviewed_by_name").GetString());
        Assert.True(postedJson.RootElement.GetProperty("reviewed_at").TryGetDateTime(out _));

        var cards = listedJson.RootElement.GetProperty("recommendations").EnumerateArray().ToList();
        var fish = cards.Single(card => card.GetProperty("id").GetInt32() == 101);
        var dry = cards.Single(card => card.GetProperty("id").GetInt32() == 102);
        Assert.Equal(postedJson.RootElement.GetRawText(), fish.GetProperty("review").GetRawText());
        Assert.Equal(JsonValueKind.Null, dry.GetProperty("review").ValueKind);
    }

    // Errors come back as { "message": ... } with the agreed status. A refused (400) click changes nothing and is not
    // logged, like every other validation failure; a 404 is logged as a failed attempt by the same person.
    [Fact]
    public async Task Refusals_return_the_agreed_status_and_message()
    {
        var store = new InMemoryRecommendationStore();
        store.AddRun(1, Run1At, Card(101, FishSection, Scales));
        store.AddRun(2, Run2At, Card(201, FishSection, Scales));
        await using var host = await HostFor(store);

        using var older = await host.SendAsync(HttpMethod.Post, "/api/admin/recommendations/101/review");
        var olderMessage = await MessageOf(older);
        Assert.Empty(host.Repository.Logs);
        using var missing = await host.SendAsync(HttpMethod.Post, "/api/admin/recommendations/999/dismiss");
        var missingMessage = await MessageOf(missing);
        using var first = await host.SendAsync(HttpMethod.Post, "/api/admin/recommendations/201/dismiss");
        using var again = await host.SendAsync(HttpMethod.Post, "/api/admin/recommendations/201/review");
        var againMessage = await MessageOf(again);

        Assert.Equal(HttpStatusCode.BadRequest, older.StatusCode);
        Assert.Equal(RefreshMessage, olderMessage);
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);
        Assert.Equal("Recommendation not found.", missingMessage);
        Assert.Equal(HttpStatusCode.OK, first.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, again.StatusCode);
        Assert.Equal(DismissedMessage, againMessage);
        Assert.Equal(["Dismiss", "Dismiss"], host.Repository.Logs.Select(log => log.Action));
        Assert.Equal([LogResult.Failed, LogResult.Success], host.Repository.Logs.Select(log => log.Result));
        Assert.All(host.Repository.Logs, log => Assert.Equal(7, log.UserId));
    }

    // Repository queries. The real expressions run over in-memory tables, as in RecommendationsTests.
    // Runs stored out of order: 12 Nov, 9 Nov, 11 Nov, 10 Nov. Asking for runs finished after 10 Nov 05:12:40 leaves
    // only 11 Nov and 12 Nov (run 2 finished exactly then, so it is not "after"), oldest first: runs 3 then 4.
    [Fact]
    public async Task Repository_returns_runs_finished_after_a_time_oldest_first_with_their_cards()
    {
        using var context = EmptyContext();
        context.RecommendationRuns = new AccountDatabaseSet<RecommendationRun>(
        [
            Run(4, Run1At.AddDays(1), Card(401, FishSection, Scales)),
            Run(1, Run1At.AddDays(-2), Card(101, FishSection, Scales)),
            Run(3, Run1At, Card(301, FishSection, Scales)),
            Run(2, Run1At.AddDays(-1), Card(201, FishSection, Scales))
        ]);

        var runs = await new RecommendationRepository(context).GetRunsFinishedAfterAsync(Run1At.AddDays(-1));

        Assert.Equal([3, 4], runs.Select(run => run.Id));
        Assert.Equal([301, 401], runs.SelectMany(run => run.SectionRecommendations).Select(card => card.Id));
    }

    [Fact]
    public async Task Repository_finds_a_card_by_id_or_returns_null()
    {
        using var context = EmptyContext();
        context.SectionRecommendations = new AccountDatabaseSet<SectionRecommendation>(
            [Card(101, FishSection, Scales), Card(102, DrySection, Cleanliness)]);
        var repository = new RecommendationRepository(context);

        var found = await repository.GetCardAsync(102);

        Assert.NotNull(found);
        Assert.Equal(DrySection, found.MarketSectionId);
        Assert.Null(await repository.GetCardAsync(999));
    }

    [Fact]
    public async Task Repository_returns_every_review()
    {
        using var context = EmptyContext();
        context.RecommendationReviews = new AccountDatabaseSet<RecommendationReview>(
        [
            Review(1, FishSection, Scales, RecommendationDecision.Reviewed, 1, Run1At.AddHours(1)),
            Review(2, DrySection, Cleanliness, RecommendationDecision.Dismissed, 1, Run1At.AddHours(2))
        ]);

        var reviews = await new RecommendationRepository(context).GetReviewsAsync();

        Assert.Equal([1, 2], reviews.Select(review => review.Id).Order());
    }

    [Fact]
    public async Task Repository_adds_a_review_to_its_table()
    {
        using var context = EmptyContext();
        var table = new List<RecommendationReview>();
        context.RecommendationReviews = new RegistrationDbSet<RecommendationReview>(table);
        var review = Review(0, FishSection, Scales, RecommendationDecision.Reviewed, 1, Run1At.AddHours(1));

        await new RecommendationRepository(context).AddReviewAsync(review);

        Assert.Same(review, Assert.Single(table));
    }

    private static Task<AuditHost> HostFor(InMemoryRecommendationStore store) => AuditHost.CreateAsync(services =>
    {
        services.AddSingleton<IRecommendationRepository>(store);
        services.AddSingleton(Sections());
        services.AddSingleton(FakeUnitOfWork([]));
        services.AddScoped<IRecommendationService, RecommendationService>();
    });

    private static async Task<string?> MessageOf(HttpResponseMessage response)
    {
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return json.RootElement.GetProperty("message").GetString();
    }

    private static Task<RecommendationReviewResponse> Act(IRecommendationService service, int id, bool dismiss)
        => dismiss ? service.DismissAsync(id, 7) : service.MarkReviewedAsync(id, 7);

    private static AppDbContext EmptyContext() => new(new DbContextOptionsBuilder<AppDbContext>().Options);

    private static RecommendationService ServiceFor(InMemoryRecommendationStore store, List<string>? unitOfWorkCalls = null)
        => new(store, Sections(), Users(), FakeUnitOfWork(unitOfWorkCalls ?? []));

    private static IMarketSectionRepository Sections()
    {
        var sections = new List<MarketSection>
        {
            new() { Id = FishSection, Name = "Fish and Seafood", Description = "Wet market fish stalls", IsActive = true },
            new() { Id = DrySection, Name = "Dry Goods", Description = "Dry goods stalls", IsActive = true }
        };
        return ReviewBoundaryProxy.Create<IMarketSectionRepository>((method, _) => method.Name switch
        {
            nameof(IMarketSectionRepository.GetAllAsync) => Task.FromResult(sections),
            _ => throw new InvalidOperationException(method.Name)
        });
    }

    // Admin 7 is Juan Dela Cruz and admin 8 is Maria Santos. Any other id has no account.
    private static IUserRepository Users()
        => ReviewBoundaryProxy.Create<IUserRepository>((method, args) => method.Name switch
        {
            nameof(IUserRepository.GetNamesByIdsAsync) => Task.FromResult(
                ((IEnumerable<int>)args[0]!).Distinct()
                    .Where(id => id is 7 or 8)
                    .ToDictionary(id => id, id => id == 7
                        ? new UserNamesResponse { Id = 7, FirstName = "Juan", LastName = "Dela Cruz" }
                        : new UserNamesResponse { Id = 8, FirstName = "Maria", LastName = "Santos" })),
            _ => throw new InvalidOperationException(method.Name)
        });

    private static IUnitOfWork FakeUnitOfWork(List<string> calls)
        => ReviewBoundaryProxy.Create<IUnitOfWork>((method, _) =>
        {
            calls.Add(method.Name);
            return method.Name == nameof(IUnitOfWork.SaveChangesAsync) ? Task.FromResult(1) : Task.CompletedTask;
        });

    private static RecommendationRun Run(int id, DateTime finishedAt, params SectionRecommendation[] cards)
    {
        var run = new RecommendationRun
        {
            Id = id,
            StartedAt = finishedAt.AddMinutes(-1),
            FinishedAt = finishedAt,
            WindowStart = finishedAt.AddDays(-30),
            WindowEnd = finishedAt.AddMinutes(-1),
            ModelVersion = "test-model",
            RecordCount = 21,
            SectionRecommendations = cards.ToList()
        };
        foreach (var card in cards) card.RecommendationRunId = id;
        return run;
    }

    private static SectionRecommendation Card(int id, int marketSectionId, string categoryCode) => new()
    {
        Id = id,
        MarketSectionId = marketSectionId,
        CategoryCode = categoryCode,
        CategoryNameEnglish = categoryCode == Scales ? "Weights and Measures" : "Cleanliness",
        CategoryNameFilipino = categoryCode == Scales ? "Timbang at Sukat" : "Kalinisan",
        RecommendedAction = $"Inspect section {marketSectionId}.",
        CategoryRecordCount = 4,
        SectionRecordCount = 6,
        RiskScore = 3.0m,
        RiskLevel = "Moderate",
        PatternConfidence = "Moderate",
        PeakStartHour = 8,
        HourlyCounts = [0, 0, 0, 0, 0, 0, 0, 0, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        LastFlaggedAt = new DateTime(2026, 11, 10, 0, 15, 0, DateTimeKind.Utc)
    };

    private static RecommendationReview Review(int id, int sectionId, string category,
        RecommendationDecision decision, int runId, DateTime reviewedAt, int adminId = 7, string adminName = "Juan Dela Cruz") => new()
    {
        Id = id,
        MarketSectionId = sectionId,
        CategoryCode = category,
        Decision = decision,
        ReviewedById = adminId,
        ReviewedByName = adminName,
        ReviewedAt = reviewedAt,
        RecommendationRunId = runId
    };

    // A stand-in for the database behind the repository: runs with their cards, and the reviews table.
    private sealed class InMemoryRecommendationStore : IRecommendationRepository
    {
        public List<RecommendationRun> Runs { get; } = [];
        public List<RecommendationReview> Reviews { get; } = [];

        public void AddRun(int id, DateTime finishedAt, params SectionRecommendation[] cards)
            => Runs.Add(Run(id, finishedAt, cards));

        public void Seed(int id, int sectionId, string category, RecommendationDecision decision, int runId,
            DateTime reviewedAt, int adminId, string adminName)
            => Reviews.Add(Review(id, sectionId, category, decision, runId, reviewedAt, adminId, adminName));

        public Task<RecommendationRun?> GetLatestRunAsync()
            => Task.FromResult(Runs.OrderByDescending(run => run.FinishedAt).FirstOrDefault());

        public Task<SectionRecommendation?> GetCardAsync(int id)
            => Task.FromResult(Runs.SelectMany(run => run.SectionRecommendations).FirstOrDefault(card => card.Id == id));

        public Task<List<RecommendationReview>> GetReviewsAsync()
        {
            foreach (var review in Reviews)
                review.RecommendationRun = Runs.Single(run => run.Id == review.RecommendationRunId);
            return Task.FromResult(Reviews.ToList());
        }

        public Task<List<RecommendationRun>> GetRunsFinishedAfterAsync(DateTime finishedAt)
            => Task.FromResult(Runs.Where(run => run.FinishedAt > finishedAt).OrderBy(run => run.FinishedAt).ToList());

        public Task AddReviewAsync(RecommendationReview review)
        {
            review.Id = Reviews.Count + 1;
            Reviews.Add(review);
            return Task.CompletedTask;
        }
    }
}
