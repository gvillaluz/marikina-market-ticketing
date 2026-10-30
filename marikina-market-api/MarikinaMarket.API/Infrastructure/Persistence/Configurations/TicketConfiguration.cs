using MarikinaMarket.API.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MarikinaMarket.API.Infrastructure.Persistence.Configurations
{
    public class TicketConfiguration : IEntityTypeConfiguration<Ticket>
    {
        public void Configure(EntityTypeBuilder<Ticket> builder)
        {
            builder.Property(x => x.Categories)
                .HasConversion<string>();

            builder.HasIndex(x => new { x.VendorId, x.Categories, x.IssuedAt });
            builder.Property(x => x.PaperViolatorName).HasMaxLength(200);
            builder.Property(x => x.PaperReference).HasMaxLength(200).UseCollation("C");
            builder.Property(x => x.IssuePlace).HasMaxLength(500);
            builder.HasIndex(x => x.PaperReference).IsUnique()
                .HasDatabaseName("ix_tickets_paper_reference")
                .HasFilter("\"type\" = 'Ticket' AND paper_reference IS NOT NULL");
            builder.Property(x => x.SnapshotBusinessAccountNumber).HasMaxLength(20);
            builder.Property(x => x.SnapshotBusinessName).HasMaxLength(100);
            builder.Property(x => x.SnapshotRegisteredOwnerName).HasMaxLength(201);
            builder.Property(x => x.SnapshotBusinessType);
            builder.Property(x => x.SnapshotStallNumber).HasMaxLength(20);
            builder.Property(x => x.SnapshotMarketSectionName).HasMaxLength(150);
            builder.Property(x => x.SnapshotBusinessAddress).HasMaxLength(266);
            builder.HasIndex(x => new { x.PersonId, x.IssuedAt });
            builder.HasOne(x => x.Person).WithMany().HasForeignKey(x => x.PersonId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasIndex(x => x.ControlNumber)
                .IsUnique();

            builder.HasOne(x => x.Vendor)
                .WithMany(t => t.Tickets)
                .HasForeignKey(x => x.VendorId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(x => x.Enforcer)
                .WithMany(t => t.IssuedTickets)
                .HasForeignKey(x => x.EnforcerId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasOne(x => x.MarketSection)
                .WithMany(t => t.Tickets)
                .HasForeignKey(x => x.MarketSectionId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.HasMany(x => x.CommunityServiceLogs)
                .WithOne(x => x.Ticket)
                .HasForeignKey(x => x.TicketId)
                .OnDelete(DeleteBehavior.Restrict);

            builder.Property(x => x.Description)
                .HasMaxLength(1000);

            builder.Property(x => x.TotalPaymentAmount)
                .HasPrecision(18, 2);

            builder.Property(x => x.ProofUrls)
                .HasColumnType("text[]");

            builder.Property(x => x.HighestSeverity)
                .HasConversion<string>();

            builder.Property(t => t.Status)
                .HasConversion<string>();

            builder.Property(t => t.Type)
                .HasConversion<string>();

            builder.Property(t => t.PenaltyType)
                .HasConversion<string>();

            builder.Property(v => v.IssuedAt)
                .HasDefaultValueSql("timezone('utc', now())");

            builder.Property(v => v.Version)
                .IsRowVersion()
                .HasColumnName("xmin")
                .HasColumnType("xid");
        }
    }
}
