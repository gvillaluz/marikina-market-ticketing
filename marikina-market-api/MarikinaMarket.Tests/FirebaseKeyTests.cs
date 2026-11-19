using System.Security.Cryptography;
using System.Text.Json;
using Google.Apis.Auth.OAuth2;
using MarikinaMarket.API.Presentation;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace MarikinaMarket.Tests;

public class FirebaseKeyTests
{
    // The Firebase Admin key is read from one setting (User Secrets on a developer computer, an App Service setting
    // on Azure), so the key file never has to travel inside the server package.
    [Fact]
    public void The_key_is_read_from_the_setting()
    {
        var configuration = Settings(ServiceAccountJson("firebase-adminsdk-test@marikina-market-test.iam.gserviceaccount.com"));

        var credential = FirebaseKey.Read(configuration);

        var serviceAccount = Assert.IsType<ServiceAccountCredential>(credential.UnderlyingCredential);
        Assert.Equal("firebase-adminsdk-test@marikina-market-test.iam.gserviceaccount.com", serviceAccount.Id);
        Assert.Equal("marikina-market-test", serviceAccount.ProjectId);
    }

    // Without the setting the server must stop at start-up with a message naming the setting, not with a
    // confusing error later or a silent start without push notifications.
    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void A_missing_setting_stops_start_up_with_its_name(string? value)
    {
        var configuration = Settings(value);

        var error = Assert.Throws<InvalidOperationException>(() => FirebaseKey.Read(configuration));

        Assert.Contains("Firebase:ServiceAccountJson", error.Message);
    }

    private static IConfiguration Settings(string? value) =>
        new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?> { ["Firebase:ServiceAccountJson"] = value })
            .Build();

    // The same fields as a key downloaded from Firebase (Project settings → Service accounts), with a private key
    // made for this test only.
    private static string ServiceAccountJson(string clientEmail)
    {
        using var rsa = RSA.Create(2048);
        return JsonSerializer.Serialize(new Dictionary<string, string>
        {
            ["type"] = "service_account",
            ["project_id"] = "marikina-market-test",
            ["private_key_id"] = "0123456789abcdef0123456789abcdef01234567",
            ["private_key"] = rsa.ExportPkcs8PrivateKeyPem() + "\n",
            ["client_email"] = clientEmail,
            ["client_id"] = "100000000000000000001",
            ["auth_uri"] = "https://accounts.google.com/o/oauth2/auth",
            ["token_uri"] = "https://oauth2.googleapis.com/token",
            ["auth_provider_x509_cert_url"] = "https://www.googleapis.com/oauth2/v1/certs",
            ["client_x509_cert_url"] = "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-test%40marikina-market-test.iam.gserviceaccount.com",
            ["universe_domain"] = "googleapis.com",
        });
    }
}
