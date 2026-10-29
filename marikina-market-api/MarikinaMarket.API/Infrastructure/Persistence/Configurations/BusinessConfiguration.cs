using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MarikinaMarket.API.Infrastructure.Persistence.Configurations
{
    public class BusinessConfiguration : IEntityTypeConfiguration<Business>
    {
        public void Configure(EntityTypeBuilder<Business> builder)
        {
            builder.ToTable("businesses");
            builder.Property(v => v.OwnerFirstName).HasMaxLength(100).IsRequired();
            builder.Property(v => v.OwnerLastName).HasMaxLength(100).IsRequired();
            builder.Property(v => v.HouseNumber).HasMaxLength(50).IsRequired();
            builder.Property(v => v.Street).HasMaxLength(50).IsRequired();
            builder.Property(v => v.Barangay).HasMaxLength(60).IsRequired();
            builder.Property(v => v.City).HasMaxLength(100).IsRequired();
            builder.Property(v => v.PhoneNumber).HasMaxLength(20);
            builder.Property(v => v.Email).HasMaxLength(255);
            builder.Property(v => v.StallNumber)
                .HasMaxLength(20);

            builder.Property(v => v.BusinessAccountNumber)
                .HasMaxLength(20)
                .IsRequired();

            builder.HasIndex(v => v.BusinessAccountNumber)
                .IsUnique();
            builder.Property<string>("AccountNumberKey").HasColumnName("account_number_key")
                .HasComputedColumnSql("lower(btrim(\"business_account_number\"))", stored: true);
            builder.HasIndex("AccountNumberKey").IsUnique()
                .HasDatabaseName("ix_businesses_account_number_key");

            builder.HasOne(m => m.MarketSection)
                .WithMany(v => v.Businesses)
                .HasForeignKey(v => v.MarketSectionId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Property(t => t.Type)
                .HasConversion<string>();

            builder.Property(v => v.BusinessName)
                .HasMaxLength(100);

            builder.HasIndex(v => v.QrCodeValue)
                .IsUnique();

            builder.Property(v => v.Status)
                .HasConversion<string>();

            builder.Property(v => v.CreatedAt)
                .HasDefaultValueSql("timezone('utc', now())");

            builder.Property(v => v.ScoreUpdatedAt)
                .HasDefaultValueSql("timezone('utc', now())");
        }
    }
}
