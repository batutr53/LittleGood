using System.Security.Claims;
using System.Text.Json;
using System.Threading.RateLimiting;
using LittleGod.Api;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

var builder=WebApplication.CreateBuilder(args);
builder.WebHost.ConfigureKestrel(o=>o.Limits.MaxRequestBodySize=540672);
builder.Services.ConfigureHttpJsonOptions(o=>{o.SerializerOptions.MaxDepth=12;o.SerializerOptions.UnmappedMemberHandling=System.Text.Json.Serialization.JsonUnmappedMemberHandling.Disallow;});
builder.Services.AddDbContext<UniverseDb>(o=>o.UseNpgsql(builder.Configuration.GetConnectionString("Universe")??throw new InvalidOperationException("Configure ConnectionStrings__Universe")));
builder.Services.AddIdentityApiEndpoints<Player>(o=>{
    o.Password.RequiredLength=12;o.Password.RequireDigit=false;o.Password.RequireUppercase=false;o.Password.RequireLowercase=false;o.Password.RequireNonAlphanumeric=false;
    o.Lockout.MaxFailedAccessAttempts=5;o.Lockout.DefaultLockoutTimeSpan=TimeSpan.FromMinutes(10);
}).AddEntityFrameworkStores<UniverseDb>();
builder.Services.Configure<BearerTokenOptions>(IdentityConstants.BearerScheme,o=>{o.BearerTokenExpiration=TimeSpan.FromMinutes(15);o.RefreshTokenExpiration=TimeSpan.FromHours(8);});
builder.Services.AddAuthorization();builder.Services.AddScoped<SocialService>();builder.Services.AddOpenApi();
var keys=builder.Configuration["DataProtectionDirectory"];
if(!string.IsNullOrEmpty(keys)) {
    var protection=builder.Services.AddDataProtection().PersistKeysToFileSystem(new DirectoryInfo(keys)).SetApplicationName("LittleGod.Universe.v1");
    if(OperatingSystem.IsWindows())protection.ProtectKeysWithDpapi();
}
builder.Services.AddRateLimiter(o=>{
    o.RejectionStatusCode=429;
    o.GlobalLimiter=PartitionedRateLimiter.Create<HttpContext,string>(c=>RateLimitPartition.GetFixedWindowLimiter(c.User.FindFirstValue(ClaimTypes.NameIdentifier)??c.Connection.RemoteIpAddress?.ToString()??"unknown",_=>new(){PermitLimit=120,Window=TimeSpan.FromMinutes(1),QueueLimit=0}));
    o.AddPolicy("auth",c=>RateLimitPartition.GetFixedWindowLimiter(c.Connection.RemoteIpAddress?.ToString()??"unknown",_=>new(){PermitLimit=20,Window=TimeSpan.FromMinutes(1),QueueLimit=0}));
    o.AddPolicy("write",c=>RateLimitPartition.GetFixedWindowLimiter(c.User.FindFirstValue(ClaimTypes.NameIdentifier)??"unknown",_=>new(){PermitLimit=20,Window=TimeSpan.FromMinutes(1),QueueLimit=0}));
});
var app=builder.Build();
if(builder.Configuration.GetValue<bool>("MigrateOnStart")) {
    using var scope=app.Services.CreateScope();await scope.ServiceProvider.GetRequiredService<UniverseDb>().Database.MigrateAsync();
}
app.Use(async(c,next)=>{
    c.Response.Headers["Cache-Control"]="no-store";c.Response.Headers["X-Content-Type-Options"]="nosniff";
    if(!app.Environment.IsDevelopment()&&!c.Request.IsHttps){c.Response.StatusCode=400;await c.Response.WriteAsJsonAsync(new{error="https_required"});return;}
    try {await next();}
    catch(BadHttpRequestException e){c.Response.StatusCode=e.StatusCode;await c.Response.WriteAsJsonAsync(new{error="invalid_request"});}
    catch(JsonException){c.Response.StatusCode=400;await c.Response.WriteAsJsonAsync(new{error="invalid_json"});}
    catch(DbUpdateException){c.Response.StatusCode=409;await c.Response.WriteAsJsonAsync(new{error="conflict_retry"});}
    catch(Exception){c.Response.StatusCode=503;await c.Response.WriteAsJsonAsync(new{error="service_unavailable"});app.Logger.LogWarning("Request failed {Method} {Status}",c.Request.Method,503);}
});
app.UseAuthentication();
app.Use(async(c,next)=>{
    if(c.User.Identity?.IsAuthenticated==true){var signin=c.RequestServices.GetRequiredService<SignInManager<Player>>();if(await signin.ValidateSecurityStampAsync(c.User) is null){c.Response.StatusCode=401;return;}}
    await next();
});
app.UseRateLimiter();app.UseAuthorization();
app.MapGet("/health",async(UniverseDb db)=>await db.Database.CanConnectAsync()?Results.Ok(new{status="ok",version=1}):Results.StatusCode(503));
if(app.Environment.IsDevelopment())app.MapOpenApi();
app.MapAuth();app.MapSocial();app.Run();
public partial class Program { }
