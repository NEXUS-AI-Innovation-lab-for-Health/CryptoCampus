#!/usr/bin/env bash
set -e

# Dossier où se trouve ce script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Dossier contenant docker-compose.yml
COMPOSE_DIR="$SCRIPT_DIR/../"

export COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

cd "$COMPOSE_DIR"

echo "Arrêt et nettoyage de l'ensemble de l'application."
docker compose down -v

echo "Build de l'application Frontend..."
cd ./Scripts
./buildVueApp.sh
cd "$COMPOSE_DIR"

echo "Build de l'image sans cache..."
docker compose build --no-cache

echo "Lancement de l'ensemble de l'application."
docker compose up -d

echo "Restoration de la database..."
cd ./Scripts
./restoreDB.sh
echo "Restoration de la database terminée."

echo "------------------------------------------------------"
echo "✅ Application CryptoCampus démarrée avec succès !"
echo ""
echo "Frontend + API unifiés : http://127.0.0.1:80"
echo "  - Interface web       : http://127.0.0.1:80"
echo "  - API REST            : http://127.0.0.1:80/api/"
echo "  - Agenda              : http://127.0.0.1:80/agenda"
echo ""
echo "Services disponibles :"
echo "  - PostgreSQL          : localhost:5432"
echo "  - PgAdmin             : http://127.0.0.1:5050"
echo "  - Qdrant Vector DB    : http://127.0.0.1:6333"
echo "  - Ganache Blockchain  : http://127.0.0.1:8545"
echo "------------------------------------------------------"