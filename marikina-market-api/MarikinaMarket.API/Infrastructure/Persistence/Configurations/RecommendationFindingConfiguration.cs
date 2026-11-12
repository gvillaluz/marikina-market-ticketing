using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MarikinaMarket.API.Infrastructure.Persistence.Configurations
{
    public class RecommendationFindingConfiguration : IEntityTypeConfiguration<RecommendationFinding>
    {
        public void Configure(EntityTypeBuilder<RecommendationFinding> builder)
        {
            builder.HasKey(x => new { x.RecommendationRunId, x.TicketId, x.CategoryCode });
            builder.Property(x => x.CategoryCode).HasMaxLength(64);
            builder.HasOne(x => x.RecommendationRun).WithMany(x => x.Findings)
                .HasForeignKey(x => x.RecommendationRunId).OnDelete(DeleteBehavior.Cascade);
            builder.HasOne(x => x.Ticket).WithMany()
                .HasForeignKey(x => x.TicketId).OnDelete(DeleteBehavior.Cascade);
        }
    }
}
