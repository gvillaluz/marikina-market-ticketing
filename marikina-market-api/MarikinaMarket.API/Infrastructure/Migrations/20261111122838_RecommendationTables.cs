using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RecommendationTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "recommendation_runs",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    started_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    finished_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    window_start = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    window_end = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    model_version = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    record_count = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_recommendation_runs", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "recommendation_findings",
                columns: table => new
                {
                    recommendation_run_id = table.Column<int>(type: "integer", nullable: false),
                    ticket_id = table.Column<int>(type: "integer", nullable: false),
                    category_code = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_recommendation_findings", x => new { x.recommendation_run_id, x.ticket_id, x.category_code });
                    table.ForeignKey(
                        name: "fk_recommendation_findings_recommendation_runs_recommendation_",
                        column: x => x.recommendation_run_id,
                        principalTable: "recommendation_runs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_recommendation_findings_tickets_ticket_id",
                        column: x => x.ticket_id,
                        principalTable: "tickets",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "section_recommendations",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    recommendation_run_id = table.Column<int>(type: "integer", nullable: false),
                    market_section_id = table.Column<int>(type: "integer", nullable: false),
                    category_code = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    category_name_english = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    category_name_filipino = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
                    recommended_action = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    category_record_count = table.Column<int>(type: "integer", nullable: false),
                    section_record_count = table.Column<int>(type: "integer", nullable: false),
                    risk_score = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    risk_level = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    pattern_confidence = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    peak_start_hour = table.Column<int>(type: "integer", nullable: false),
                    hourly_counts = table.Column<List<int>>(type: "integer[]", nullable: false),
                    last_flagged_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_section_recommendations", x => x.id);
                    table.ForeignKey(
                        name: "fk_section_recommendations_market_sections_market_section_id",
                        column: x => x.market_section_id,
                        principalTable: "market_sections",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_section_recommendations_recommendation_runs_recommendation_",
                        column: x => x.recommendation_run_id,
                        principalTable: "recommendation_runs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_recommendation_findings_ticket_id",
                table: "recommendation_findings",
                column: "ticket_id");

            migrationBuilder.CreateIndex(
                name: "ix_recommendation_runs_finished_at",
                table: "recommendation_runs",
                column: "finished_at");

            migrationBuilder.CreateIndex(
                name: "ix_section_recommendations_market_section_id",
                table: "section_recommendations",
                column: "market_section_id");

            migrationBuilder.CreateIndex(
                name: "ix_section_recommendations_recommendation_run_id_market_sectio",
                table: "section_recommendations",
                columns: new[] { "recommendation_run_id", "market_section_id" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "recommendation_findings");

            migrationBuilder.DropTable(
                name: "section_recommendations");

            migrationBuilder.DropTable(
                name: "recommendation_runs");
        }
    }
}
