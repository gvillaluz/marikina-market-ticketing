using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MarikinaMarket.API.Infrastructure.Persistence.Configurations
{
    public class RecommendationReviewConfiguration : IEntityTypeConfiguration<RecommendationReview>
    {
        public void Configure(EntityTypeBuilder<RecommendationReview> builder)
        {
            builder.Property(x => x.CategoryCode).HasMaxLength(64);
            builder.Property(x => x.Decision).HasConversion<string>().HasMaxLength(16);
            builder.Property(x => x.ReviewedByName).HasMaxLength(256);
            builder.HasIndex(x => new { x.MarketSectionId, x.CategoryCode });
            builder.HasOne<MarketSection>().WithMany()
                .HasForeignKey(x => x.MarketSectionId).OnDelete(DeleteBehavior.Restrict);
            builder.HasOne<User>().WithMany()
                .HasForeignKey(x => x.ReviewedById).OnDelete(DeleteBehavior.Restrict);
            builder.HasOne(x => x.RecommendationRun).WithMany()
                .HasForeignKey(x => x.RecommendationRunId).OnDelete(DeleteBehavior.Cascade);
        }
    }
}
