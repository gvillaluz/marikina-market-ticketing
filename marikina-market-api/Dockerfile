# Server package: the .NET server plus PostgreSQL 18's pg_dump, which the Backups page runs.
# Build from the marikina-market-api folder:  docker build -t marikina-market-api .
# No secrets are inside: settings (database, JWT, Firebase, B2, email) are given when the package runs.

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY MarikinaMarket.API/MarikinaMarket.API.csproj MarikinaMarket.API/
RUN dotnet restore MarikinaMarket.API/MarikinaMarket.API.csproj
COPY MarikinaMarket.API/ MarikinaMarket.API/
RUN dotnet publish MarikinaMarket.API/MarikinaMarket.API.csproj --configuration Release --output /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0
# pg_dump 18 from PostgreSQL's own package site (Ubuntu 24.04 itself only offers version 16).
# pg_dump must be the database's major version or newer.
ADD --chmod=644 https://www.postgresql.org/media/keys/ACCC4CF8.asc /usr/share/keyrings/postgresql.asc
RUN echo "deb [signed-by=/usr/share/keyrings/postgresql.asc] https://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
        > /etc/apt/sources.list.d/postgresql.list \
    && apt-get update \
    && apt-get install --yes --no-install-recommends postgresql-client-18 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "MarikinaMarket.API.dll"]
