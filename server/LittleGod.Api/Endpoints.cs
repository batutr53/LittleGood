using System.Security.Claims;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
namespace LittleGod.Api;
public static class Endpoints {
static string Me(ClaimsPrincipal u)=>u.FindFirstValue(ClaimTypes.NameIdentifier)!;
public static void MapSocial(this WebApplication app) {
var api=app.MapGroup("/api/v1").RequireAuthorization();
api.MapGet("/me",async(ClaimsPrincipal u,UniverseDb db,SocialService s)=>s.ProfileDto(await db.Profiles.SingleAsync(x=>x.PlayerId==Me(u))));
api.MapPut("/me/profile",async(ProfileEdit r,ClaimsPrincipal u,UniverseDb db,SocialService s)=>{
    if(!Snapshot.Text(r.Name,32,true)||r.Avatar is <0 or >5||!SocialService.Visibility(r.Visibility))return Results.BadRequest(new{error="invalid_profile"});
    var p=await db.Profiles.SingleAsync(x=>x.PlayerId==Me(u));p.Name=r.Name;p.Avatar=r.Avatar;p.Visibility=r.Visibility;await db.SaveChangesAsync();return Results.Ok(s.ProfileDto(p));
}).RequireRateLimiting("write");
api.MapGet("/players/{code}",async(string code,ClaimsPrincipal u,SocialService s)=>await s.ViewProfile(Me(u),code) is {} p?Results.Ok(p):Results.NotFound());
api.MapGet("/friends",async(ClaimsPrincipal u,UniverseDb db,SocialService s,int offset=0)=>{
    if(offset<0||offset>100)return Results.BadRequest();var me=Me(u);
    var rows=await db.Connections.Where(x=>x.Low==me||x.High==me).OrderBy(x=>x.Low).ThenBy(x=>x.High).Skip(offset).Take(20).ToListAsync();
    var list=new List<object>();foreach(var c in rows){var p=await db.Profiles.SingleAsync(x=>x.PlayerId==(c.Low==me?c.High:c.Low));list.Add(new{profile=s.ProfileDto(p),state=c.State,incoming=c.Sender!=me});}
    return Results.Ok(new{version=1,items=list,next=rows.Count==20?offset+20:(int?)null});
});
api.MapPost("/friends/{code}",async(string code,ClaimsPrincipal u,SocialService s)=>await s.Request(Me(u),code)?Results.NoContent():Results.NotFound()).RequireRateLimiting("write");
api.MapPut("/friends/{code}/accept",async(string code,ClaimsPrincipal u,SocialService s)=>await s.Accept(Me(u),code)?Results.NoContent():Results.NotFound()).RequireRateLimiting("write");
api.MapDelete("/friends/{code}",async(string code,ClaimsPrincipal u,SocialService s)=>{await s.Remove(Me(u),code);return Results.NoContent();}).RequireRateLimiting("write");
api.MapPut("/blocks/{code}",async(string code,ClaimsPrincipal u,SocialService s)=>{await s.Remove(Me(u),code,true);return Results.NoContent();}).RequireRateLimiting("write");
api.MapGet("/blocks",async(ClaimsPrincipal u,UniverseDb db)=>Results.Ok(new{items=await db.Blocks.Where(x=>x.Owner==Me(u)).Join(db.Profiles,x=>x.Target,p=>p.PlayerId,(x,p)=>new{code=p.Code,name=p.Name}).Take(100).ToListAsync()}));
api.MapDelete("/blocks/{code}",async(string code,ClaimsPrincipal u,UniverseDb db,SocialService s)=>{var p=await s.ByCode(code);if(p is not null)await db.Blocks.Where(x=>x.Owner==Me(u)&&x.Target==p.PlayerId).ExecuteDeleteAsync();return Results.NoContent();}).RequireRateLimiting("write");
api.MapPut("/planets/showcase",async(Publish r,ClaimsPrincipal u,SocialService s)=>await s.Publish(Me(u),r)?Results.Ok(new{version=1,status="published"}):Results.BadRequest(new{error="invalid_snapshot"})).RequireRateLimiting("write");
api.MapDelete("/planets/showcase",async(ClaimsPrincipal u,UniverseDb db)=>{
    var me=Me(u);await using var tx=await db.Database.BeginTransactionAsync();
    await db.Showcases.Where(x=>x.Owner==me).ExecuteDeleteAsync();await db.Reactions.Where(x=>x.Owner==me).ExecuteDeleteAsync();await tx.CommitAsync();return Results.NoContent();
}).RequireRateLimiting("write");
api.MapGet("/planets/{code}/showcase",async(string code,ClaimsPrincipal u,UniverseDb db,SocialService s)=>{
    var show=await s.ReadShowcase(Me(u),code);if(show is null)return Results.NotFound();
    var v=await db.Versions.SingleAsync(x=>x.Owner==show.Owner&&x.Revision==show.Revision);
    return Results.Ok(new{version=1,revision=v.Revision,updated=show.Updated,hash=v.Hash,snapshot=JsonSerializer.Deserialize<JsonElement>(v.Document)});
});
api.MapPost("/visits/{code}",async(string code,ClaimsPrincipal u,SocialService s)=>await s.ReadShowcase(Me(u),code) is not null?Results.NoContent():Results.NotFound()).RequireRateLimiting("write");
api.MapPut("/reactions/{code}",async(string code,React r,ClaimsPrincipal u,SocialService s)=>await s.Reaction(Me(u),code,r.Kind)?Results.NoContent():Results.NotFound()).RequireRateLimiting("write");
api.MapGet("/discovery",async(ClaimsPrincipal u,UniverseDb db,int offset=0)=>{
    if(offset<0||offset>10000)return Results.BadRequest();var me=Me(u);
    var query=from s in db.Showcases join p in db.Profiles on s.Owner equals p.PlayerId join v in db.Versions on new{s.Owner,s.Revision} equals new{v.Owner,v.Revision}
        where s.Visibility=="public"&&p.Visibility=="public"&&!db.Blocks.Any(x=>(x.Owner==me&&x.Target==s.Owner)||(x.Owner==s.Owner&&x.Target==me))
        orderby v.Score descending,s.Owner
        select new{code=p.Code,name=p.Name,avatar=p.Avatar,revision=s.Revision,updated=s.Updated,score=v.Score,planet=v.Document};
    var rows=await query.Skip(offset).Take(12).ToListAsync();
    return Results.Ok(new{version=1,rule="biome_variety + rare_discoveries*3 + monuments*2",items=rows.Select(x=>new{x.code,x.name,x.avatar,x.revision,x.updated,x.score,planet=JsonSerializer.Deserialize<JsonElement>(x.planet).GetProperty("planet").GetProperty("name").GetString(),preview=JsonSerializer.Deserialize<JsonElement>(x.planet).GetProperty("cells").EnumerateArray().Select(c=>new[]{(int)c.GetProperty("x").GetDouble(),(int)c.GetProperty("y").GetDouble(),(int)c.GetProperty("biome").GetDouble()})}),next=rows.Count==12?offset+12:(int?)null});
});
api.MapGet("/notifications",async(ClaimsPrincipal u,UniverseDb db,long before=long.MaxValue)=>{
    var me=Me(u);var rows=await db.Activities.Where(x=>x.Recipient==me&&x.Id<before).Join(db.Profiles,x=>x.Actor,p=>p.PlayerId,(x,p)=>new{x.Id,x.Kind,x.Read,x.Created,actor=p.Name,code=p.Code}).OrderByDescending(x=>x.Id).Take(20).ToListAsync();
    return Results.Ok(new{version=1,items=rows,next=rows.Count==20?rows[^1].Id:(long?)null});
});
api.MapPut("/notifications/read",async(ClaimsPrincipal u,UniverseDb db)=>{await db.Activities.Where(x=>x.Recipient==Me(u)&&!x.Read).ExecuteUpdateAsync(s=>s.SetProperty(x=>x.Read,true));return Results.NoContent();}).RequireRateLimiting("write");
}
}
