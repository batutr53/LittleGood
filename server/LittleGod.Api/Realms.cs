using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;

namespace LittleGod.Api;

public sealed class RealmCharacter {
    public string Id { get; set; } = Guid.NewGuid().ToString("N");
    public string Owner { get; set; } = "";
    public Player Player { get; set; } = null!;
    public string Realm { get; set; } = "hearth";
    public string Name { get; set; } = "";
    public string NameKey { get; set; } = "";
    public string PrimaryClass { get; set; } = "warrior";
    public string Unlocked { get; set; } = "[]";
    public int Seed { get; set; }
    public int Experience { get; set; }
    public int Essence { get; set; }
    public int Hunts { get; set; }
}
public sealed class RealmTicket {
    public string Hash { get; set; } = "";
    public string CharacterId { get; set; } = "";
    public RealmCharacter Character { get; set; } = null!;
    public DateTimeOffset Expires { get; set; }
    public bool Used { get; set; }
}
public record CreateCharacter(string Name, string Class);
public record RecruitClass(string Class);
public sealed class RealmReward {public string Id {get;set;}="";public DateTimeOffset Created {get;set;}=DateTimeOffset.UtcNow;}
public static partial class Realms {
    public static readonly string[] Classes = ["warrior","priest","mage","rogue"];
    [GeneratedRegex("^[\\p{L}][\\p{L}\\p{Nd} _-]{1,22}[\\p{L}\\p{Nd}]$")]
    private static partial Regex NamePattern();
    public static bool ValidName(string? name) => name is not null && name==name.Trim() && NamePattern().IsMatch(name);
    public static string TicketHash(string ticket) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(ticket)));
    public static object Dto(RealmCharacter c) => new {id=c.Id,realm=c.Realm,name=c.Name,primaryClass=c.PrimaryClass,unlocked=System.Text.Json.JsonSerializer.Deserialize<string[]>(c.Unlocked),seed=c.Seed,experience=c.Experience,essence=c.Essence,hunts=c.Hunts};
    public static void MapRealms(this WebApplication app) {
        var api=app.MapGroup("/api/v1").RequireAuthorization();
        api.MapGet("/realms",(WorldHub hub)=>Results.Ok(new {items=new[]{new{id="hearth",name="Hearth · İlk Krallık",status="online",players=hub.Count,capacity=WorldHub.Capacity,region="beta",rules="cooperative"}}}));
        api.MapGet("/realms/{realm}/characters",async(string realm,ClaimsPrincipal user,UniverseDb db)=>{
            if(realm!="hearth")return Results.NotFound();
            var owner=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            return Results.Ok(new{items=(await db.Set<RealmCharacter>().Where(c=>c.Owner==owner&&c.Realm==realm).ToListAsync()).Select(Dto)});
        });
        api.MapPost("/realms/{realm}/characters",async(string realm,CreateCharacter body,ClaimsPrincipal user,UniverseDb db)=>{
            if(realm!="hearth"||!ValidName(body.Name)||!Classes.Contains(body.Class))return Results.BadRequest(new{error="invalid_character"});
            var owner=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            if(await db.Set<RealmCharacter>().AnyAsync(c=>c.Owner==owner&&c.Realm==realm))return Results.Conflict(new{error="character_exists"});
            var c=new RealmCharacter{Owner=owner,Realm=realm,Name=body.Name,NameKey=body.Name.ToUpperInvariant(),PrimaryClass=body.Class,Unlocked=System.Text.Json.JsonSerializer.Serialize(new[]{body.Class}),Seed=RandomNumberGenerator.GetInt32(1,int.MaxValue)};
            db.Add(c);await db.SaveChangesAsync();return Results.Ok(Dto(c));
        }).RequireRateLimiting("write");
        api.MapPost("/realms/{realm}/characters/{id}/enter",async(string realm,string id,ClaimsPrincipal user,UniverseDb db,WorldHub hub)=>{
            var owner=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var c=await db.Set<RealmCharacter>().SingleOrDefaultAsync(c=>c.Id==id&&c.Owner==owner&&c.Realm==realm);
            if(c is null)return Results.NotFound();
            if(hub.Count>=WorldHub.Capacity)return Results.StatusCode(503);
            var ticket=Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
            db.Add(new RealmTicket{Hash=TicketHash(ticket),CharacterId=id,Expires=DateTimeOffset.UtcNow.AddSeconds(90)});await db.SaveChangesAsync();
            // Tickets are one-use and short-lived; no credentials appear in WebSocket URLs.
            return Results.Ok(new{ticket,expiresIn=90,character=Dto(c)});
        }).RequireRateLimiting("write");
        api.MapPost("/realms/{realm}/characters/{id}/recruit",async(string realm,string id,RecruitClass body,ClaimsPrincipal user,UniverseDb db,WorldHub hub)=>{
            if(!Classes.Contains(body.Class))return Results.BadRequest();
            var owner=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            await using var tx=await db.Database.BeginTransactionAsync();
            await db.Database.ExecuteSqlInterpolatedAsync($"SELECT pg_advisory_xact_lock(hashtext({owner}))");
            if(hub.Contains(id))return Results.Conflict(new{error="leave_hunt_first"});
            await db.Database.ExecuteSqlInterpolatedAsync($"SELECT 1 FROM \"RealmCharacter\" WHERE \"Id\"={id} FOR UPDATE");
            var c=await db.Set<RealmCharacter>().SingleOrDefaultAsync(c=>c.Id==id&&c.Owner==owner&&c.Realm==realm);
            if(c is null)return Results.NotFound();
            var unlocked=System.Text.Json.JsonSerializer.Deserialize<List<string>>(c.Unlocked)!;
            if(unlocked.Contains(body.Class))return Results.Ok(Dto(c));
            if(c.Hunts<3||c.Essence<3)return Results.Conflict(new{error="requires_three_hunts_and_three_essence"});
            c.Essence-=3;unlocked.Add(body.Class);c.Unlocked=System.Text.Json.JsonSerializer.Serialize(unlocked);await db.SaveChangesAsync();await tx.CommitAsync();return Results.Ok(Dto(c));
        }).RequireRateLimiting("write");
        api.MapPost("/realms/{realm}/characters/{id}/select-class",async(string realm,string id,RecruitClass body,ClaimsPrincipal user,UniverseDb db,WorldHub hub)=>{
            var owner=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var c=await db.Set<RealmCharacter>().SingleOrDefaultAsync(c=>c.Id==id&&c.Owner==owner&&c.Realm==realm);if(c is null)return Results.NotFound();
            if(hub.Contains(id)||!Classes.Contains(body.Class)||!System.Text.Json.JsonSerializer.Deserialize<string[]>(c.Unlocked)!.Contains(body.Class))return Results.Conflict();
            c.PrimaryClass=body.Class;await db.SaveChangesAsync();return Results.Ok(Dto(c));
        }).RequireRateLimiting("write");
    }
}
