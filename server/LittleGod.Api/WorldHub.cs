using System.Net.WebSockets;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;

namespace LittleGod.Api;

// One cooperative beta realm. Clients send intent; positions, combat and rewards live here.
public sealed class WorldHub(IServiceScopeFactory scopes,ILogger<WorldHub> log):BackgroundService {
    public const int Capacity=32;
    readonly object gate=new();
    readonly Dictionary<string,Session> players=[];
    readonly List<Beast> beasts=[new(){Id=1,X=620,Y=550},new(){Id=2,X=920,Y=420}];
    long tick;
    readonly Dictionary<int,(string Id,List<string> Owners)> pending=[];
    sealed class Session {
        public required RealmCharacter Character;
        public required WebSocket Socket;
        public float X=350,Y=760,MoveX,MoveY;
        public int Hp=100,Mana=100;
        public long Sequence=-1,LastCommand,LastAttack=-100,LastSkill=-100,DownAt;
        public string Action="";
        public int Target;
        public long Ack=-1;
    }
    sealed class Beast {
        public int Id,Hp=100;public float X,Y;public long Revive,LastHit=-100,DamagedAt=-100;
        public HashSet<string> Contributors=[];
    }
    public int Count {get {lock(gate)return players.Count;}}
    public bool Contains(string id){lock(gate)return players.ContainsKey(id);}
    public static bool ValidMove(float x,float y)=>float.IsFinite(x)&&float.IsFinite(y)&&Math.Abs(x)<=1&&Math.Abs(y)<=1;
    public static bool ValidSequence(long previous,long next)=>next>previous&&next-previous<=1024;
    static string[] Allies(Session player)=>System.Text.Json.JsonSerializer.Deserialize<string[]>(player.Character.Unlocked)!.Where(c=>c!=player.Character.PrimaryClass).Take(3).ToArray();
    void Hit(Beast beast,Session player,int damage) {
        if(beast.Hp<=0)return;
        beast.Contributors.Add(player.Character.Id);beast.DamagedAt=tick;beast.Hp=Math.Max(0,beast.Hp-damage);
        if(beast.Hp==0){beast.Revive=long.MaxValue;pending[beast.Id]=(Guid.NewGuid().ToString("N"),beast.Contributors.Where(id=>players.TryGetValue(id,out var p)&&p.Hp>0&&Distance(p.X,p.Y,beast.X,beast.Y)<350).ToList());}
    }
    static float Distance(float x,float y,float a,float b)=>MathF.Sqrt((x-a)*(x-a)+(y-b)*(y-b));
    public async Task Connect(HttpContext context) {
        if(!context.WebSockets.IsWebSocketRequest){context.Response.StatusCode=400;return;}
        using var socket=await context.WebSockets.AcceptWebSocketAsync();
        using var limit=CancellationTokenSource.CreateLinkedTokenSource(context.RequestAborted);limit.CancelAfter(TimeSpan.FromSeconds(6));
        var first=await Receive(socket,limit.Token);
        if(first is null||!first.RootElement.TryGetProperty("ticket",out var property)||property.ValueKind!=JsonValueKind.String)return;
        var ticket=property.GetString()!;if(ticket.Length!=64)return;
        await using var scope=scopes.CreateAsyncScope();var db=scope.ServiceProvider.GetRequiredService<UniverseDb>();var hash=Realms.TicketHash(ticket);
        var row=await db.Set<RealmTicket>().Include(t=>t.Character).AsNoTracking().SingleOrDefaultAsync(t=>t.Hash==hash&&!t.Used&&t.Expires>DateTimeOffset.UtcNow);
        if(row is null)return;
        if(await db.Set<RealmTicket>().Where(t=>t.Hash==hash&&!t.Used&&t.Expires>DateTimeOffset.UtcNow).ExecuteUpdateAsync(s=>s.SetProperty(t=>t.Used,true))!=1)return;
        var session=new Session{Character=row.Character,Socket=socket};
        lock(gate){if(players.Count>=Capacity||players.ContainsKey(row.Character.Id))return;session.X+=80*(players.Count%4);session.Y+=35*(players.Count/4);players.Add(row.Character.Id,session);}
        try {
            var window=Environment.TickCount64;var messages=0;
            while(socket.State==WebSocketState.Open&&!context.RequestAborted.IsCancellationRequested) {
                using var doc=await Receive(socket,context.RequestAborted);if(doc is null)break;var root=doc.RootElement;
                if(Environment.TickCount64-window>=1000){window=Environment.TickCount64;messages=0;}
                if(++messages>60)break;
                if(!root.TryGetProperty("sequence",out var seq)||seq.ValueKind!=JsonValueKind.Number||!seq.TryGetInt64(out var n)||!root.TryGetProperty("x",out var x)||x.ValueKind!=JsonValueKind.Number||!x.TryGetSingle(out var mx)||!root.TryGetProperty("y",out var y)||y.ValueKind!=JsonValueKind.Number||!y.TryGetSingle(out var my)||!ValidMove(mx,my))continue;
                var action=root.TryGetProperty("action",out var a)&&a.ValueKind==JsonValueKind.String?a.GetString()!:"";
                var target=root.TryGetProperty("target",out var t)&&t.ValueKind==JsonValueKind.Number&&t.TryGetInt32(out var id)?id:0;
                lock(gate){
                    if(!ValidSequence(session.Sequence,n))continue;
                    session.Sequence=n;session.LastCommand=tick;session.MoveX=mx;session.MoveY=my;
                    if(action is "attack" or "skill" or "dodge"){session.Action=action;session.Target=target;}
                }
            }
        } catch(OperationCanceledException) {} catch(WebSocketException) {} finally {
            lock(gate){if(players.GetValueOrDefault(row.Character.Id)==session)players.Remove(row.Character.Id);}
            if(socket.State==WebSocketState.Open)await socket.CloseAsync(WebSocketCloseStatus.NormalClosure,"Left realm",CancellationToken.None);
        }
    }
    static async Task<JsonDocument?> Receive(WebSocket socket,CancellationToken token) {
        var buffer=new byte[4096];var count=0;
        do {
            var result=await socket.ReceiveAsync(new ArraySegment<byte>(buffer,count,buffer.Length-count),token);
            if(result.MessageType!=WebSocketMessageType.Text)return null;
            count+=result.Count;if(count>=buffer.Length)return null;
            if(result.EndOfMessage)break;
        }while(true);
        try{var doc=JsonDocument.Parse(buffer.AsMemory(0,count));if(doc.RootElement.ValueKind==JsonValueKind.Object)return doc;doc.Dispose();return null;}catch(JsonException){return null;}
    }
    protected override async Task ExecuteAsync(CancellationToken stoppingToken) {
        using var timer=new PeriodicTimer(TimeSpan.FromMilliseconds(100));
        while(await timer.WaitForNextTickAsync(stoppingToken)) {
            List<(int Beast,string Id,List<string> Owners)> rewards=[];
            lock(gate) {
                tick++;
                foreach(var player in players.Values) {
                    if(player.Hp<=0){if(tick-player.DownAt>50){player.Hp=100;player.Mana=100;player.X=350;player.Y=760;}continue;}
                    var mx=tick-player.LastCommand<=4?player.MoveX:0;var my=tick-player.LastCommand<=4?player.MoveY:0;var length=MathF.Max(1,MathF.Sqrt(mx*mx+my*my));
                    var action=player.Action;player.Action="";player.Ack=player.Sequence;
                    var speed=14f;if(action=="dodge"&&tick-player.LastSkill>=12){speed=70;player.LastSkill=tick;}
                    player.X=Math.Clamp(player.X+mx/length*speed,80,1220);player.Y=Math.Clamp(player.Y+my/length*speed,100,880);
                    if(tick%10==0)player.Mana=Math.Min(100,player.Mana+2);
                    if(tick%20==0&&tick-player.LastAttack<30)foreach(var ally in Allies(player)) {
                        if(ally=="priest"&&player.Hp<85){player.Hp=Math.Min(100,player.Hp+5);continue;}
                        var nearby=beasts.FirstOrDefault(b=>b.Hp>0&&Distance(player.X,player.Y,b.X,b.Y)<200);if(nearby is not null)Hit(nearby,player,7);
                    }
                    if(action is not ("attack" or "skill"))continue;
                    var heavy=action=="skill";if(heavy&&(player.Mana<8||tick-player.LastSkill<40)||!heavy&&tick-player.LastAttack<7)continue;
                    var beast=beasts.FirstOrDefault(b=>b.Id==player.Target&&b.Hp>0);if(beast is null)continue;
                    var ranged=player.Character.PrimaryClass is "mage" or "priest" or "rogue";
                    if(Distance(player.X,player.Y,beast.X,beast.Y)>(ranged?270:115))continue;
                    if(heavy){player.Mana-=8;player.LastSkill=tick;}else player.LastAttack=tick;
                    Hit(beast,player,heavy?32:16);
                }
                foreach(var beast in beasts) {
                    if(beast.Hp==0){if(tick>=beast.Revive){beast.Hp=100;beast.Contributors.Clear();}continue;}
                    var target=players.Values.Where(p=>p.Hp>0&&Distance(p.X,p.Y,beast.X,beast.Y)<300).OrderBy(p=>Distance(p.X,p.Y,beast.X,beast.Y)).FirstOrDefault();if(target is null)continue;
                    var dx=target.X-beast.X;var dy=target.Y-beast.Y;var length=Distance(target.X,target.Y,beast.X,beast.Y);
                    if(length>65){beast.X+=dx/length*6;beast.Y+=dy/length*6;}
                    else if(tick-beast.LastHit>=15){beast.LastHit=tick;target.Hp=Math.Max(0,target.Hp-7);if(target.Hp==0)target.DownAt=tick;}
                }
                rewards=pending.Select(r=>(r.Key,r.Value.Id,r.Value.Owners)).ToList();
            }
            foreach(var reward in rewards) {
                try {
                    await using var scope=scopes.CreateAsyncScope();var db=scope.ServiceProvider.GetRequiredService<UniverseDb>();
                    await using var tx=await db.Database.BeginTransactionAsync(stoppingToken);
                    if(!await db.Set<RealmReward>().AnyAsync(r=>r.Id==reward.Id,stoppingToken)) {
                        db.Add(new RealmReward{Id=reward.Id});await db.SaveChangesAsync(stoppingToken);
                        await db.Set<RealmCharacter>().Where(c=>reward.Owners.Contains(c.Id)).ExecuteUpdateAsync(s=>s.SetProperty(c=>c.Experience,c=>c.Experience+20).SetProperty(c=>c.Essence,c=>c.Essence+1).SetProperty(c=>c.Hunts,c=>c.Hunts+1),stoppingToken);
                    }
                    await tx.CommitAsync(stoppingToken);
                    var awarded=await db.Set<RealmCharacter>().AsNoTracking().Where(c=>reward.Owners.Contains(c.Id)).ToListAsync(stoppingToken);
                    lock(gate){foreach(var c in awarded)if(players.TryGetValue(c.Id,out var p)){p.Character.Experience=c.Experience;p.Character.Essence=c.Essence;p.Character.Hunts=c.Hunts;}pending.Remove(reward.Beast);beasts.Single(b=>b.Id==reward.Beast).Revive=tick+150;}
                }catch(Exception){log.LogWarning("Realm reward could not be persisted; beast {Id}",reward.Beast);}
            }
            Session[] sessions;byte[] packet;
            lock(gate) {
                sessions=players.Values.ToArray();
                packet=JsonSerializer.SerializeToUtf8Bytes(new{version=1,tick,players=sessions.Select(p=>new{id=p.Character.Id,name=p.Character.Name,job=p.Character.PrimaryClass,x=p.X,y=p.Y,hp=p.Hp,mp=p.Mana,xp=p.Character.Experience,essence=p.Character.Essence,hunts=p.Character.Hunts,ack=p.Ack,attack=p.LastAttack,cast=p.LastSkill,target=p.Target}),companions=sessions.SelectMany(p=>Allies(p).Select((job,i)=>new{id=p.Character.Id+"_"+job,owner=p.Character.Id,job,x=Math.Clamp(p.X-60+i*50,80,1220),y=Math.Clamp(p.Y+55,100,880),hp=p.Hp})),enemies=beasts.Select(b=>new{id=b.Id,x=b.X,y=b.Y,hp=b.Hp,hit=b.DamagedAt})});
            }
            // A slow peer cannot stall the realm's simulation indefinitely.
            await Task.WhenAll(sessions.Select(async p=>{
                using var timeout=CancellationTokenSource.CreateLinkedTokenSource(stoppingToken);timeout.CancelAfter(300);
                try{await p.Socket.SendAsync(packet,WebSocketMessageType.Text,true,timeout.Token);}catch(Exception){p.Socket.Abort();}
            }));
            if(tick%600==0)try {
                await using var scope=scopes.CreateAsyncScope();var db=scope.ServiceProvider.GetRequiredService<UniverseDb>();await db.Set<RealmTicket>().Where(t=>t.Expires<DateTimeOffset.UtcNow).ExecuteDeleteAsync(stoppingToken);
            }catch(Exception){log.LogWarning("Realm ticket cleanup deferred");}
        }
    }
}
