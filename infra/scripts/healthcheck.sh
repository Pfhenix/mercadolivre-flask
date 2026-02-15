#!/usr/bin/env bash
set -euo pipefail

COCKPIT_DIR="${COCKPIT_DIR:-/opt/cockpit/app}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
API_HEALTH_URL="${API_HEALTH_URL:-http://localhost:8000/health}"
PANEL_URL="${PANEL_URL:-http://localhost:3000}"
DB_SERVICE="${DB_SERVICE:-db}"
REDIS_SERVICE="${REDIS_SERVICE:-redis}"

log(){
  echo "[$(date +'%F %T')] $*"
}

cd "${COCKPIT_DIR}"

log "Teste API health: ${API_HEALTH_URL}"
curl -fsS "${API_HEALTH_URL}" >/dev/null

log "Teste painel: ${PANEL_URL}"
curl -fsS "${PANEL_URL}" >/dev/null

log "Teste Redis (${REDIS_SERVICE})"
docker compose -f "${COMPOSE_FILE}" exec -T "${REDIS_SERVICE}" redis-cli ping | grep -q PONG

log "Teste Postgres (${DB_SERVICE})"
docker compose -f "${COMPOSE_FILE}" exec -T "${DB_SERVICE}" pg_isready >/dev/null

log "Health-check concluído com sucesso"
