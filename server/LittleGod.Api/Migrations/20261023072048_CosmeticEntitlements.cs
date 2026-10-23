using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LittleGod.Api.Migrations
{
    /// <inheritdoc />
    public partial class CosmeticEntitlements : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PurchaseReceipt",
                columns: table => new
                {
                    Store = table.Column<string>(type: "text", nullable: false),
                    Transaction = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    Owner = table.Column<string>(type: "text", nullable: false),
                    Product = table.Column<string>(type: "text", nullable: false),
                    State = table.Column<string>(type: "text", nullable: false),
                    VerifiedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PurchaseReceipt", x => new { x.Store, x.Transaction });
                    table.CheckConstraint("CK_PurchaseState", "\"State\" IN ('pending','completed','cancelled','failed','revoked')");
                    table.ForeignKey(
                        name: "FK_PurchaseReceipt_AspNetUsers_Owner",
                        column: x => x.Owner,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PurchaseReceipt_Owner_State",
                table: "PurchaseReceipt",
                columns: new[] { "Owner", "State" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PurchaseReceipt");
        }
    }
}
