using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace MarikinaMarket.Tests;

public class VendorLoginSnapshotTests
{
    [Fact]
    public async Task Account_snapshot_does_not_attach_an_account_independent_business()
    {
        await using var host = await VendorSelfProfileHost.CreateAsync();
        using var response = await host.Send(HttpMethod.Get, path: "/api/user/me?user_id=88&vendor_id=7");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var snapshot = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.False(snapshot.TryGetProperty("vendor", out var business) && business.ValueKind != JsonValueKind.Null);
    }

    [Fact]
    public async Task Former_vendor_account_cannot_edit_business_through_self_profile()
    {
        await using var host = await VendorSelfProfileHost.CreateAsync();
        using var response = await host.Send(HttpMethod.Put, body: host.Edit());
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        Assert.Equal(0, host.Writes);
    }
}
