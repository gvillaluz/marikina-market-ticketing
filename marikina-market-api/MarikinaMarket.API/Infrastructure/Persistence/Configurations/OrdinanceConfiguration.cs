using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MarikinaMarket.API.Infrastructure.Persistence.Configurations
{
    public class OrdinanceConfiguration : IEntityTypeConfiguration<Ordinance>
    {
        public void Configure(EntityTypeBuilder<Ordinance> builder)
        {
            builder.Property(x => x.OrdinanceNo)
                .HasMaxLength(100);

            builder.Property(x => x.Series)
                .IsRequired();

            builder.Property(x => x.Section)
                .HasColumnName("section")
                .HasMaxLength(100);

            // Preserve unknown legacy codes for recovery; they are not section numbers.
            builder.Property<string>("LegacyMarketCode")
                .HasColumnName("market_code");

            builder.Property(x => x.SpecificCategory)
                .HasMaxLength(100);

            builder.HasIndex(x => x.OrdinanceNo);

            builder.Property(x => x.Title)
                .HasMaxLength(250);

            builder.Property(x => x.Category)
                .HasConversion<string>();
            builder.Property(x => x.Severity).HasConversion<string>();

            builder.Property(x => x.CreatedAt)
                .HasDefaultValueSql("timezone('utc', now())");
            
            builder.Property(x => x.UpdatedAt)
                .HasDefaultValueSql("timezone('utc', now())");

            builder.Property(x => x.IsActive)
                .HasDefaultValue(true);
        }
    }
}
