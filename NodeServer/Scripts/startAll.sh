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

echo "Build de l'image sans cache..."
docker compose build --no-cache

echo "Lancement de l'ensemble de l'application."
docker compose up -d

echo "------------------------------------------------------"
echo "Serveur Node disponible à l'url : http://127.0.0.1:80"
echo "API CryptoCampus disponible à l'url : http://127.0.0.1:81"
echo "Database PostgreSQL démarrée sur le port 5432"
echo "PgAdmin disponible à l'url : http://127.0.0.1:5050"
echo "------------------------------------------------------"

echo "Restoration de la database..."
cd ./Scripts
./restoreDB.sh
echo "Restoration de la database terminée."
