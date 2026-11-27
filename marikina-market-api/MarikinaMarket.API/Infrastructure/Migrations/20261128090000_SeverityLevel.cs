using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <summary>
    /// Severity Level from the Market Code (ADR 0001, #164): each offence rule records its Additional Penalty
    /// and a ticket saves its Severity Level beside the old highest severity, which stays for now.
    /// </summary>
    public partial class SeverityLevel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "additional_penalty",
                table: "ordinance_penalty_tiers",
                type: "text",
                nullable: false,
                defaultValue: "None");

            migrationBuilder.AddColumn<int>(
                name: "severity_level",
                table: "tickets",
                type: "integer",
                nullable: true);

            migrationBuilder.Sql(SeverityLevelLabelData.BuildLabelSql());
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(name: "severity_level", table: "tickets");
            migrationBuilder.DropColumn(name: "additional_penalty", table: "ordinance_penalty_tiers");
        }
    }
}
