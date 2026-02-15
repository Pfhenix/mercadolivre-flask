#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="${TMP_DIR:-/opt/cockpit/app/tmp}"
OLDER_THAN_DAYS="${OLDER_THAN_DAYS:-3}"

if [[ ! -d "${TMP_DIR}" ]]; then
  echo "Aviso: ${TMP_DIR} não existe, nada para limpar."
  exit 0
fi

echo "Limpando arquivos temporários em ${TMP_DIR} com mais de ${OLDER_THAN_DAYS} dias"
find "${TMP_DIR}" -type f -mtime +"${OLDER_THAN_DAYS}" -print -delete
