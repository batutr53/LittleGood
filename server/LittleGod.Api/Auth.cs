using System.Security.Claims;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.BearerToken;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;

namespace LittleGod.Api;
public record Credentials(string Account, string Password);
public record Renewal(string RefreshToken);
public static partial class Auth {
    [GeneratedRegex("^[a-zA-Z0-9_.-]{4,64}$")]
    private static partial Regex AccountPattern();
    public static void MapAuth(this WebApplication app) {
        var g=app.MapGroup("/api/v1/auth").RequireRateLimiting("auth");
        g.MapPost("/register", async (Credentials c,UserManager<Player> users,UniverseDb db) => {
            if(c.Account is null || c.Password is null || !AccountPattern().IsMatch(c.Account) || c.Password.Length is <12 or >128)
                return Results.BadRequest(new{error="account_or_password_invalid"});
            // Identical status/body for existing and new accounts; never return Identity error details.
            var p=new Player{UserName=c.Account};
            await using var tx=await db.Database.BeginTransactionAsync();
            var result=await users.CreateAsync(p,c.Password);
            if(!result.Succeeded)new PasswordHasher<Player>().HashPassword(p,c.Password);
            if(result.Succeeded) { db.Profiles.Add(new Profile{PlayerId=p.Id}); await db.SaveChangesAsync(); await tx.CommitAsync(); }
            return Results.Accepted(value:new{message="registration_processed_sign_in"});
        });
        g.MapPost("/login",async(Credentials c,UserManager<Player> users,SignInManager<Player> signin)=>{
            if(c.Account is null || c.Password is null || c.Account.Length>64 || c.Password.Length>128) return Results.Unauthorized();
            var p=await users.FindByNameAsync(c.Account);
            if(p is null) {
                // Run the maintained Identity password hasher even for unknown accounts.
                var dummy=new Player(); var hasher=new PasswordHasher<Player>();
                hasher.HashPassword(dummy,c.Password); return Results.Unauthorized();
            }
            var result=await signin.CheckPasswordSignInAsync(p,c.Password,true);
            if(!result.Succeeded) return Results.Unauthorized();
            var principal=await signin.CreateUserPrincipalAsync(p);
            return Results.SignIn(principal,authenticationScheme:IdentityConstants.BearerScheme);
        });
        g.MapPost("/refresh",async(Renewal r,IOptionsMonitor<BearerTokenOptions> options,SignInManager<Player> signin)=>{
            if(r.RefreshToken is null || r.RefreshToken.Length>8192) return Results.Unauthorized();
            var ticket=options.Get(IdentityConstants.BearerScheme).RefreshTokenProtector.Unprotect(r.RefreshToken);
            if(ticket?.Properties.ExpiresUtc is not {} expiry || expiry<DateTimeOffset.UtcNow) return Results.Unauthorized();
            var p=await signin.ValidateSecurityStampAsync(ticket.Principal);
            if(p is null) return Results.Unauthorized();
            return Results.SignIn(await signin.CreateUserPrincipalAsync(p),authenticationScheme:IdentityConstants.BearerScheme);
        });
        g.MapPost("/logout",async(ClaimsPrincipal principal,UserManager<Player> users)=>{
            var p=await users.GetUserAsync(principal); if(p is null)return Results.Unauthorized();
            await users.UpdateSecurityStampAsync(p); return Results.NoContent();
        }).RequireAuthorization();
        app.MapDelete("/api/v1/me",async(ClaimsPrincipal principal,UserManager<Player> users)=>{
            var p=await users.GetUserAsync(principal); if(p is null)return Results.Unauthorized();
            await users.DeleteAsync(p); return Results.NoContent();
        }).RequireAuthorization().RequireRateLimiting("auth");
    }
}
