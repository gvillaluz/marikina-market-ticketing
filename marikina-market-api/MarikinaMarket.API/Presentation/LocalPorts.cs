namespace MarikinaMarket.API.Presentation
{
    public static class LocalPorts
    {
        // On a developer computer the server always listens on 5000 and on 5001 with HTTPS (development certificate),
        // which the phone app and the live checks use. Anywhere else, such as Azure App Service, the host chooses
        // the port and provides HTTPS itself, and there is no development certificate.
        public static void UseLocalPorts(this WebApplicationBuilder builder)
        {
            if (!builder.Environment.IsDevelopment()) return;

            builder.WebHost.ConfigureKestrel(serverOptions =>
            {
                serverOptions.ListenAnyIP(5000);
                serverOptions.ListenAnyIP(5001, listenOptions => listenOptions.UseHttps());
            });
        }
    }
}
