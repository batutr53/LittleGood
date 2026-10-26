using System.Text.Json;
namespace LittleGod.Api;

// Mirrors the public v1 projection, never accepts a private save or resource reference.
public static class Snapshot {
    public const int MaxBytes=2097152;
    static bool Shape(JsonElement e,string keys)=>e.ValueKind==JsonValueKind.Object && e.EnumerateObject().Select(x=>x.Name).Order().SequenceEqual(keys.Split(' ').Order());
    static bool Num(JsonElement e,double lo,double hi,bool whole=false)=>e.ValueKind==JsonValueKind.Number && e.TryGetDouble(out var n)&&double.IsFinite(n)&&n>=lo&&n<=hi&&(!whole||Math.Floor(n)==n);
    static bool N(JsonElement e,string k,double lo,double hi,bool whole=false)=>Num(e.GetProperty(k),lo,hi,whole);
    static bool Bool(JsonElement e)=>e.ValueKind is JsonValueKind.True or JsonValueKind.False;
    public static bool Text(string? s,int max,bool nonempty=false)=>s is not null&&s.Length<=max&&(!nonempty||!string.IsNullOrWhiteSpace(s))&&!s.Any(c=>char.IsControl(c)||"/\\:<>[]{}".Contains(c));
    static bool T(JsonElement e,string k,int max,bool required=false)=>e.GetProperty(k).ValueKind==JsonValueKind.String&&Text(e.GetProperty(k).GetString(),max,required);
    static bool Array(JsonElement e,int min,int max)=>e.ValueKind==JsonValueKind.Array&&e.GetArrayLength()>=min&&e.GetArrayLength()<=max;
    static bool Indices(JsonElement e,int max,int highest)=>Array(e,0,max)&&e.EnumerateArray().All(x=>Num(x,0,highest,true))&&e.EnumerateArray().Select(x=>x.GetDouble()).Distinct().Count()==e.GetArrayLength();
    static bool Choices(JsonElement e,string choices,int max)=>Array(e,0,max)&&e.EnumerateArray().All(x=>x.ValueKind==JsonValueKind.String&&choices.Split(' ').Contains(x.GetString()))&&e.EnumerateArray().Select(x=>x.GetString()).Distinct().Count()==e.GetArrayLength();
    const string Memories="rain_bloom friendship lantern_grove first_village first_birth companions rivalry explored landmark alliance mountain_spring silver_fox rainbow_choir elder rescue canopy_arch reed_shelter migration trade boundary cooperation";
    public static bool Valid(JsonElement d, bool large=false) {
        try {
            if(d.ValueKind==JsonValueKind.Object&&d.TryGetProperty("version",out var version)&&Num(version,2,3,true)) {
                if(!Shape(d,"format version planet cells creatures settlements memories discoveries secrets findings appearance"))return false;
                var legacy=System.Text.Json.Nodes.JsonNode.Parse(d.GetRawText())!.AsObject();legacy.Remove("appearance");legacy["version"]=1;
                return Valid(JsonSerializer.SerializeToElement(legacy),version.GetInt32()==3)&&Appearance(d.GetProperty("appearance"),d.GetProperty("cells").GetArrayLength(),d.GetProperty("creatures").GetArrayLength());
            }
            if(!Shape(d,"format version planet cells creatures settlements memories discoveries secrets findings")||d.GetProperty("format").GetString()!="littlegod.showcase"||!N(d,"version",1,1,true))return false;
            var p=d.GetProperty("planet");
            if(!Shape(p,"name tick weather theme xp")||!T(p,"name",32,true)||!N(p,"tick",0,1e9,true)||!N(p,"weather",0,3,true)||!N(p,"theme",0,1,true)||!N(p,"xp",0,1e9,true))return false;
            var tick=p.GetProperty("tick").GetDouble();
            var cells=d.GetProperty("cells"); if(!Array(cells,1,large?2304:400))return false;
            var positions=new HashSet<string>(); int arches=0,reeds=0;
            foreach(var c in cells.EnumerateArray()) {
                if(!Shape(c,"x y biome height moisture plants resources temperature detail meadow spring grove_until last_gift canopy_arch reed_shelter"))return false;
                if(!N(c,"x",-32,32,true)||!N(c,"y",-32,32,true)||!N(c,"biome",0,6,true)||!positions.Add($"{c.GetProperty("x").GetDouble()},{c.GetProperty("y").GetDouble()}"))return false;
                if(!N(c,"height",-1,2)||!N(c,"moisture",0,1)||!N(c,"plants",0,1)||!N(c,"resources",0,100)||!N(c,"temperature",-100,100)||!N(c,"detail",0,1)||!N(c,"grove_until",0,tick+120,true)||!N(c,"last_gift",-1,2,true))return false;
                foreach(var k in new[]{"meadow","spring","canopy_arch","reed_shelter"})if(!Bool(c.GetProperty(k)))return false;
                if(c.GetProperty("canopy_arch").GetBoolean())arches++; if(c.GetProperty("reed_shelter").GetBoolean())reeds++;
            }
            if(arches>1||reeds>1)return false;
            int last=cells.GetArrayLength()-1;
            var creatures=d.GetProperty("creatures");if(!Array(creatures,0,100))return false;int i=0;
            foreach(var c in creatures.EnumerateArray()) {
                if(!Shape(c,"id name species cell trait hunger phase recorded_at preferred trail companion rival silver parent parent_name lineage origin_cell migrant"))return false;
                if(!N(c,"id",i,i,true)||!T(c,"name",24,true)||!N(c,"species",0,5,true)||!N(c,"cell",0,last,true)||!new[]{"gardener","friendly","explorer","patient"}.Contains(c.GetProperty("trait").GetString()))return false;
                if(!N(c,"hunger",0,1)||!N(c,"phase",0,Math.Tau+.001)||!N(c,"recorded_at",0,tick,true)||!N(c,"preferred",0,5,true)||!Indices(c.GetProperty("trail"),32,last)||!Bool(c.GetProperty("silver"))||!T(c,"parent_name",24)||!N(c,"lineage",0,99,true)||!N(c,"origin_cell",0,last,true)||!Bool(c.GetProperty("migrant")))return false;
                foreach(var k in new[]{"companion","rival","parent"})if(!N(c,k,-1,creatures.GetArrayLength()-1,true)||c.GetProperty(k).GetDouble()==i)return false;
                i++;
            }
            var homes=d.GetProperty("settlements");if(!Array(homes,0,10))return false;var homeCells=new HashSet<int>();
            foreach(var h in homes.EnumerateArray()) {
                if(!Shape(h,"cell name custom population food stage tech landmark allies rival_cell trade_until")||!N(h,"cell",0,last,true)||!homeCells.Add((int)h.GetProperty("cell").GetDouble()))return false;
                if(!T(h,"name",24,true)||!new[]{"orchard","riverfolk","stargazers"}.Contains(h.GetProperty("custom").GetString())||!N(h,"population",0,80)||!N(h,"food",0,100)||!N(h,"stage",0,2,true)||!N(h,"tech",0,1e9)||!Bool(h.GetProperty("landmark"))||!Indices(h.GetProperty("allies"),10,last)||!N(h,"rival_cell",-1,last,true)||!N(h,"trade_until",0,tick+30,true))return false;
            }
            foreach(var h in homes.EnumerateArray()) {
                var cell=(int)h.GetProperty("cell").GetDouble();
                foreach(var a in h.GetProperty("allies").EnumerateArray())if(!homeCells.Contains((int)a.GetDouble())||(int)a.GetDouble()==cell)return false;
                var r=(int)h.GetProperty("rival_cell").GetDouble();if(r>=0&&(!homeCells.Contains(r)||r==cell))return false;
            }
            var memories=d.GetProperty("memories");if(!Array(memories,0,64))return false;
            foreach(var m in memories.EnumerateArray())if(!Shape(m,"key tick cell subject species biome plants identity")||!Memories.Split(' ').Contains(m.GetProperty("key").GetString())||!T(m,"subject",192)||!N(m,"tick",0,tick,true)||!N(m,"cell",0,last,true)||!N(m,"species",-1,5,true)||!N(m,"biome",0,6,true)||!N(m,"plants",0,1)||!N(m,"identity",-1,creatures.GetArrayLength()-1,true))return false;
            return Indices(d.GetProperty("discoveries"),6,5)&&Choices(d.GetProperty("secrets"),"mountain_spring silver_fox rainbow_choir",3)&&Choices(d.GetProperty("findings"),"rain_bloom friendship lantern_grove first_village",4);
        } catch(Exception e) when(e is InvalidOperationException or KeyNotFoundException or FormatException or OverflowException) {return false;}
    }
    public static int Score(JsonElement d)=>d.GetProperty("cells").EnumerateArray().Select(x=>(int)x.GetProperty("biome").GetDouble()).Distinct().Count()+d.GetProperty("secrets").GetArrayLength()*3+d.GetProperty("settlements").EnumerateArray().Count(x=>x.GetProperty("landmark").GetBoolean())*2;
    static readonly Dictionary<string,(string Category,bool Premium)> Cosmetics=JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory,"catalog.json"))).RootElement.EnumerateArray().ToDictionary(x=>x.GetProperty("id").GetString()!,x=>(x.GetProperty("category").GetString()!,x.GetProperty("premium").GetBoolean()));
    static bool Item(JsonElement e,string category)=>e.ValueKind==JsonValueKind.String&&Cosmetics.TryGetValue(e.GetString()!,out var item)&&!item.Premium&&item.Category==category;
    static bool Appearance(JsonElement a,int cells,int creatures) {
        if(!Shape(a,"theme sky frame placements coats")||!Item(a.GetProperty("theme"),"theme"))return false;
        foreach(var key in new[]{"sky","frame"})if(a.GetProperty(key).ValueKind!=JsonValueKind.String||(a.GetProperty(key).GetString()!=""&&!Item(a.GetProperty(key),key)))return false;
        var ps=a.GetProperty("placements");var cs=a.GetProperty("coats");if(!Array(ps,0,32)||!Array(cs,0,100))return false;
        var ids=new HashSet<int>();var positions=new HashSet<int>();
        foreach(var p in ps.EnumerateArray()) {
            if(!Shape(p,"id item cell rotation")||!N(p,"id",1,32,true)||!N(p,"cell",0,cells-1,true)||!N(p,"rotation",0,3,true)||(!Item(p.GetProperty("item"),"decor")&&!Item(p.GetProperty("item"),"settlement")))return false;
            if(!ids.Add((int)p.GetProperty("id").GetDouble())||!positions.Add((int)p.GetProperty("cell").GetDouble()))return false;
        }
        ids.Clear();
        foreach(var c in cs.EnumerateArray())if(!Shape(c,"id item")||!N(c,"id",0,creatures-1,true)||!Item(c.GetProperty("item"),"creature")||!ids.Add((int)c.GetProperty("id").GetDouble()))return false;
        return true;
    }
}
