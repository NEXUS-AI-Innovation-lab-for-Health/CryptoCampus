# Script de démarrage rapide pour le système d'annonces

Write-Host "🚀 Démarrage du système d'annonces d'aide aux devoirs..." -ForegroundColor Cyan
Write-Host ""

# 1. Démarrer les conteneurs
Write-Host "📦 Démarrage des conteneurs Docker..." -ForegroundColor Yellow
docker-compose up -d

Start-Sleep -Seconds 5

# 2. Installer les dépendances
Write-Host ""
Write-Host "📥 Installation des dépendances NPM..." -ForegroundColor Yellow
docker exec -it api_crypto npm install

# 3. Peupler Qdrant
Write-Host ""
Write-Host "🌱 Peuplement de Qdrant avec des annonces de test..." -ForegroundColor Yellow
docker exec -it api_crypto npm run seed

# 4. Instructions finales
Write-Host ""
Write-Host "✅ SYSTÈME PRÊT !" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Accédez à la page de test :" -ForegroundColor Cyan
Write-Host "   http://localhost:81/test-listings.html" -ForegroundColor White
Write-Host ""
Write-Host "📊 Autres services :" -ForegroundColor Cyan
Write-Host "   - API: http://localhost:81" -ForegroundColor White
Write-Host "   - Qdrant Dashboard: http://localhost:6333/dashboard" -ForegroundColor White
Write-Host "   - pgAdmin: http://localhost:5050" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Exemples de recherches :" -ForegroundColor Cyan
Write-Host "   - mathématiques lycée" -ForegroundColor White
Write-Host "   - anglais conversation" -ForegroundColor White
Write-Host "   - programmation python" -ForegroundColor White
Write-Host "   - préparation bac" -ForegroundColor White
Write-Host ""
