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
    [Fact]public void StartingPoints(){
        var stats=Realms.Attributes.ToDictionary(k=>k,_=>0);stats["magic"]=10;
        Assert.True(Realms.ValidStats(stats));Assert.True(Realms.ValidStats(null));
        stats["strength"]=1;Assert.False(Realms.ValidStats(stats));
        stats["strength"]=-1;Assert.False(Realms.ValidStats(stats));
        stats.Remove("strength");Assert.False(Realms.ValidStats(stats));
    }
    [Fact]public void LegacyAndCombatStats(){
        var c=new RealmCharacter();Assert.Equal(100,Realms.MaxHealth(c));Assert.Equal(100,Realms.MaxMana(c));Assert.Equal(0,Realms.BonusAttack(c));
        c.PrimaryClass="mage";c.StartingStats="{\"magic\":6,\"vitality\":2,\"intelligence\":2}";
        Assert.Equal(106,Realms.MaxHealth(c));Assert.Equal(108,Realms.MaxMana(c));Assert.Equal(6,Realms.BonusAttack(c));
    }
    [Fact]public void CalendarUsesUtcAndNeverResets(){
        var now=DateTimeOffset.Parse("2026-10-28T00:00:00Z");var c=new RealmCharacter();Assert.True(Realms.DailyReady(c,now));
        c.LastDaily=now;Assert.False(Realms.DailyReady(c,now.AddHours(23)));
        Assert.True(Realms.DailyReady(c,now.AddDays(1)));c.RewardDays=12;
        Assert.True(Realms.DailyReady(c,now.AddDays(60)));Assert.Equal(12,c.RewardDays);
    }
}
