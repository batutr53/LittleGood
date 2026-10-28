using LittleGod.Api;
namespace LittleGod.Tests;
public class RealmTests {
    [Theory]
    [InlineData("Arden",true)][InlineData("İlk Kahraman",true)][InlineData("A",false)]
    [InlineData(" Aster",false)][InlineData("Aster ",false)][InlineData("<Mage>",false)]
    [InlineData("Mage\nLord",false)][InlineData("123",false)][InlineData(null,false)]
    public void Names(string? name,bool valid)=>Assert.Equal(valid,Realms.ValidName(name));
    [Fact]public void Movement(){Assert.True(WorldHub.ValidMove(1,-1));Assert.False(WorldHub.ValidMove(float.NaN,0));Assert.False(WorldHub.ValidMove(0,float.PositiveInfinity));Assert.False(WorldHub.ValidMove(2,0));}
    [Fact]public void Replay(){Assert.True(WorldHub.ValidSequence(-1,0));Assert.False(WorldHub.ValidSequence(5,5));Assert.False(WorldHub.ValidSequence(5,4));Assert.False(WorldHub.ValidSequence(5,5000));}
    [Fact]public void OpaqueTicket(){var token=Guid.NewGuid().ToString("N");Assert.Equal(64,Realms.TicketHash(token).Length);Assert.NotEqual(token,Realms.TicketHash(token));}
}
