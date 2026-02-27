#!/usr/bin/env bash
set -euo pipefail

# Faz dump do banco MySQL do container db e salva em backups/
# Uso: ./scripts/backup-db.sh  (ou: make backup-db)

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

BACKUP_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP="$(date +"%Y-%m-%d-%H-%M")"
DUMP_FILE="${BACKUP_DIR}/db-backup-${TIMESTAMP}.sql"

mkdir -p "${BACKUP_DIR}"

echo "Fazendo backup do banco em ${DUMP_FILE}..."

docker compose exec -T db mysqldump -uroot -proot \
  --single-transaction --routines --triggers \
  drupal > "${DUMP_FILE}"

if [ ! -s "${DUMP_FILE}" ]; then
  echo "Erro: dump vazio ou falhou." >&2
  exit 1
fi

echo "Backup criado com sucesso: ${DUMP_FILE}"
