#!/usr/bin/env bash
set -euo pipefail

# Diretório raiz do projeto (pasta onde está o docker-compose.yml)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BACKUP_DIR="${PROJECT_ROOT}/backups"
WEB_ROOT="${PROJECT_ROOT}/app/web"
SITES_DIR="${WEB_ROOT}/sites"

if [ ! -d "${BACKUP_DIR}" ]; then
  echo "Diretório de backups não encontrado: ${BACKUP_DIR}" >&2
  exit 1
fi

if [ ! -d "${WEB_ROOT}" ]; then
  echo "Diretório web não encontrado: ${WEB_ROOT}" >&2
  exit 1
fi

BACKUP_NAME="${1:-}"
BACKUP_FILE=""

if [ -n "${BACKUP_NAME}" ]; then
  # Se o usuário passou um nome, usar exatamente esse arquivo (relativo ao BACKUP_DIR)
  if [ -f "${BACKUP_DIR}/${BACKUP_NAME}" ]; then
    BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}"
  elif [ -f "${BACKUP_NAME}" ]; then
    BACKUP_FILE="${BACKUP_NAME}"
  else
    echo "Backup especificado não encontrado: ${BACKUP_NAME}" >&2
    exit 1
  fi
else
  # Caso contrário, usar o backup mais recente
  BACKUP_FILE="$(
    find "${BACKUP_DIR}" -maxdepth 1 -type f -name 'backup-*.tar.gz' -printf '%T@ %p\n' 2>/dev/null \
      | sort -n \
      | tail -n 1 \
      | awk '{print $2}'
  )"

  if [ -z "${BACKUP_FILE:-}" ]; then
    echo "Nenhum backup encontrado em ${BACKUP_DIR}" >&2
    exit 1
  fi
fi

echo "Restaurando backup: ${BACKUP_FILE}"

if [ -d "${SITES_DIR}" ]; then
  echo "Removendo conteúdo atual de ${SITES_DIR}..."
  rm -rf "${SITES_DIR}"
fi

mkdir -p "${WEB_ROOT}"

# O backup foi criado com -C app/web sites, então extraímos em app/web
tar -xzf "${BACKUP_FILE}" -C "${WEB_ROOT}"

echo "Restore concluído em ${SITES_DIR}"

