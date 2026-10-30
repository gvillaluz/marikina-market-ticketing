using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations;

public partial class SettlementSubmissionIdentity : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<Guid>(name: "receipt_submission_id", table: "tickets", type: "uuid", nullable: true);
        migrationBuilder.AddColumn<string>(name: "receipt_submission_hash", table: "tickets", type: "character varying(64)", maxLength: 64, nullable: true);
        migrationBuilder.AddColumn<Guid>(name: "submission_id", table: "community_service_logs", type: "uuid", nullable: true);
        migrationBuilder.AddColumn<string>(name: "submission_hash", table: "community_service_logs", type: "character varying(64)", maxLength: 64, nullable: true);
        migrationBuilder.CreateIndex(name: "ix_community_service_logs_ticket_id_submission_id", table: "community_service_logs", columns: new[] { "ticket_id", "submission_id" }, unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex(name: "ix_community_service_logs_ticket_id_submission_id", table: "community_service_logs");
        migrationBuilder.DropColumn(name: "receipt_submission_id", table: "tickets");
        migrationBuilder.DropColumn(name: "receipt_submission_hash", table: "tickets");
        migrationBuilder.DropColumn(name: "submission_id", table: "community_service_logs");
        migrationBuilder.DropColumn(name: "submission_hash", table: "community_service_logs");
    }
}
