using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LittleGod.Api.Migrations
{
    /// <inheritdoc />
    public partial class CharacterIdentityAndDaily : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastDaily",
                table: "RealmCharacter",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Race",
                table: "RealmCharacter",
                type: "text",
                nullable: false,
                defaultValue: "human");

            migrationBuilder.AddColumn<int>(
                name: "RewardDays",
                table: "RealmCharacter",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "StartingStats",
                table: "RealmCharacter",
                type: "text",
                nullable: false,
                defaultValue: "{}");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LastDaily",
                table: "RealmCharacter");

            migrationBuilder.DropColumn(
                name: "Race",
                table: "RealmCharacter");

            migrationBuilder.DropColumn(
                name: "RewardDays",
                table: "RealmCharacter");

            migrationBuilder.DropColumn(
                name: "StartingStats",
                table: "RealmCharacter");
        }
    }
}
