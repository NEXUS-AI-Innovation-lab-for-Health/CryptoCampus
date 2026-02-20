#!/usr/bin/env bash
# Script pour faire un dump complet de la base de données CryptoCampus
set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Dump de la base de données CryptoCampus ===${NC}"

# Charger les variables d'environnement
if [ -f ../.env ]; then
    source ../.env
else
    echo -e "${RED}❌ Fichier .env introuvable${NC}"
    exit 1
fi

# Vérifier que le conteneur PostgreSQL est en cours d'exécution
if ! docker ps | grep -q postgres-database; then
    echo -e "${RED}❌ Le conteneur postgres-database n'est pas en cours d'exécution${NC}"
    echo "Démarrez-le avec : cd .. && docker-compose up -d db"
    exit 1
fi

# Créer le dossier de backup s'il n'existe pas
BACKUP_DIR="../Docker/PgAdmin/DB_Backup"
mkdir -p "$BACKUP_DIR"

# Nom du fichier de backup
BACKUP_FILE="$BACKUP_DIR/CryptoCampus_latest.sql"

echo -e "${YELLOW}📦 Création du dump (Format: Plain)...${NC}"

# Effectuer le dump avec les paramètres spécifiés
# Format: Plain (format par défaut)
# Options: --clean --if-exists pour un dump complet
docker exec postgres-database pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    --format=plain \
    --clean \
    --if-exists \
    --verbose > "$BACKUP_FILE" 2>&1

# Vérifier que le dump a réussi
if [ $? -eq 0 ]; then
    FILESIZE=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
    echo -e "${GREEN}✅ Dump créé avec succès !${NC}"
    echo -e "${GREEN}📁 Fichier : $BACKUP_FILE${NC}"
    echo -e "${GREEN}📏 Taille  : $FILESIZE${NC}"
    echo ""
    echo -e "${GREEN}💡 Pour restaurer cette sauvegarde :${NC}"
    echo -e "   ${YELLOW}./restoreDB.sh $BACKUP_FILE${NC}"
else
    echo -e "${RED}❌ Erreur lors de la création du dump${NC}"
    exit 1
fi
