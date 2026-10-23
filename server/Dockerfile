FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY server/LittleGod.Api/ server/LittleGod.Api/
COPY assets/cosmetics/catalog.json assets/cosmetics/catalog.json
RUN dotnet publish server/LittleGod.Api -c Release -o /out
FROM mcr.microsoft.com/dotnet/aspnet:10.0
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN mkdir /keys && chown app /keys
COPY --from=build /out .
USER app
ENTRYPOINT ["dotnet", "LittleGod.Api.dll"]
