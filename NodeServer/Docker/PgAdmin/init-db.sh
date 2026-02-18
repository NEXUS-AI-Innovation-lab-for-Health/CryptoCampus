#!/usr/bin/env bash
# Script d'initialisation automatique de la base de données CryptoCampus
# Ce script est exécuté automatiquement au premier démarrage du conteneur PostgreSQL
set -e

echo "🚀 Initialisation de la base de données CryptoCampus..."

# Attendre que PostgreSQL soit prêt
until pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
    echo "⏳ Attente de PostgreSQL..."
    sleep 2
done

echo "✅ PostgreSQL est prêt"

# Vérifier si la base est déjà initialisée (vérifier si la table users existe)
TABLE_EXISTS=$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='users');")

if [ "$TABLE_EXISTS" = "t" ]; then
    echo "ℹ️  Base de données déjà initialisée, rien à faire"
    exit 0
fi

echo "📦 Création des tables initiales..."

# Si un fichier de sauvegarde latest existe, l'utiliser
if [ -f "/docker-entrypoint-initdb.d/CryptoCampus_latest.sql" ]; then
    echo "🔄 Restauration depuis la dernière sauvegarde..."
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < /docker-entrypoint-initdb.d/CryptoCampus_latest.sql
    echo "✅ Base de données restaurée depuis la sauvegarde"
else
    echo "⚠️  Pas de sauvegarde trouvée, initialisation manuelle requise"
    echo "💡 Utilisez le script restoreDB.sh pour restaurer une sauvegarde"
fi

echo "🎉 Initialisation terminée !"
