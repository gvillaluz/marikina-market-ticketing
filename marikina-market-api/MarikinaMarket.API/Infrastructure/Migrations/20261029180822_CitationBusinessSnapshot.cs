using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations;

public partial class CitationBusinessSnapshot : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(name: "snapshot_business_account_number", table: "tickets", type: "character varying(20)", maxLength: 20, nullable: true);
        migrationBuilder.AddColumn<string>(name: "snapshot_business_name", table: "tickets", type: "character varying(100)", maxLength: 100, nullable: true);
        migrationBuilder.AddColumn<string>(name: "snapshot_registered_owner_name", table: "tickets", type: "character varying(201)", maxLength: 201, nullable: true);
        migrationBuilder.AddColumn<string>(name: "snapshot_business_type", table: "tickets", type: "text", nullable: true);
        migrationBuilder.AddColumn<string>(name: "snapshot_stall_number", table: "tickets", type: "character varying(20)", maxLength: 20, nullable: true);
        migrationBuilder.AddColumn<string>(name: "snapshot_market_section_name", table: "tickets", type: "character varying(150)", maxLength: 150, nullable: true);
        migrationBuilder.AddColumn<string>(name: "snapshot_business_address", table: "tickets", type: "character varying(266)", maxLength: 266, nullable: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "snapshot_business_account_number", table: "tickets");
        migrationBuilder.DropColumn(name: "snapshot_business_name", table: "tickets");
        migrationBuilder.DropColumn(name: "snapshot_registered_owner_name", table: "tickets");
        migrationBuilder.DropColumn(name: "snapshot_business_type", table: "tickets");
        migrationBuilder.DropColumn(name: "snapshot_stall_number", table: "tickets");
        migrationBuilder.DropColumn(name: "snapshot_market_section_name", table: "tickets");
        migrationBuilder.DropColumn(name: "snapshot_business_address", table: "tickets");
    }
}
