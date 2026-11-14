namespace MarikinaMarket.API.Presentation
{
    public static class WebsiteFallback
    {
        // The website is served from this server's wwwroot. Page addresses outside /api that are not files
        // load the website's start page, so refreshing any website page works.
        public static void MapWebsiteFallback(this IEndpointRouteBuilder endpoints)
        {
            endpoints.MapFallbackToFile("/", "index.html");
            endpoints.MapFallbackToFile("{*path:regex(^(?!api(/|$))):nonfile}", "index.html");
        }
    }
}
