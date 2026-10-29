using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MarikinaMarket.API.Infrastructure.Persistence.Configurations;

public class PersonConfiguration : IEntityTypeConfiguration<Person>
{
    public void Configure(EntityTypeBuilder<Person> builder)
    {
        builder.ToTable("persons");
        builder.Property(p => p.FullName).HasMaxLength(200).IsRequired();
        builder.Property(p => p.Address).HasMaxLength(500).IsRequired();
        builder.Property(p => p.PhoneNumber).HasMaxLength(11);
        builder.Property(p => p.CreatedAt).HasDefaultValueSql("timezone('utc', now())");
    }
}
