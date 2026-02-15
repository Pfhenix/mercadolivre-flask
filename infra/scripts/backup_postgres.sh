#!/usr/bin/env bash
set -euo pipefail

COCKPIT_DIR="${COCKPIT_DIR:-/opt/cockpit/app}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
DB_SERVICE="${DB_SERVICE:-db}"
DB_NAME="${DB_NAME:-postgres}"
DB_USER="${DB_USER:-postgres}"
BACKUP_DIR="${BACKUP_DIR:-/opt/cockpit/backups/postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

mkdir -p "${BACKUP_DIR}"
TIMESTAMP="$(date +%F_%H%M%S)"
OUT_FILE="${BACKUP_DIR}/pg_${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "Gerando backup do Postgres em ${OUT_FILE}"
cd "${COCKPIT_DIR}"
docker compose -f "${COMPOSE_FILE}" exec -T "${DB_SERVICE}" \
  pg_dump -U "${DB_USER}" "${DB_NAME}" | gzip > "${OUT_FILE}"

find "${BACKUP_DIR}" -type f -name '*.sql.gz' -mtime +"${RETENTION_DAYS}" -delete

echo "Backup concluído"
