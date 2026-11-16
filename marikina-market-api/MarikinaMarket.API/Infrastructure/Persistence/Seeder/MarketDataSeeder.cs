using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace MarikinaMarket.API.Infrastructure.Persistence.Seeder
{
    public static class MarketDataSeeder
    {
        private static readonly string[] MarketStreets =
        [
            "Shoe Avenue",
            "E. Jacinto Street",
            "E. Dela Paz Street",
            "P. Burgos Street",
            "M. Cruz Street",
            "J. P. Rizal Street",
            "Sumulong Avenue",
            "Villalon Street",
            "P. Paz Street",
            "Kapitan Venciong Street",
            "W. Paz Street"
        ];

        public static void Seed(ModelBuilder modelBuilder)
        {
            SeedMarketStreets(modelBuilder);
        }

        private static void SeedMarketStreets(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<MarketSection>().HasData(MarketStreets.Select((name, index) => new MarketSection
            {
                Id = index + 1,
                Name = name,
                CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }));
        }
    }
}
