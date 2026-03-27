#!/bin/bash

SERVICE_NAME="frontend"
FRONT_PATH="/app/Application/Frontend"

echo "Build Vue.js dans le service ${SERVICE_NAME}..."

docker compose exec ${SERVICE_NAME} sh -c "
  cd ${FRONT_PATH} &&
  npm install &&
  npm run build
"

if [ $? -eq 0 ]; then
  echo "Build terminé avec succès"
else
  echo "Erreur pendant le build"
  exit 1
fi
