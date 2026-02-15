#!/usr/bin/env bash
set -euo pipefail

# Preparação base da VPS para o Cockpit Multiagentes.
# Não sobrescreve arquivos sem backup explícito.

COCKPIT_DIR="${COCKPIT_DIR:-/opt/cockpit}"
REPO_SRC="${REPO_SRC:-$(pwd)}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml}"
ENV_EXAMPLE="${ENV_EXAMPLE:-.env.example}"
ENV_FILE="${ENV_FILE:-.env}"

log(){
  echo "[$(date +'%F %T')] $*"
}

require_root(){
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Erro: execute como root (ou com sudo)." >&2
    exit 1
  fi
}

ensure_dir_permissions(){
  log "Criando diretório ${COCKPIT_DIR} com permissões seguras"
  mkdir -p "${COCKPIT_DIR}"
  chown root:root "${COCKPIT_DIR}"
  chmod 750 "${COCKPIT_DIR}"
}

install_docker_if_needed(){
  if command -v docker >/dev/null 2>&1; then
    log "Docker já instalado: $(docker --version)"
  else
    log "Instalando Docker via script oficial"
    curl -fsSL https://get.docker.com | sh
  fi

  if docker compose version >/dev/null 2>&1; then
    log "Docker Compose plugin ok: $(docker compose version)"
  elif command -v docker-compose >/dev/null 2>&1; then
    log "docker-compose legado encontrado: $(docker-compose --version)"
  else
    echo "Erro: Docker Compose não encontrado após instalação." >&2
    exit 1
  fi

  systemctl enable --now docker
}

sync_repo(){
  log "Sincronizando monorepo para ${COCKPIT_DIR}/app"
  mkdir -p "${COCKPIT_DIR}/app"
  rsync -a --delete --exclude '.git' "${REPO_SRC}/" "${COCKPIT_DIR}/app/"
}

prepare_env(){
  local target_dir="${COCKPIT_DIR}/app"
  if [[ ! -f "${target_dir}/${ENV_EXAMPLE}" ]]; then
    log "Aviso: ${ENV_EXAMPLE} não encontrado. Etapa de .env ignorada."
    return 0
  fi

  if [[ -f "${target_dir}/${ENV_FILE}" ]]; then
    log "${ENV_FILE} já existe, mantendo sem alterações."
    return 0
  fi

  log "Criando ${ENV_FILE} a partir de ${ENV_EXAMPLE} (sem preencher segredos)"
  cp "${target_dir}/${ENV_EXAMPLE}" "${target_dir}/${ENV_FILE}"
  chmod 640 "${target_dir}/${ENV_FILE}"
  log "Preencha segredos manualmente antes de subir o stack."
}

main(){
  require_root
  ensure_dir_permissions
  install_docker_if_needed
  sync_repo
  prepare_env
  log "Bootstrap finalizado. Próximo passo: docker compose up -d"
}

main "$@"
