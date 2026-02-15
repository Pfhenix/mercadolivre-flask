#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${SOURCE_DIR:-/opt/cockpit/app/storage}"
BACKUP_DIR="${BACKUP_DIR:-/opt/cockpit/backups/storage}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

mkdir -p "${BACKUP_DIR}"
TIMESTAMP="$(date +%F_%H%M%S)"
ARCHIVE="${BACKUP_DIR}/storage_${TIMESTAMP}.tar.gz"

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Erro: diretório de storage não encontrado em ${SOURCE_DIR}" >&2
  exit 1
fi

echo "Compactando ${SOURCE_DIR} em ${ARCHIVE}"
tar -C "$(dirname "${SOURCE_DIR}")" -czf "${ARCHIVE}" "$(basename "${SOURCE_DIR}")"

find "${BACKUP_DIR}" -type f -name 'storage_*.tar.gz' -mtime +"${RETENTION_DAYS}" -delete

echo "Backup de storage concluído"
