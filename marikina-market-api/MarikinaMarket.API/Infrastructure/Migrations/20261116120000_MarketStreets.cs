using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <summary>
    /// Market streets replace market sections. Records are kept and moved to a street;
    /// only the old recommendation records are deleted. Sample data only (user decision, 2026-11-16).
    /// </summary>
    public partial class MarketStreets : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                -- Old recommendation records point to old sections; the model is run again afterwards.
                DELETE FROM recommendation_reviews;
                DELETE FROM section_recommendations;
                DELETE FROM recommendation_findings;
                DELETE FROM recommendation_runs;

                -- A street has no description.
                ALTER TABLE market_sections DROP COLUMN description;

                -- Free every name first, so a street name never clashes with an old one.
                UPDATE market_sections SET name = 'old-' || id;

                -- The streets take ids 1 to 11, reusing the rows that already have those ids.
                INSERT INTO market_sections (id, name, is_active, created_at)
                VALUES
                    (1, 'Shoe Avenue', true, '2024-01-01 00:00:00+00'),
                    (2, 'E. Jacinto Street', true, '2024-01-01 00:00:00+00'),
                    (3, 'E. Dela Paz Street', true, '2024-01-01 00:00:00+00'),
                    (4, 'P. Burgos Street', true, '2024-01-01 00:00:00+00'),
                    (5, 'M. Cruz Street', true, '2024-01-01 00:00:00+00'),
                    (6, 'J. P. Rizal Street', true, '2024-01-01 00:00:00+00'),
                    (7, 'Sumulong Avenue', true, '2024-01-01 00:00:00+00'),
                    (8, 'Villalon Street', true, '2024-01-01 00:00:00+00'),
                    (9, 'P. Paz Street', true, '2024-01-01 00:00:00+00'),
                    (10, 'Kapitan Venciong Street', true, '2024-01-01 00:00:00+00'),
                    (11, 'W. Paz Street', true, '2024-01-01 00:00:00+00')
                ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, is_active = true;

                -- Businesses are spread evenly over the streets, in turn by business id.
                UPDATE businesses business SET market_section_id = spread.street_id
                FROM (SELECT id, (row_number() OVER (ORDER BY id) - 1) % 11 + 1 AS street_id FROM businesses) spread
                WHERE business.id = spread.id;

                -- Tickets and warnings of a business follow the business.
                UPDATE tickets ticket SET market_section_id = business.market_section_id
                FROM businesses business
                WHERE ticket.vendor_id = business.id;

                -- Records of unregistered vendors are spread the same way, in turn by record id.
                UPDATE tickets ticket SET market_section_id = spread.street_id
                FROM (SELECT id, (row_number() OVER (ORDER BY id) - 1) % 11 + 1 AS street_id
                      FROM tickets WHERE vendor_id IS NULL) spread
                WHERE ticket.id = spread.id;

                -- Every saved street name on a record becomes its new street's name.
                UPDATE tickets ticket SET snapshot_market_section_name = street.name
                FROM market_sections street
                WHERE ticket.market_section_id = street.id AND ticket.snapshot_market_section_name IS NOT NULL;

                -- Old registration requests are spread the same way.
                UPDATE vendor_registration_requests request SET market_section_id = spread.street_id
                FROM (SELECT id, (row_number() OVER (ORDER BY id) - 1) % 11 + 1 AS street_id
                      FROM vendor_registration_requests) spread
                WHERE request.id = spread.id;

                -- Remove everything that is not a street. If any record still points to one,
                -- this fails and the whole update is undone.
                DELETE FROM market_sections WHERE id > 11;

                -- Streets the office adds later continue after the highest id ever used.
                DO $$
                DECLARE
                    id_sequence regclass := pg_get_serial_sequence('market_sections', 'id')::regclass;
                BEGIN
                    PERFORM setval(id_sequence,
                        GREATEST((SELECT MAX(id) FROM market_sections), pg_sequence_last_value(id_sequence)));
                END $$;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
            => throw new NotSupportedException("The move to market streets cannot be undone. Restore a user-managed backup instead.");
    }
}
