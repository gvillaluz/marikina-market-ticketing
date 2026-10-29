using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations;

public partial class PersonRegistry : Migration
{
    // Source prepared for review only. Schema provisioning is a separate user step.
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "persons",
            columns: table => new
            {
                id = table.Column<int>(type: "integer", nullable: false)
                    .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                full_name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                address = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                phone_number = table.Column<string>(type: "character varying(11)", maxLength: 11, nullable: true),
                created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false,
                    defaultValueSql: "timezone('utc', now())")
            },
            constraints: table => table.PrimaryKey("pk_persons", x => x.id));
    }

    protected override void Down(MigrationBuilder migrationBuilder) => migrationBuilder.DropTable("persons");
}
