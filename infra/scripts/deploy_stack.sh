#!/usr/bin/env bash
set -euo pipefail

COCKPIT_DIR="${COCKPIT_DIR:-/opt/cockpit/app}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"

log(){
  echo "[$(date +'%F %T')] $*"
}

cd "${COCKPIT_DIR}"

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "Erro: ${COMPOSE_FILE} não encontrado em ${COCKPIT_DIR}." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Erro: .env ausente. Crie a partir do .env.example antes do deploy." >&2
  exit 1
fi

log "Validando arquivo compose"
docker compose -f "${COMPOSE_FILE}" config >/dev/null

log "Baixando/atualizando imagens"
docker compose -f "${COMPOSE_FILE}" pull

log "Subindo stack"
docker compose -f "${COMPOSE_FILE}" up -d --remove-orphans

log "Serviços ativos"
docker compose -f "${COMPOSE_FILE}" ps
