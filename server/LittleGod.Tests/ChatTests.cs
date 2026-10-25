using LittleGod.Api;
namespace LittleGod.Tests;
public class ChatTests {
    [Theory]
    [InlineData(null,false)]
    [InlineData("",false)]
    [InlineData(" hello",false)]
    [InlineData("hello ",false)]
    [InlineData("hello\nworld",false)]
    [InlineData("hello\u0000world",false)]
    [InlineData("Merhaba dünya",true)]
    [InlineData("Hello <world>",true)] // rendered as plain text, never markup
    public void MessageContract(string? text,bool expected)=>Assert.Equal(expected,ChatEndpoints.ValidText(text));
    [Fact] public void ExactBoundary(){Assert.True(ChatEndpoints.ValidText(new string('a',300)));Assert.False(ChatEndpoints.ValidText(new string('a',301)));}
}
