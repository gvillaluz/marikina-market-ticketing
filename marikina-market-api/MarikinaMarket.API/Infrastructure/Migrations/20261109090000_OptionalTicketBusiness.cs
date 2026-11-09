using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarikinaMarket.API.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class OptionalTicketBusiness : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // An unregistered vendor's ticket or warning has no business. Existing rows keep theirs.
            migrationBuilder.AlterColumn<int>(
                name: "vendor_id",
                table: "tickets",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Fails by design while any ticket or warning has no business: those rows cannot be given one by guesswork.
            migrationBuilder.AlterColumn<int>(
                name: "vendor_id",
                table: "tickets",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);
        }
    }
}
