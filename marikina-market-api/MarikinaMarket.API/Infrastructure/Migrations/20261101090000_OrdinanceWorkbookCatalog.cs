using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class OrdinanceWorkbookCatalog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Data only: updates legacy IDs 2-21 in place, retires ID 1 and adds the remaining
            // Ordinance 011 (2014) workbook sections. New rows stay unconfigured (no severity,
            // not warning-eligible) until an administrator sets them.
            migrationBuilder.Sql(OrdinanceWorkbookCatalogData.BuildUpSql());
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // The replaced legacy titles/tiers are not reconstructed by guesswork; restore the pre-apply backup.
            migrationBuilder.Sql("""
                DO $$
                BEGIN
                    RAISE EXCEPTION 'Rollback blocked: the workbook catalog migration is data-only and irreversible; restore the pre-apply backup.';
                END $$;
                """);
        }
    }
}
