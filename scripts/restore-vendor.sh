#!/usr/bin/env bash
set -euo pipefail

# Restaura a pasta vendor a partir de um backup em backups/
# Uso:
#   ./scripts/restore-vendor.sh                    # usa o vendor-backup-*.tar.gz mais recente
#   ./scripts/restore-vendor.sh arquivo.tar.gz     # usa o arquivo informado (relativo ou absoluto)

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VENDOR_DIR="${PROJECT_ROOT}/app/vendor"
BACKUP_DIR="${PROJECT_ROOT}/backups"

if [ ! -d "${BACKUP_DIR}" ]; then
  echo "Diretório de backups não encontrado: ${BACKUP_DIR}" >&2
  exit 1
fi

BACKUP_NAME="${1:-}"
BACKUP_FILE=""

if [ -n "${BACKUP_NAME}" ]; then
  # Se o usuário passou um nome, tentar primeiro relativo a BACKUP_DIR, depois caminho direto
  if [ -f "${BACKUP_DIR}/${BACKUP_NAME}" ]; then
    BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}"
  elif [ -f "${BACKUP_NAME}" ]; then
    BACKUP_FILE="${BACKUP_NAME}"
  else
    echo "Backup de vendor especificado não encontrado: ${BACKUP_NAME}" >&2
    exit 1
  fi
else
  # Caso contrário, usar o backup de vendor mais recente
  BACKUP_FILE="$(
    find "${BACKUP_DIR}" -maxdepth 1 -type f -name 'vendor-backup-*.tar.gz' -printf '%T@ %p\n' 2>/dev/null \
      | sort -n \
      | tail -n 1 \
      | awk '{print $2}'
  )"

  if [ -z "${BACKUP_FILE:-}" ]; then
    echo "Nenhum backup de vendor encontrado em ${BACKUP_DIR} (vendor-backup-*.tar.gz)" >&2
    exit 1
  fi
fi

echo "Restaurando vendor a partir de: ${BACKUP_FILE}"

if [ -d "${VENDOR_DIR}" ]; then
  echo "Removendo vendor atual em ${VENDOR_DIR}..."
  rm -rf "${VENDOR_DIR}"
fi

mkdir -p "${PROJECT_ROOT}/app"

# O backup foi criado com: tar -czf ... -C "${PROJECT_ROOT}/app" vendor
# Então extraímos relativo a app/
tar -xzf "${BACKUP_FILE}" -C "${PROJECT_ROOT}/app"

echo "Restore de vendor concluído em ${VENDOR_DIR}"

