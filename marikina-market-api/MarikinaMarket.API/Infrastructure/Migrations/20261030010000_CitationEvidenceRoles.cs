using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations;

public partial class CitationEvidenceRoles : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(name: "role", table: "ticket_evidences", type: "character varying(20)", maxLength: 20, nullable: true);
        migrationBuilder.AddColumn<int>(name: "sort_order", table: "ticket_evidences", type: "integer", nullable: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "role", table: "ticket_evidences");
        migrationBuilder.DropColumn(name: "sort_order", table: "ticket_evidences");
    }
}
