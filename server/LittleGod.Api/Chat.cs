using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
namespace LittleGod.Api;

public sealed class ChatMessage {
    public long Id { get; set; }
    public string Sender { get; set; } = "";
    public string? Recipient { get; set; }
    public string Text { get; set; } = "";
    public DateTimeOffset Created { get; set; } = DateTimeOffset.UtcNow;
}
public sealed class ChatReport {
    public long Id { get; set; }
    public long MessageId { get; set; }
    public string Reporter { get; set; } = "";
    public string Sender { get; set; } = "";
    public string Text { get; set; } = "";
    public string Reason { get; set; } = "";
    public DateTimeOffset Created { get; set; } = DateTimeOffset.UtcNow;
}
public record ChatSend(string Text, string? Recipient);
public record ChatFlag(string Reason);
public static class ChatEndpoints {
    public static bool ValidText(string? text) => text is { Length: >0 and <=300 } && text==text.Trim() && !text.Any(char.IsControl);
    public static void MapChat(this WebApplication app) {
        var api=app.MapGroup("/api/v1/chat").RequireAuthorization();
        api.MapPost("/messages",async(ChatSend body,ClaimsPrincipal user,UniverseDb db,SocialService social)=>{
            var me=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            if(!ValidText(body.Text))return Results.BadRequest(new{error="invalid_message"});
            string? target=null;
            if(body.Recipient is not null) {
                var p=await social.ByCode(body.Recipient);
                if(p is null||!await social.Friends(me,p.PlayerId)||await social.Blocked(me,p.PlayerId))return Results.NotFound();
                target=p.PlayerId;
            }
            await using var tx=await db.Database.BeginTransactionAsync();
            // Serialize concurrent sends by authenticated sender, including across API instances.
            await db.Database.ExecuteSqlInterpolatedAsync($"SELECT pg_advisory_xact_lock(hashtext({me}))");
            var now=DateTimeOffset.UtcNow;
            if(await db.Set<ChatMessage>().AnyAsync(x=>x.Sender==me&&x.Created>now.AddSeconds(-2)))return Results.StatusCode(429);
            var message=new ChatMessage{Sender=me,Recipient=target,Text=body.Text,Created=now};db.Add(message);await db.SaveChangesAsync();await tx.CommitAsync();
            return Results.Ok(new{id=message.Id,created=message.Created});
        });
        api.MapGet("/messages",async(ClaimsPrincipal user,UniverseDb db,SocialService social,string? peer=null,long before=long.MaxValue,long after=0)=>{
            if(before<1||after<0)return Results.BadRequest();
            var me=user.FindFirstValue(ClaimTypes.NameIdentifier)!;string? target=null;
            if(peer is not null) {
                var p=await social.ByCode(peer);
                if(p is null||!await social.Friends(me,p.PlayerId)||await social.Blocked(me,p.PlayerId))return Results.NotFound();
                target=p.PlayerId;
            }
            var since=DateTimeOffset.UtcNow.AddDays(-7);
            var query=db.Set<ChatMessage>().Where(x=>x.Created>=since&&x.Id<before&&x.Id>after);
            query=target is null?query.Where(x=>x.Recipient==null):query.Where(x=>(x.Sender==me&&x.Recipient==target)||(x.Sender==target&&x.Recipient==me));
            query=query.Where(x=>!db.Blocks.Any(b=>(b.Owner==me&&b.Target==x.Sender)||(b.Owner==x.Sender&&b.Target==me)));
            var ordered=after>0?query.OrderBy(x=>x.Id):query.OrderByDescending(x=>x.Id);
            var rows=await ordered.Take(50).Join(db.Profiles,m=>m.Sender,p=>p.PlayerId,(m,p)=>new{id=m.Id,sender=p.Code,name=p.Name,text=m.Text,created=m.Created}).ToListAsync();
            return Results.Ok(new{items=rows.OrderBy(x=>x.id),next=rows.Count==50?rows[^1].id:(long?)null});
        });
        api.MapPost("/messages/{id:long}/report",async(long id,ChatFlag body,ClaimsPrincipal user,UniverseDb db,SocialService social)=>{
            if(!ValidText(body.Reason))return Results.BadRequest();var me=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            var m=await db.Set<ChatMessage>().SingleOrDefaultAsync(x=>x.Id==id&&x.Created>=DateTimeOffset.UtcNow.AddDays(-7));
            if(m is null||m.Sender==me||(m.Recipient is not null&&m.Recipient!=me)||await social.Blocked(me,m.Sender))return Results.NotFound();
            if(!await db.Set<ChatReport>().AnyAsync(x=>x.Reporter==me&&x.MessageId==id)) {
                db.Add(new ChatReport{Reporter=me,MessageId=id,Sender=m.Sender,Text=m.Text,Reason=body.Reason});await db.SaveChangesAsync();
            }
            return Results.NoContent();
        }).RequireRateLimiting("write");
    }
}
public sealed class ChatRetention(IServiceScopeFactory scopes,ILogger<ChatRetention> logger):BackgroundService {
    protected override async Task ExecuteAsync(CancellationToken token) {
        using var timer=new PeriodicTimer(TimeSpan.FromHours(1));
        do {
            try {using var scope=scopes.CreateScope();var db=scope.ServiceProvider.GetRequiredService<UniverseDb>();await db.Set<ChatMessage>().Where(x=>x.Created<DateTimeOffset.UtcNow.AddDays(-7)).ExecuteDeleteAsync(token);}
            catch(Exception) when(!token.IsCancellationRequested){logger.LogWarning("Chat retention deferred");}
        } while(await timer.WaitForNextTickAsync(token));
    }
}
