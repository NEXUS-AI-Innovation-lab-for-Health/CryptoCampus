#!/bin/bash

SERVICE_NAME="frontend"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="${SCRIPT_DIR}/.."

echo "Rebuild de l'image et redémarrage du service ${SERVICE_NAME}..."

# Le conteneur frontend est une image nginx multi-stage : le code Vue est
# buildé pendant la construction de l'image (cf. Dockerfile), il n'y a pas
# de sources/node_modules dans le conteneur final. On reconstruit donc
# l'image puis on redémarre le conteneur.
docker compose -f "${COMPOSE_DIR}/docker-compose.yml" up -d --build ${SERVICE_NAME}

if [ $? -eq 0 ]; then
  echo "Frontend reconstruit et redémarré avec succès"
else
  echo "Erreur pendant le rebuild du frontend"
  exit 1
fi
