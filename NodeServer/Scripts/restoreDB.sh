#!/usr/bin/env bash
set -e

DB_HOST="postgres-database"
DB_NAME="CryptoCampus"
DB_USER="onlycode-admin"
DB_PASSWORD="Zongo94"
SQL_FILE="../Docker/PgAdmin/DB_Backup/CryptoCampus.sql"

docker exec -i -e PGPASSWORD="$DB_PASSWORD" postgres-database \
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -q < "$SQL_FILE"
