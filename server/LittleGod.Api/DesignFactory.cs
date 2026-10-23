using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
namespace LittleGod.Api;
public class DesignFactory : IDesignTimeDbContextFactory<UniverseDb> {
    public UniverseDb CreateDbContext(string[] args)=>new(new DbContextOptionsBuilder<UniverseDb>().UseNpgsql("Host=127.0.0.1;Database=littlegod_design").Options);
}
