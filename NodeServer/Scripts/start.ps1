Write-Host "Starting Node.js Docker environment..." -ForegroundColor Cyan

# Move to project root
Set-Location (Split-Path $PSScriptRoot -Parent)

# Build images if needed
docker compose build

# Start containers (creates containers & volumes if missing)
docker compose up -d

Write-Host "Node.js server is running!" -ForegroundColor Green
Write-Host "URL: http://localhost:3000"
