using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class OrdinancePenaltyRules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "severity",
                table: "ordinances",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "warning_eligible",
                table: "ordinances",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<string>(
                name: "severity",
                table: "ordinance_penalty_tiers",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<decimal>(
                name: "penalty_amount",
                table: "ordinance_penalty_tiers",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(18,2)",
                oldPrecision: 18,
                oldScale: 2);

            migrationBuilder.AddColumn<bool>(
                name: "allow_blood_donation",
                table: "ordinance_penalty_tiers",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "allow_community_service",
                table: "ordinance_penalty_tiers",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "fine_kind",
                table: "ordinance_penalty_tiers",
                type: "text",
                nullable: false,
                defaultValue: "Fixed");

            migrationBuilder.AddColumn<decimal>(
                name: "maximum_fine",
                table: "ordinance_penalty_tiers",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "penalty_terms",
                table: "ordinance_penalty_tiers",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            // Normalize the old accepted base-offense alias without replacing IDs or fines.
            // If both aliases exist, the explicit first-offense tier remains authoritative.
            migrationBuilder.Sql("""
                UPDATE ordinance_penalty_tiers AS legacy
                SET offense_number = 1
                WHERE legacy.offense_number = 0
                    AND NOT EXISTS (
                        SELECT 1 FROM ordinance_penalty_tiers AS explicit_first
                        WHERE explicit_first.ordinance_id = legacy.ordinance_id
                            AND explicit_first.offense_number = 1);

                UPDATE ordinances AS ordinance
                SET severity = first_tier.severity,
                    warning_eligible = first_tier.severity = 'Minor'
                FROM (
                    SELECT DISTINCT ON (ordinance_id) ordinance_id, severity
                    FROM ordinance_penalty_tiers
                    WHERE offense_number IN (1, 0)
                    ORDER BY ordinance_id, CASE WHEN offense_number = 1 THEN 0 ELSE 1 END
                ) AS first_tier
                WHERE ordinance.id = first_tier.ordinance_id;

                UPDATE ordinance_penalty_tiers
                SET fine_kind = 'Fixed',
                    allow_blood_donation = offense_number = 1 AND severity IN ('Minor', 'Moderate'),
                    allow_community_service = offense_number = 1 AND severity IN ('Minor', 'Moderate');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Refuse to erase new rules or replace missing historic classifications with guesses.
            // The original tier severity column is retained as recovery-only data by Up.
            migrationBuilder.Sql("""
                DO $$
                BEGIN
                    IF EXISTS (SELECT 1 FROM ordinance_penalty_tiers
                        WHERE fine_kind <> 'Fixed' OR penalty_amount IS NULL
                            OR maximum_fine IS NOT NULL OR penalty_terms IS NOT NULL OR severity IS NULL
                            OR allow_blood_donation IS DISTINCT FROM (offense_number = 1 AND severity IN ('Minor', 'Moderate'))
                            OR allow_community_service IS DISTINCT FROM (offense_number = 1 AND severity IN ('Minor', 'Moderate')))
                        OR EXISTS (
                            SELECT 1 FROM ordinances AS ordinance
                            LEFT JOIN LATERAL (
                                SELECT severity FROM ordinance_penalty_tiers
                                WHERE ordinance_id = ordinance.id AND offense_number IN (1, 0)
                                ORDER BY CASE WHEN offense_number = 1 THEN 0 ELSE 1 END LIMIT 1
                            ) AS first_tier ON true
                            WHERE ordinance.severity IS DISTINCT FROM first_tier.severity
                                OR ordinance.warning_eligible IS DISTINCT FROM COALESCE(first_tier.severity = 'Minor', false)) THEN
                        RAISE EXCEPTION 'Rollback blocked: penalty rules or scoring settings require a reviewed recovery plan.';
                    END IF;
                END $$;
                """);
            migrationBuilder.DropColumn(
                name: "severity",
                table: "ordinances");

            migrationBuilder.DropColumn(
                name: "warning_eligible",
                table: "ordinances");

            migrationBuilder.DropColumn(
                name: "allow_blood_donation",
                table: "ordinance_penalty_tiers");

            migrationBuilder.DropColumn(
                name: "allow_community_service",
                table: "ordinance_penalty_tiers");

            migrationBuilder.DropColumn(
                name: "fine_kind",
                table: "ordinance_penalty_tiers");

            migrationBuilder.DropColumn(
                name: "maximum_fine",
                table: "ordinance_penalty_tiers");

            migrationBuilder.DropColumn(
                name: "penalty_terms",
                table: "ordinance_penalty_tiers");

            migrationBuilder.AlterColumn<string>(
                name: "severity",
                table: "ordinance_penalty_tiers",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "penalty_amount",
                table: "ordinance_penalty_tiers",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(18,2)",
                oldPrecision: 18,
                oldScale: 2,
                oldNullable: true);
        }
    }
}
