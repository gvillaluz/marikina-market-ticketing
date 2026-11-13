using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RecommendationReviews : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "recommendation_reviews",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    market_section_id = table.Column<int>(type: "integer", nullable: false),
                    category_code = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    decision = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    reviewed_by_id = table.Column<int>(type: "integer", nullable: false),
                    reviewed_by_name = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    reviewed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    recommendation_run_id = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_recommendation_reviews", x => x.id);
                    table.ForeignKey(
                        name: "fk_recommendation_reviews_asp_net_users_reviewed_by_id",
                        column: x => x.reviewed_by_id,
                        principalTable: "AspNetUsers",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_recommendation_reviews_market_sections_market_section_id",
                        column: x => x.market_section_id,
                        principalTable: "market_sections",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_recommendation_reviews_recommendation_runs_recommendation_r",
                        column: x => x.recommendation_run_id,
                        principalTable: "recommendation_runs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_recommendation_reviews_market_section_id_category_code",
                table: "recommendation_reviews",
                columns: new[] { "market_section_id", "category_code" });

            migrationBuilder.CreateIndex(
                name: "ix_recommendation_reviews_recommendation_run_id",
                table: "recommendation_reviews",
                column: "recommendation_run_id");

            migrationBuilder.CreateIndex(
                name: "ix_recommendation_reviews_reviewed_by_id",
                table: "recommendation_reviews",
                column: "reviewed_by_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "recommendation_reviews");
        }
    }
}
