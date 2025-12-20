Write-Host "Stopping Node.js Docker environment..." -ForegroundColor Yellow

# Move to project root
Set-Location (Split-Path $PSScriptRoot -Parent)

# Stop and remove containers
docker compose down --volumes

Write-Host "Containers and volumes removed." -ForegroundColor Green
