using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
namespace LittleGod.Api;
public record ProfileEdit(string Name,int Avatar,string Visibility);
public record Publish(JsonElement Snapshot,string Visibility);
public record React(int Kind);
public sealed class SocialService(UniverseDb db) {
    public static bool Visibility(string v)=>v is "private" or "friends" or "public";
    public async Task<bool> Blocked(string a,string b)=>await db.Blocks.AnyAsync(x=>(x.Owner==a&&x.Target==b)||(x.Owner==b&&x.Target==a));
    public async Task<bool> Friends(string a,string b)=>await db.Connections.AnyAsync(x=>x.State=="accepted"&&((x.Low==a&&x.High==b)||(x.Low==b&&x.High==a)));
    public async Task<bool> Allowed(string viewer,string owner,string visibility)=>viewer==owner||(!await Blocked(viewer,owner)&&(visibility=="public"||(visibility=="friends"&&await Friends(viewer,owner))));
    public async Task<Profile?> ByCode(string code)=>code.Length==32?await db.Profiles.SingleOrDefaultAsync(x=>x.Code==code):null;
    public object ProfileDto(Profile p)=>new{code=p.Code,name=p.Name,avatar=p.Avatar,visibility=p.Visibility};
    public async Task<object?> ViewProfile(string viewer,string code) {
        var p=await ByCode(code);if(p is null||!await Allowed(viewer,p.PlayerId,p.Visibility))return null;
        return ProfileDto(p);
    }
    public async Task<Showcase?> ReadShowcase(string viewer,string code) {
        var p=await ByCode(code); if(p is null||!await Allowed(viewer,p.PlayerId,p.Visibility))return null;
        var s=await db.Showcases.SingleOrDefaultAsync(x=>x.Owner==p.PlayerId);
        return s is not null&&await Allowed(viewer,s.Owner,s.Visibility)?s:null;
    }
    public async Task Notify(string to,string actor,string kind) {
        // One activity per actor/kind per hour, bounded inbox. Read requests never fabricate visits.
        if(to==actor||await db.Activities.AnyAsync(x=>x.Recipient==to&&x.Actor==actor&&x.Kind==kind&&x.Created>DateTimeOffset.UtcNow.AddHours(-1)))return;
        db.Activities.Add(new Activity{Recipient=to,Actor=actor,Kind=kind});
        var old=await db.Activities.Where(x=>x.Recipient==to).OrderByDescending(x=>x.Id).Skip(199).ToListAsync();db.Activities.RemoveRange(old);
    }
    public async Task<bool> Request(string me,string code) {
        var p=await ByCode(code);if(p is null||p.PlayerId==me||await Blocked(me,p.PlayerId))return false;
        // Exact unguessable code acts as an invitation, including private profiles.
        string lo=string.CompareOrdinal(me,p.PlayerId)<0?me:p.PlayerId, hi=lo==me?p.PlayerId:me;
        if(!await db.Connections.AnyAsync(x=>x.Low==lo&&x.High==hi)) {
            if(await db.Connections.CountAsync(x=>x.Low==me||x.High==me)>=100||await db.Connections.CountAsync(x=>x.Low==p.PlayerId||x.High==p.PlayerId)>=100)return false;
            db.Connections.Add(new Connection{Low=lo,High=hi,Sender=me});await Notify(p.PlayerId,me,"friend_request");await db.SaveChangesAsync();
        } return true;
    }
    public async Task<bool> Accept(string me,string code) {
        var p=await ByCode(code);if(p is null||await Blocked(me,p.PlayerId))return false;
        var c=await db.Connections.SingleOrDefaultAsync(x=>(x.Low==me&&x.High==p.PlayerId)||(x.High==me&&x.Low==p.PlayerId));
        if(c is null||c.Sender==me)return false;
        if(c.State!="accepted"){c.State="accepted";await Notify(p.PlayerId,me,"friend_accepted");await db.SaveChangesAsync();}return true;
    }
    public async Task Remove(string me,string code,bool block=false) {
        var p=await ByCode(code);if(p is null||p.PlayerId==me)return;
        await using var tx=await db.Database.BeginTransactionAsync();
        await db.Connections.Where(x=>(x.Low==me&&x.High==p.PlayerId)||(x.High==me&&x.Low==p.PlayerId)).ExecuteDeleteAsync();
        if(block) {
            if(!await db.Blocks.AnyAsync(x=>x.Owner==me&&x.Target==p.PlayerId))db.Blocks.Add(new Block{Owner=me,Target=p.PlayerId});
            await db.Activities.Where(x=>(x.Recipient==me&&x.Actor==p.PlayerId)||(x.Recipient==p.PlayerId&&x.Actor==me)).ExecuteDeleteAsync();
            await db.Reactions.Where(x=>(x.Owner==me&&x.Sender==p.PlayerId)||(x.Sender==me&&x.Owner==p.PlayerId)).ExecuteDeleteAsync();
        }
        await db.SaveChangesAsync();await tx.CommitAsync();
    }
    public async Task<bool> Publish(string me,Publish request) {
        if(!Visibility(request.Visibility)||!Snapshot.Valid(request.Snapshot))return false;
        var raw=request.Snapshot.GetRawText(); if(Encoding.UTF8.GetByteCount(raw)>(request.Snapshot.TryGetProperty("version",out var snapshotVersion)&&snapshotVersion.ValueKind==JsonValueKind.Number&&snapshotVersion.TryGetInt32(out var snapshotVersionNumber)&&snapshotVersionNumber==3?Snapshot.MaxBytes:524288))return false;
        var hash=Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(raw)));
        var s=await db.Showcases.SingleOrDefaultAsync(x=>x.Owner==me);
        if(s is null){s=new Showcase{Owner=me};db.Showcases.Add(s);}
        var prev=await db.Versions.SingleOrDefaultAsync(x=>x.Owner==me&&x.Revision==s.Revision);
        if(prev?.Hash==hash&&s.Visibility==request.Visibility)return true;
        s.Visibility=request.Visibility;s.Revision++;s.Updated=DateTimeOffset.UtcNow;
        db.Versions.Add(new ShowcaseVersion{Owner=me,Revision=s.Revision,Document=raw,Hash=hash,Score=Snapshot.Score(request.Snapshot)});
        // Keep only three versions; inaccessible historical versions have no public endpoint.
        db.Versions.RemoveRange(await db.Versions.Where(x=>x.Owner==me&&x.Revision<=s.Revision-3).ToListAsync());
        if(s.Visibility!="private") {
            var friends=await db.Connections.Where(x=>x.State=="accepted"&&(x.Low==me||x.High==me)).ToListAsync();
            foreach(var f in friends)await Notify(f.Low==me?f.High:f.Low,me,"planet_updated");
        }
        await db.SaveChangesAsync();return true;
    }
    public async Task<bool> Reaction(string me,string code,int kind) {
        var s=await ReadShowcase(me,code);if(s is null||s.Owner==me||kind is <0 or >3||!await Friends(me,s.Owner))return false;
        var r=await db.Reactions.SingleOrDefaultAsync(x=>x.Owner==s.Owner&&x.Sender==me);
        if(r?.Kind==kind)return true;
        if(r is null)db.Reactions.Add(new Reaction{Owner=s.Owner,Sender=me,Kind=kind});else r.Kind=kind;
        await Notify(s.Owner,me,"planet_reaction");await db.SaveChangesAsync();return true;
    }
}
