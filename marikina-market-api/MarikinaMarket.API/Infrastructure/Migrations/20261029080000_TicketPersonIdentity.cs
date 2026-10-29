using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations;

public partial class TicketPersonIdentity : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<int>(name: "person_id", table: "tickets", type: "integer", nullable: true);
        migrationBuilder.AddColumn<string>(name: "paper_violator_name", table: "tickets",
            type: "character varying(200)", maxLength: 200, nullable: true);
        migrationBuilder.CreateIndex(name: "ix_tickets_person_id_issued_at", table: "tickets",
            columns: new[] { "person_id", "issued_at" });
        migrationBuilder.AddForeignKey(name: "fk_tickets_persons_person_id", table: "tickets",
            column: "person_id", principalTable: "persons", principalColumn: "id", onDelete: ReferentialAction.Restrict);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropForeignKey(name: "fk_tickets_persons_person_id", table: "tickets");
        migrationBuilder.DropIndex(name: "ix_tickets_person_id_issued_at", table: "tickets");
        migrationBuilder.DropColumn(name: "paper_violator_name", table: "tickets");
        migrationBuilder.DropColumn(name: "person_id", table: "tickets");
    }
}
