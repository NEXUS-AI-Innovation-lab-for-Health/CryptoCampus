#!/usr/bin/env bash
set -e

# Dossier où se trouve ce script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Dossier contenant docker-compose.yml
COMPOSE_DIR="$SCRIPT_DIR/../"

cd "$COMPOSE_DIR"

echo "Arrêt rapide de l'ensemble de l'application."
docker compose down

echo "Lancement rapide de l'ensemble de l'application."
docker compose up -d

echo "------------------------------------------------------"
echo "✅ Application CryptoCampus démarrée !"
echo "Frontend + API : http://127.0.0.1:80"
echo "------------------------------------------------------"
