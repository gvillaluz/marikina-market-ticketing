using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class BusinessRecords : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Approved reset, prepared for user review only. Never target operational data.
            migrationBuilder.Sql("""
                DO $$ BEGIN
                    IF current_database() <> 'marikina_market_e2e' THEN
                        RAISE EXCEPTION 'Business-record reset is restricted to the disposable marikina_market_e2e database.';
                    END IF;
                END $$;
                CREATE TEMP TABLE retired_vendor_users ON COMMIT DROP AS
                    SELECT user_id AS id FROM vendor_profiles
                    UNION
                    SELECT membership.user_id FROM "AspNetUserRoles" membership
                    JOIN "AspNetRoles" role ON role.id = membership.role_id
                    WHERE role.name = 'MarketVendor';
                DO $$ BEGIN
                    IF EXISTS (
                        SELECT 1 FROM retired_vendor_users retired
                        JOIN "AspNetUserRoles" membership ON membership.user_id = retired.id
                        JOIN "AspNetRoles" role ON role.id = membership.role_id
                        WHERE role.name <> 'MarketVendor'
                    ) THEN
                        RAISE EXCEPTION 'A selected vendor account also has a staff role. Review the data before resetting.';
                    END IF;
                END $$;
                CREATE TEMP TABLE retired_vendor_tickets ON COMMIT DROP AS
                    SELECT ticket.id FROM tickets ticket
                    JOIN vendor_profiles vendor ON vendor.id = ticket.vendor_id;
                DELETE FROM notifications WHERE vendor_id IN (SELECT id FROM vendor_profiles)
                    OR ticket_id IN (SELECT id FROM retired_vendor_tickets);
                DELETE FROM community_service_logs WHERE ticket_id IN (SELECT id FROM retired_vendor_tickets);
                DELETE FROM ticket_evidences WHERE ticket_id IN (SELECT id FROM retired_vendor_tickets);
                DELETE FROM ticket_violations WHERE ticket_id IN (SELECT id FROM retired_vendor_tickets);
                DELETE FROM tickets WHERE id IN (SELECT id FROM retired_vendor_tickets);
                DELETE FROM vendor_profiles;
                DELETE FROM refresh_tokens WHERE user_id IN (SELECT id FROM retired_vendor_users);
                DELETE FROM user_device_tokens WHERE user_id IN (SELECT id FROM retired_vendor_users);
                DELETE FROM otp_verifications WHERE user_id IN (SELECT id FROM retired_vendor_users);
                DELETE FROM "AspNetUserTokens" WHERE user_id IN (SELECT id FROM retired_vendor_users);
                DELETE FROM "AspNetUserLogins" WHERE user_id IN (SELECT id FROM retired_vendor_users);
                DELETE FROM "AspNetUserClaims" WHERE user_id IN (SELECT id FROM retired_vendor_users);
                DELETE FROM "AspNetUserRoles" WHERE user_id IN (SELECT id FROM retired_vendor_users);
                DELETE FROM "AspNetUsers" WHERE id IN (SELECT id FROM retired_vendor_users);
                """);
            migrationBuilder.DropForeignKey(
                name: "fk_notifications_vendor_profiles_vendor_id",
                table: "notifications");

            migrationBuilder.DropForeignKey(
                name: "fk_tickets_vendor_profiles_vendor_id",
                table: "tickets");

            migrationBuilder.DropTable(
                name: "vendor_profiles");

            migrationBuilder.RenameColumn(
                name: "business_id",
                table: "vendor_registration_requests",
                newName: "business_account_number");

            migrationBuilder.RenameIndex(
                name: "ix_vendor_registration_requests_business_id",
                table: "vendor_registration_requests",
                newName: "ix_vendor_registration_requests_business_account_number");

            migrationBuilder.CreateTable(
                name: "businesses",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    owner_first_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    owner_last_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    house_number = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    street = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    barangay = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    city = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    phone_number = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    market_section_id = table.Column<int>(type: "integer", nullable: false),
                    type = table.Column<string>(type: "text", nullable: false),
                    business_account_number = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    business_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    stall_number = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    compliance_score = table.Column<int>(type: "integer", nullable: false),
                    score_updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    qr_code_value = table.Column<string>(type: "text", nullable: false),
                    status = table.Column<string>(type: "text", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    account_number_key = table.Column<string>(type: "text", nullable: true, computedColumnSql: "lower(btrim(\"business_account_number\"))", stored: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_businesses", x => x.id);
                    table.ForeignKey(
                        name: "fk_businesses_market_sections_market_section_id",
                        column: x => x.market_section_id,
                        principalTable: "market_sections",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_businesses_account_number_key",
                table: "businesses",
                column: "account_number_key",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_businesses_business_account_number",
                table: "businesses",
                column: "business_account_number",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_businesses_market_section_id",
                table: "businesses",
                column: "market_section_id");

            migrationBuilder.CreateIndex(
                name: "ix_businesses_qr_code_value",
                table: "businesses",
                column: "qr_code_value",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "fk_notifications_businesses_vendor_id",
                table: "notifications",
                column: "vendor_id",
                principalTable: "businesses",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "fk_tickets_businesses_vendor_id",
                table: "tickets",
                column: "vendor_id",
                principalTable: "businesses",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
            => throw new NotSupportedException("The approved vendor-data reset cannot be undone. Restore a user-managed backup instead.");
    }
}
