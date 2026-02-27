#!/usr/bin/env bash
set -euo pipefail

# Faz backup da pasta vendor em backups/
# Uso: ./scripts/backup-vendor.sh  (ou: make backup-vendor)

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VENDOR_DIR="${PROJECT_ROOT}/app/vendor"
BACKUP_DIR="${PROJECT_ROOT}/backups"

if [ ! -d "${VENDOR_DIR}" ]; then
  echo "Diretório vendor não encontrado: ${VENDOR_DIR}" >&2
  exit 1
fi

mkdir -p "${BACKUP_DIR}"

# Permite reutilizar um timestamp externo (por exemplo, via backup-all.sh)
TIMESTAMP="${TIMESTAMP:-$(date +"%Y-%m-%d-%H-%M-%S")}"
BACKUP_FILE="${BACKUP_DIR}/vendor-backup-${TIMESTAMP}.tar.gz"

echo "Gerando backup de ${VENDOR_DIR} em ${BACKUP_FILE}..."

# Arquiva a pasta 'vendor' preservando estrutura relativa a partir de app
tar -czf "${BACKUP_FILE}" -C "${PROJECT_ROOT}/app" vendor

echo "Backup de vendor criado com sucesso: ${BACKUP_FILE}"

