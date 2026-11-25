namespace MarikinaMarket.API.Presentation
{
    public static class WebsiteCors
    {
        public const string PolicyName = "ConfiguredOrigins";

        // The website runs on its own address. Only the addresses in Cors:AllowedOrigins may read this server's
        // answers, and only they may send the website's sign-in cookie with their requests.
        public static IServiceCollection AddWebsiteCors(this IServiceCollection services, IConfiguration configuration)
        {
            var allowedOrigins = configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
            return services.AddCors(options => options.AddPolicy(PolicyName, policy =>
                policy.WithOrigins(allowedOrigins)
                    .AllowAnyHeader()
                    .AllowAnyMethod()
                    .AllowCredentials()
                    // Lets the website read the backup file name the server sends with a download.
                    .WithExposedHeaders("Content-Disposition")));
        }
    }
}
