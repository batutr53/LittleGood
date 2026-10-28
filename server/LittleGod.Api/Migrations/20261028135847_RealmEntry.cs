using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LittleGod.Api.Migrations
{
    /// <inheritdoc />
    public partial class RealmEntry : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RealmCharacter",
                columns: table => new
                {
                    Id = table.Column<string>(type: "text", nullable: false),
                    Owner = table.Column<string>(type: "text", nullable: false),
                    Realm = table.Column<string>(type: "text", nullable: false),
                    Name = table.Column<string>(type: "character varying(24)", maxLength: 24, nullable: false),
                    NameKey = table.Column<string>(type: "character varying(48)", maxLength: 48, nullable: false),
                    PrimaryClass = table.Column<string>(type: "text", nullable: false),
                    Unlocked = table.Column<string>(type: "text", nullable: false),
                    Seed = table.Column<int>(type: "integer", nullable: false),
                    Experience = table.Column<int>(type: "integer", nullable: false),
                    Essence = table.Column<int>(type: "integer", nullable: false),
                    Hunts = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RealmCharacter", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RealmCharacter_AspNetUsers_Owner",
                        column: x => x.Owner,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RealmReward",
                columns: table => new
                {
                    Id = table.Column<string>(type: "text", nullable: false),
                    Created = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RealmReward", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "RealmTicket",
                columns: table => new
                {
                    Hash = table.Column<string>(type: "text", nullable: false),
                    CharacterId = table.Column<string>(type: "text", nullable: false),
                    Expires = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    Used = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RealmTicket", x => x.Hash);
                    table.ForeignKey(
                        name: "FK_RealmTicket_RealmCharacter_CharacterId",
                        column: x => x.CharacterId,
                        principalTable: "RealmCharacter",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RealmCharacter_Owner_Realm",
                table: "RealmCharacter",
                columns: new[] { "Owner", "Realm" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RealmCharacter_Realm_NameKey",
                table: "RealmCharacter",
                columns: new[] { "Realm", "NameKey" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RealmTicket_CharacterId",
                table: "RealmTicket",
                column: "CharacterId");

            migrationBuilder.CreateIndex(
                name: "IX_RealmTicket_Expires",
                table: "RealmTicket",
                column: "Expires");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RealmReward");

            migrationBuilder.DropTable(
                name: "RealmTicket");

            migrationBuilder.DropTable(
                name: "RealmCharacter");
        }
    }
}
