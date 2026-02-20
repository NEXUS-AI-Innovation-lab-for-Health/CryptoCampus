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
    # 1. Utiliser le fichier passé en argument
    SQL_FILE="$1"
    echo -e "${YELLOW}ℹ️  Utilisation du fichier spécifié en argument${NC}"
elif [ -n "$SQL_FILE" ] && [ -f "$SQL_FILE" ]; then
    # 2. Utiliser le fichier spécifié dans .env
    echo -e "${YELLOW}ℹ️  Utilisation du fichier spécifié dans .env : $SQL_FILE${NC}"
elif [ -f "../Docker/PgAdmin/DB_Backup/CryptoCampus_latest.sql" ]; then
    # 3. Utiliser la sauvegarde latest par défaut
    SQL_FILE="../Docker/PgAdmin/DB_Backup/CryptoCampus_latest.sql"
    echo -e "${YELLOW}ℹ️  Utilisation de la dernière sauvegarde automatique${NC}"
else
    echo -e "${RED}❌ Aucun fichier SQL valide trouvé${NC}"
    echo -e "${YELLOW}Usage: ./restoreDB.sh [fichier.sql]${NC}"
    echo -e "${YELLOW}   ou: définir SQL_FILE dans le fichier .env${NC}"
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

# Créer le dossier de logs s'il n'existe pas
LOG_DIR="../Docker/PgAdmin/Logs"
mkdir -p "$LOG_DIR"

# Nom du fichier log avec timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/restore_${TIMESTAMP}.log"

echo -e "${YELLOW}🔄 Restauration en cours...${NC}"
echo -e "${YELLOW}📝 Les logs sont écrits dans : $LOG_FILE${NC}"

# Restaurer la base de données et rediriger tous les logs vers le fichier
cat "$SQL_FILE" | docker exec -i postgres-database \
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$LOG_FILE" 2>&1

# Vérifier le résultat
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Base de données restaurée avec succès !${NC}"
    echo -e "${GREEN}📝 Logs disponibles dans : $LOG_FILE${NC}"
else
    echo -e "${RED}❌ Erreur lors de la restauration${NC}"
    echo -e "${RED}📝 Consultez les logs : $LOG_FILE${NC}"
    exit 1
fi
