using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class OrdinanceSectionAndSpecificCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Retain legacy codes without guessing section numbers or rewriting ticket links.
            migrationBuilder.AlterColumn<string>(
                name: "market_code",
                table: "ordinances",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<string>(
                name: "section",
                table: "ordinances",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "specific_category",
                table: "ordinances",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // A rollback must not silently erase newly entered identities/categories.
            migrationBuilder.Sql("""
                DO $$
                BEGIN
                    IF EXISTS (SELECT 1 FROM ordinances
                        WHERE section IS NOT NULL OR specific_category IS NOT NULL
                            OR market_code IS NULL
                            OR category IN ('DressCode', 'IllegalVendor', 'NonSmoking', 'Others')) THEN
                        RAISE EXCEPTION 'Rollback blocked: ordinance section/category data requires a reviewed recovery plan.';
                    END IF;
                END $$;
                """);
            migrationBuilder.DropColumn(
                name: "section",
                table: "ordinances");

            migrationBuilder.DropColumn(
                name: "specific_category",
                table: "ordinances");

            migrationBuilder.AlterColumn<string>(
                name: "market_code",
                table: "ordinances",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);
        }
    }
}
