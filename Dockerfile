# Multi-stage build for framework-dependent application
# Stage 1: Build the application
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files and restore
COPY NugetCacheMcp/*.csproj NugetCacheMcp/
RUN dotnet restore NugetCacheMcp/NuGetCacheMcp.csproj -r linux-musl-x64

# Copy source and publish
COPY NugetCacheMcp/ NugetCacheMcp/
RUN dotnet publish NugetCacheMcp/NuGetCacheMcp.csproj \
    -c Release \
    -r linux-musl-x64 \
    --self-contained false \
    -o /app \
    --no-restore

# Stage 2: Create runtime image
# Using runtime for framework-dependent apps (requires .NET runtime)
FROM mcr.microsoft.com/dotnet/runtime:10.0-alpine AS runtime

# Create non-root user for security
RUN adduser -D -u 1000 appuser

WORKDIR /app

# Copy the framework-dependent executable
COPY --from=build /app/NuGetCacheMcp .

# Set ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# The MCP server communicates via stdio, so no port exposure needed
# Environment variable to configure NuGet cache path (mounted at runtime)
ENV NUGET_CACHE_PATH=/nuget-cache

# Health check is not applicable for stdio-based MCP servers

ENTRYPOINT ["./NuGetCacheMcp"]
