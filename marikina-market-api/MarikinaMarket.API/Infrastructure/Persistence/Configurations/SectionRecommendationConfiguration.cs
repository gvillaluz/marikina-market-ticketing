using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MarikinaMarket.API.Infrastructure.Persistence.Configurations
{
    public class SectionRecommendationConfiguration : IEntityTypeConfiguration<SectionRecommendation>
    {
        public void Configure(EntityTypeBuilder<SectionRecommendation> builder)
        {
            builder.Property(x => x.CategoryCode).HasMaxLength(64);
            builder.Property(x => x.CategoryNameEnglish).HasMaxLength(128);
            builder.Property(x => x.CategoryNameFilipino).HasMaxLength(128);
            builder.Property(x => x.RecommendedAction).HasMaxLength(500);
            builder.Property(x => x.RiskScore).HasPrecision(10, 2);
            builder.Property(x => x.RiskLevel).HasMaxLength(16);
            builder.Property(x => x.PatternConfidence).HasMaxLength(16);
            builder.HasIndex(x => new { x.RecommendationRunId, x.MarketSectionId }).IsUnique();
            builder.HasOne(x => x.RecommendationRun).WithMany(x => x.SectionRecommendations)
                .HasForeignKey(x => x.RecommendationRunId).OnDelete(DeleteBehavior.Cascade);
            builder.HasOne(x => x.MarketSection).WithMany()
                .HasForeignKey(x => x.MarketSectionId).OnDelete(DeleteBehavior.Restrict);
        }
    }
}
