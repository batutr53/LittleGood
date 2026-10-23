using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
namespace LittleGod.Api;
public record StoreProof(string Store,string Product,string Proof);
public record VerifiedPurchase(string Store,string Transaction,string Product,string Account,string State);
public interface IStoreVerifier {Task<VerifiedPurchase?> Verify(StoreProof proof,string account,CancellationToken cancellationToken);}
// No configuration switch can turn a client boolean or local mock into an entitlement.
public sealed class DisabledStoreVerifier : IStoreVerifier {
    public Task<VerifiedPurchase?> Verify(StoreProof proof,string account,CancellationToken cancellationToken)=>Task.FromResult<VerifiedPurchase?>(null);
}
public sealed class PurchaseReceipt {
    public string Store {get;set;}="";
    public string Transaction {get;set;}="";
    public string Owner {get;set;}="";
    public Player Player {get;set;}=null!;
    public string Product {get;set;}="";
    public string State {get;set;}="";
    public DateTimeOffset VerifiedAt {get;set;}
}
public static class PurchasePolicy {
    public const string Product="org.littlegod.cosmetics.astral_heirloom.v1";
    public static bool ValidProof(StoreProof p)=>p.Store is "google" or "apple"&&p.Product==Product&&p.Proof is not null&&p.Proof.Length is >=1 and <=8192;
    public static bool Trusted(VerifiedPurchase p,string account)=>p.Account==account&&p.Product==Product&&p.Store is "google" or "apple"&&p.Transaction.Length is >=1 and <=256&&p.State is "pending" or "completed" or "cancelled" or "failed" or "revoked";
    public static bool Active(string state)=>state=="completed";
    public static string Transition(string previous,string next)=>previous=="revoked"?"revoked":previous=="completed"&&next is "pending" or "cancelled" or "failed"?"completed":next;
}
public sealed class PurchaseService(UniverseDb db,IStoreVerifier verifier) {
    public async Task<string> Verify(string account,StoreProof proof,CancellationToken ct) {
        if(!PurchasePolicy.ValidProof(proof))return "invalid";
        var verified=await verifier.Verify(proof,account,ct);
        if(verified is null)return "unavailable";
        if(!PurchasePolicy.Trusted(verified,account)||verified.Store!=proof.Store||verified.Product!=proof.Product)return "invalid";
        await using var tx=await db.Database.BeginTransactionAsync(ct);
        var row=await db.Set<PurchaseReceipt>().SingleOrDefaultAsync(x=>x.Store==verified.Store&&x.Transaction==verified.Transaction,ct);
        if(row is not null&&row.Owner!=account)return "conflict";
        if(row is null){row=new PurchaseReceipt{Store=verified.Store,Transaction=verified.Transaction,Owner=account,Product=verified.Product};db.Add(row);}
        row.State=PurchasePolicy.Transition(row.State,verified.State);row.VerifiedAt=DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);await tx.CommitAsync(ct);return row.State;
    }
}
public static class PurchaseEndpoints {
    public static void MapPurchases(this WebApplication app) {
        var api=app.MapGroup("/api/v1").RequireAuthorization();
        api.MapGet("/purchases/products",()=>new{version=1,enabled=false,items=new[]{new{product=PurchasePolicy.Product,item="royal_pack",available=false}}});
        api.MapPost("/purchases/verify",async(StoreProof p,ClaimsPrincipal user,PurchaseService service,CancellationToken ct)=>{
            var state=await service.Verify(user.FindFirstValue(ClaimTypes.NameIdentifier)!,p,ct);
            return state=="invalid"?Results.BadRequest(new{error="invalid_store_proof"}):state=="unavailable"?Results.Json(new{error="store_verification_unavailable"},statusCode:503):state=="conflict"?Results.Conflict():Results.Ok(new{state,version=1});
        }).RequireRateLimiting("write");
        api.MapGet("/me/entitlements",async(ClaimsPrincipal user,UniverseDb db)=>{
            var id=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            return Results.Ok(new{version=1,items=await db.Set<PurchaseReceipt>().Where(x=>x.Owner==id&&x.State=="completed").Select(x=>new{product=x.Product,item="royal_pack",verifiedAt=x.VerifiedAt}).Distinct().ToListAsync()});
        });
        api.MapPost("/purchases/restore",async(ClaimsPrincipal user,UniverseDb db)=>{
            var id=user.FindFirstValue(ClaimTypes.NameIdentifier)!;
            return Results.Ok(new{version=1,storeReconciliation="unavailable",items=await db.Set<PurchaseReceipt>().Where(x=>x.Owner==id&&x.State=="completed").Select(x=>new{product=x.Product,item="royal_pack"}).Distinct().ToListAsync()});
        }).RequireRateLimiting("write");
    }
}
