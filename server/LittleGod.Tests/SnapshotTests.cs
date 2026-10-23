using System.Text.Json;
using System.Text.Json.Nodes;
using LittleGod.Api;
namespace LittleGod.Tests;
public class SnapshotTests {
    static string Root=>Path.GetFullPath(Path.Combine(AppContext.BaseDirectory,"../../../../../"));
    static JsonObject Example()=>JsonNode.Parse(File.ReadAllText(Path.Combine(Root,"docs/examples/Lumi.lgplanet")))!.AsObject();
    static bool Valid(JsonNode node)=>Snapshot.Valid(JsonSerializer.SerializeToElement(node));
    [Theory]
    [InlineData("Lumi")][InlineData("Nacre")]
    public void ExistingPublicSnapshotsRemainCompatible(string name)=>Assert.True(Snapshot.Valid(JsonDocument.Parse(File.ReadAllText(Path.Combine(Root,$"docs/examples/{name}.lgplanet"))).RootElement));
    [Theory]
    [InlineData("version",999)][InlineData("version",0)]
    public void FutureOrInvalidVersionRefused(string key,int value){var d=Example();d[key]=value;Assert.False(Valid(d));}
    [Theory]
    [InlineData("script","res://evil.gd")][InlineData("seed","private seed")][InlineData("token","secret")]
    public void ExtraPrivateAndExecutableFieldsRefused(string key,string value){var d=Example();d[key]=value;Assert.False(Valid(d));}
    [Theory]
    [InlineData("https://tracking.example")][InlineData("../planet.json")][InlineData("[img]resource[/img]")][InlineData("name\nsecret")]
    public void UnsafePublicNamesRefused(string value){var d=Example();d["planet"]!["name"]=value;Assert.False(Valid(d));}
    [Fact] public void DuplicateCoordinatesRefused(){var d=Example();d["cells"]![1]!["x"]=d["cells"]![0]!["x"]!.DeepClone();d["cells"]![1]!["y"]=d["cells"]![0]!["y"]!.DeepClone();Assert.False(Valid(d));}
    [Fact] public void CreatureReferenceBounded(){var d=Example();d["creatures"]![0]!["companion"]=999;Assert.False(Valid(d));}
    [Fact] public void SelfRelationshipRefused(){var d=Example();d["creatures"]![0]!["companion"]=0;Assert.False(Valid(d));}
    [Fact] public void FractionalIndexRefused(){var d=Example();d["creatures"]![0]!["cell"]=1.25;Assert.False(Valid(d));}
    [Fact] public void UnknownTraitRefused(){var d=Example();d["creatures"]![0]!["trait"]="script";Assert.False(Valid(d));}
    [Fact] public void UnknownEventRefused(){var d=Example();d["memories"]![0]!["key"]="invented";Assert.False(Valid(d));}
    [Fact] public void DuplicateJsonPropertiesRefused(){var e=JsonDocument.Parse("{\"format\":\"littlegod.showcase\",\"format\":\"evil\"}");Assert.False(Snapshot.Valid(e.RootElement));}
    [Fact] public void NullDocumentRefused()=>Assert.False(Snapshot.Valid(JsonDocument.Parse("null").RootElement));
    [Fact] public void UndefinedDocumentRefused()=>Assert.False(Snapshot.Valid(default));
    [Fact] public void IntegralFloatRepresentationCompatible(){var d=Example();d["cells"]![0]!["biome"]=2.0;d["settlements"]![0]!["cell"]=d["settlements"]![0]!["cell"]!.GetValue<double>();Assert.True(Valid(d));Assert.True(Snapshot.Score(JsonSerializer.SerializeToElement(d))>0);}
}
