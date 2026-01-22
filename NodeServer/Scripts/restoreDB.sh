#!/usr/bin/env bash
set -e
source ../.env

docker exec -i -e PGPASSWORD="$DB_PASSWORD" postgres-database \
    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -q < "$SQL_FILE"
