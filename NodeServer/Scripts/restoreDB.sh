#!/usr/bin/env bash
# Script pour restaurer une sauvegarde de la base de données CryptoCampus
set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Restauration de la base de données CryptoCampus ===${NC}"

# Charger les variables d'environnement
if [ -f ../.env ]; then
    source ../.env
else
    echo -e "${RED}❌ Fichier .env introuvable${NC}"
    exit 1
fi

# Déterminer le fichier SQL à utiliser
if [ -n "$1" ]; then
    SQL_FILE="$1"
elif [ -f "../Docker/PgAdmin/DB_Backup/CryptoCampus_latest.sql" ]; then
    SQL_FILE="../Docker/PgAdmin/DB_Backup/CryptoCampus_latest.sql"
    echo -e "${YELLOW}ℹ️  Utilisation de la dernière sauvegarde automatique${NC}"
else
    echo -e "${RED}❌ Aucun fichier SQL spécifié et pas de sauvegarde latest${NC}"
    echo -e "${YELLOW}Usage: ./restoreDB.sh [fichier.sql]${NC}"
    echo ""
    echo "Sauvegardes disponibles :"
    ls -lh ../Docker/PgAdmin/DB_Backup/*.sql 2>/dev/null || echo "  Aucune sauvegarde trouvée"
    exit 1
fi

# Vérifier que le fichier existe
if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}❌ Fichier SQL introuvable : $SQL_FILE${NC}"
    exit 1
fi

# Vérifier que le conteneur PostgreSQL est en cours d'exécution
if ! docker ps | grep -q postgres-database; then
    echo -e "${RED}❌ Le conteneur postgres-database n'est pas en cours d'exécution${NC}"
    echo "Démarrez-le avec : cd .. && docker-compose up -d db"
    exit 1
fi

echo -e "${YELLOW}📂 Fichier : $SQL_FILE${NC}"
echo -e "${YELLOW}🗄️  Base de données : $POSTGRES_DB${NC}"
echo ""
echo -e "${RED}⚠️  ATTENTION : Cette opération va SUPPRIMER toutes les données actuelles !${NC}"
read -p "Voulez-vous continuer ? (oui/non) : " -r
echo

if [[ ! $REPLY =~ ^[Oo][Uu][Ii]$ ]]; then
    echo -e "${YELLOW}❌ Restauration annulée${NC}"
    exit 0
fi

echo -e "${YELLOW}🔄 Restauration en cours...${NC}"

# Restaurer la base de données
cat "$SQL_FILE" | docker exec -i postgres-database \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

# Vérifier le résultat
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Base de données restaurée avec succès !${NC}"
else
    echo -e "${RED}❌ Erreur lors de la restauration${NC}"
    exit 1
fi
