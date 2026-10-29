using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations;

public partial class PaperCitationMetadata : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>(name: "paper_reference", table: "tickets",
            type: "character varying(200)", maxLength: 200, nullable: true, collation: "C");
        migrationBuilder.AddColumn<string>(name: "issue_place", table: "tickets",
            type: "character varying(500)", maxLength: 500, nullable: true);
        migrationBuilder.CreateIndex(name: "ix_tickets_paper_reference", table: "tickets",
            column: "paper_reference", unique: true,
            filter: "\"type\" = 'Ticket' AND paper_reference IS NOT NULL");
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(name: "ix_tickets_paper_reference", table: "tickets");
        migrationBuilder.DropColumn(name: "issue_place", table: "tickets");
        migrationBuilder.DropColumn(name: "paper_reference", table: "tickets");
    }
}
