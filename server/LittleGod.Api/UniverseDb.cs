using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace LittleGod.Api;

public sealed class Player : IdentityUser { }
public sealed class Profile {
    public string PlayerId { get; set; } = "";
    public Player Player { get; set; } = null!;
    public string Code { get; set; } = Guid.NewGuid().ToString("N");
    public string Name { get; set; } = "Little guardian";
    public int Avatar { get; set; }
    public string Visibility { get; set; } = "private";
}
// A single canonical pair has one state and one original sender: no opposing requests.
public sealed class Connection {
    public string Low { get; set; } = "";
    public string High { get; set; } = "";
    public string Sender { get; set; } = "";
    public string State { get; set; } = "pending";
    public Player LowPlayer { get; set; } = null!;
    public Player HighPlayer { get; set; } = null!;
}
public sealed class Block {
    public string Owner { get; set; } = "";
    public string Target { get; set; } = "";
    public Player OwnerPlayer { get; set; } = null!;
    public Player TargetPlayer { get; set; } = null!;
}
public sealed class Showcase {
    public string Owner { get; set; } = "";
    public Player Player { get; set; } = null!;
    public string Visibility { get; set; } = "friends";
    public int Revision { get; set; }
    public DateTimeOffset Updated { get; set; }
    public List<ShowcaseVersion> Versions { get; set; } = [];
}
public sealed class ShowcaseVersion {
    public string Owner { get; set; } = "";
    public Showcase Showcase { get; set; } = null!;
    public int Revision { get; set; }
    public string Document { get; set; } = "";
    public string Hash { get; set; } = "";
    public int Score { get; set; }
}
public sealed class Reaction {
    public string Owner { get; set; } = "";
    public string Sender { get; set; } = "";
    public int Kind { get; set; }
    public Player OwnerPlayer { get; set; } = null!;
    public Player SenderPlayer { get; set; } = null!;
}
public sealed class Activity {
    public long Id { get; set; }
    public string Recipient { get; set; } = "";
    public string Actor { get; set; } = "";
    public string Kind { get; set; } = "";
    public bool Read { get; set; }
    public DateTimeOffset Created { get; set; } = DateTimeOffset.UtcNow;
    public Player RecipientPlayer { get; set; } = null!;
    public Player ActorPlayer { get; set; } = null!;
}
public sealed class UniverseDb(DbContextOptions<UniverseDb> options) : IdentityDbContext<Player>(options) {
    public DbSet<Profile> Profiles => Set<Profile>();
    public DbSet<Connection> Connections => Set<Connection>();
    public DbSet<Block> Blocks => Set<Block>();
    public DbSet<Showcase> Showcases => Set<Showcase>();
    public DbSet<ShowcaseVersion> Versions => Set<ShowcaseVersion>();
    public DbSet<Reaction> Reactions => Set<Reaction>();
    public DbSet<Activity> Activities => Set<Activity>();
    protected override void OnModelCreating(ModelBuilder b) {
        base.OnModelCreating(b);
        b.Entity<RealmReward>().HasKey(r=>r.Id);
        b.Entity<RealmCharacter>().HasKey(c=>c.Id);
        b.Entity<RealmCharacter>().HasIndex(c=>new{c.Owner,c.Realm}).IsUnique();
        b.Entity<RealmCharacter>().HasIndex(c=>new{c.Realm,c.NameKey}).IsUnique();
        b.Entity<RealmCharacter>().Property(c=>c.Name).HasMaxLength(24);
        b.Entity<RealmCharacter>().Property(c=>c.NameKey).HasMaxLength(48);
        b.Entity<RealmCharacter>().HasOne(c=>c.Player).WithMany().HasForeignKey(c=>c.Owner).OnDelete(DeleteBehavior.Cascade);
        b.Entity<RealmTicket>().HasKey(t=>t.Hash);
        b.Entity<RealmTicket>().HasIndex(t=>t.Expires);
        b.Entity<RealmTicket>().HasOne(t=>t.Character).WithMany().HasForeignKey(t=>t.CharacterId).OnDelete(DeleteBehavior.Cascade);
        b.Entity<ChatMessage>().HasKey(x=>x.Id);
        b.Entity<ChatMessage>().Property(x=>x.Text).HasMaxLength(300);
        b.Entity<ChatMessage>().HasIndex(x=>new{x.Sender,x.Created});
        b.Entity<ChatMessage>().HasIndex(x=>new{x.Recipient,x.Id});
        b.Entity<ChatReport>().HasKey(x=>x.Id);
        b.Entity<ChatReport>().HasIndex(x=>new{x.Reporter,x.MessageId}).IsUnique();
        b.Entity<ChatReport>().Property(x=>x.Text).HasMaxLength(300);
        b.Entity<ChatReport>().Property(x=>x.Reason).HasMaxLength(300);
        b.Entity<PurchaseReceipt>().HasKey(x=>new{x.Store,x.Transaction});
        b.Entity<PurchaseReceipt>().Property(x=>x.Transaction).HasMaxLength(256);
        b.Entity<PurchaseReceipt>().Property(x=>x.State).IsConcurrencyToken();
        b.Entity<PurchaseReceipt>().HasOne(x=>x.Player).WithMany().HasForeignKey(x=>x.Owner).OnDelete(DeleteBehavior.Cascade);
        b.Entity<PurchaseReceipt>().HasIndex(x=>new{x.Owner,x.State});
        b.Entity<PurchaseReceipt>().ToTable(t=>t.HasCheckConstraint("CK_PurchaseState","\"State\" IN ('pending','completed','cancelled','failed','revoked')"));
        b.Entity<Profile>().HasKey(x=>x.PlayerId);
        b.Entity<Profile>().HasIndex(x=>x.Code).IsUnique();
        b.Entity<Profile>().Property(x=>x.Name).HasMaxLength(32);
        b.Entity<Profile>().HasOne(x=>x.Player).WithOne().HasForeignKey<Profile>(x=>x.PlayerId).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Connection>().HasKey(x=>new{x.Low,x.High});
        b.Entity<Connection>().ToTable(t=>t.HasCheckConstraint("CK_Connection", "\"Low\" < \"High\" AND \"Sender\" IN (\"Low\", \"High\") AND \"State\" IN ('pending','accepted')"));
        b.Entity<Connection>().HasOne(x=>x.LowPlayer).WithMany().HasForeignKey(x=>x.Low).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Connection>().HasOne(x=>x.HighPlayer).WithMany().HasForeignKey(x=>x.High).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Block>().HasKey(x=>new{x.Owner,x.Target});
        b.Entity<Block>().HasOne(x=>x.OwnerPlayer).WithMany().HasForeignKey(x=>x.Owner).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Block>().HasOne(x=>x.TargetPlayer).WithMany().HasForeignKey(x=>x.Target).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Showcase>().HasKey(x=>x.Owner);
        b.Entity<Showcase>().HasOne(x=>x.Player).WithOne().HasForeignKey<Showcase>(x=>x.Owner).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Showcase>().HasIndex(x=>new{x.Visibility,x.Updated});
        b.Entity<ShowcaseVersion>().HasKey(x=>new{x.Owner,x.Revision});
        b.Entity<ShowcaseVersion>().Property(x=>x.Document).HasColumnType("jsonb");
        b.Entity<ShowcaseVersion>().HasOne(x=>x.Showcase).WithMany(x=>x.Versions).HasForeignKey(x=>x.Owner).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Reaction>().HasKey(x=>new{x.Owner,x.Sender});
        b.Entity<Reaction>().HasOne(x=>x.OwnerPlayer).WithMany().HasForeignKey(x=>x.Owner).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Reaction>().HasOne(x=>x.SenderPlayer).WithMany().HasForeignKey(x=>x.Sender).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Activity>().HasIndex(x=>new{x.Recipient,x.Id});
        b.Entity<Activity>().HasOne(x=>x.RecipientPlayer).WithMany().HasForeignKey(x=>x.Recipient).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Activity>().HasOne(x=>x.ActorPlayer).WithMany().HasForeignKey(x=>x.Actor).OnDelete(DeleteBehavior.Cascade);
    }
}
