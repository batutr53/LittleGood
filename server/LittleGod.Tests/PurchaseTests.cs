using LittleGod.Api;
using System.Text.Json;
using System.Text.Json.Nodes;
namespace LittleGod.Tests;
public class PurchaseTests {
    [Theory]
    [InlineData("pending",false)][InlineData("completed",true)][InlineData("cancelled",false)][InlineData("failed",false)][InlineData("revoked",false)]
    public void OnlyCompletedGrants(string state,bool active)=>Assert.Equal(active,PurchasePolicy.Active(state));
    [Fact] public void ClientBooleanCannotVerify()=>Assert.False(PurchasePolicy.ValidProof(new("client",PurchasePolicy.Product,"true")));
    [Fact] public void EmptyProofDenied()=>Assert.False(PurchasePolicy.ValidProof(new("google",PurchasePolicy.Product,"")));
    [Fact] public void OversizedProofDenied()=>Assert.False(PurchasePolicy.ValidProof(new("google",PurchasePolicy.Product,new string('x',8193))));
    [Fact] public void WrongProductDenied()=>Assert.False(PurchasePolicy.ValidProof(new("apple","currency_pack","receipt")));
    [Fact] public void OtherAccountReceiptDenied()=>Assert.False(PurchasePolicy.Trusted(new("google","tx",PurchasePolicy.Product,"B","completed"),"A"));
    [Fact] public void RevocationIsTerminal()=>Assert.Equal("revoked",PurchasePolicy.Transition("revoked","completed"));
    [Theory][InlineData("pending")][InlineData("failed")][InlineData("cancelled")]
    public void StaleEventsDoNotRemoveCompletedOwnership(string state)=>Assert.Equal("completed",PurchasePolicy.Transition("completed",state));
    [Fact] public async Task RealProviderIsClosed()=>Assert.Null(await new DisabledStoreVerifier().Verify(new("google",PurchasePolicy.Product,"unverified"),"A",default));
    static JsonObject Public()=>JsonNode.Parse(File.ReadAllText(Path.GetFullPath(Path.Combine(AppContext.BaseDirectory,"../../../../../docs/examples/Lumi.lgplanet"))))!.AsObject();
    static JsonObject V2(){var p=Public();p["version"]=2;p["appearance"]=JsonNode.Parse("{\"theme\":\"crystal\",\"sky\":\"aurora\",\"frame\":\"orbit\",\"placements\":[{\"id\":1,\"cell\":0,\"rotation\":0,\"item\":\"flowers\"}],\"coats\":[{\"id\":0,\"item\":\"mint\"}]}");return p;}
    [Fact] public void BothShowcaseVersionsAccepted(){Assert.True(Snapshot.Valid(JsonSerializer.SerializeToElement(Public())));Assert.True(Snapshot.Valid(JsonSerializer.SerializeToElement(V2())));}
    [Theory][InlineData("royal_pack")][InlineData("res://evil.svg")][InlineData("unknown")]
    public void UnverifiedPremiumOrUnknownAppearanceDenied(string id){var p=V2();p["appearance"]!["theme"]=id;Assert.False(Snapshot.Valid(JsonSerializer.SerializeToElement(p)));}
    [Fact] public void PublicEconomyFieldRefused(){var p=V2();p["appearance"]!["dust"]=999;Assert.False(Snapshot.Valid(JsonSerializer.SerializeToElement(p)));}
    [Fact] public void CosmeticTargetBounded(){var p=V2();p["appearance"]!["coats"]![0]!["id"]=99999;Assert.False(Snapshot.Valid(JsonSerializer.SerializeToElement(p)));}
}
