using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MarikinaMarket.API.Infrastructure.Persistence.Configurations
{
    public class RecommendationRunConfiguration : IEntityTypeConfiguration<RecommendationRun>
    {
        public void Configure(EntityTypeBuilder<RecommendationRun> builder)
        {
            builder.Property(x => x.ModelVersion).HasMaxLength(64);
            builder.HasIndex(x => x.FinishedAt);
        }
    }
}
