using Google.Apis.Auth.OAuth2;

namespace MarikinaMarket.API.Presentation
{
    public static class FirebaseKey
    {
        public const string SettingName = "Firebase:ServiceAccountJson";

        // The Firebase Admin key (the service-account JSON) comes from one setting: User Secrets on a developer
        // computer, an App Service setting on Azure. No key file is read, so none travels inside the server package.
        public static GoogleCredential Read(IConfiguration configuration)
        {
            var json = configuration[SettingName];
            if (string.IsNullOrWhiteSpace(json))
                throw new InvalidOperationException(
                    $"The setting {SettingName} is missing. Set it to the content of the Firebase Admin service-account JSON.");

            return CredentialFactory.FromJson<ServiceAccountCredential>(json).ToGoogleCredential();
        }
    }
}
