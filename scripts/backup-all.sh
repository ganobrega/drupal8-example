#!/usr/bin/env bash
set -euo pipefail

# Faz backup da base de dados, sites e vendor usando o MESMO timestamp.
# Uso: ./scripts/backup-all.sh  (ou: make backup)

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${PROJECT_ROOT}"

BACKUP_DIR="${PROJECT_ROOT}/backups"
mkdir -p "${BACKUP_DIR}"

TIMESTAMP="$(date +"%Y-%m-%d-%H-%M-%S")"

echo "Iniciando backup completo com timestamp ${TIMESTAMP}..."

export TIMESTAMP

chmod +x "${PROJECT_ROOT}/scripts/backup-sites.sh"
chmod +x "${PROJECT_ROOT}/scripts/backup-db.sh"
chmod +x "${PROJECT_ROOT}/scripts/backup-vendor.sh"

"${PROJECT_ROOT}/scripts/backup-sites.sh"
"${PROJECT_ROOT}/scripts/backup-db.sh"
"${PROJECT_ROOT}/scripts/backup-vendor.sh"

echo "Backup completo finalizado com sucesso. Arquivos em ${BACKUP_DIR} usando timestamp ${TIMESTAMP}."

