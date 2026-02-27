#!/usr/bin/env bash
set -euo pipefail

# Faz backup da base de dados Drupal na pasta backups,
# com nome padrão db-backup-yyyy-mm-dd-hh-mm.sql
# Uso: ./scripts/backup-db.sh  (ou via alvo equivalente no Makefile)

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${PROJECT_ROOT}"

BACKUP_DIR="${PROJECT_ROOT}/backups"
mkdir -p "${BACKUP_DIR}"

# Permite reutilizar um timestamp externo (por exemplo, via backup-all.sh)
TIMESTAMP="${TIMESTAMP:-$(date +"%Y-%m-%d-%H-%M-%S")}"
BACKUP_FILE="${BACKUP_DIR}/db-backup-${TIMESTAMP}.sql"

echo "Gerando backup da base de dados Drupal em ${BACKUP_FILE}..."

docker compose exec db mysqldump --no-tablespaces -u drupal -pdrupal drupal > "${BACKUP_FILE}"

echo "Backup da base de dados concluído com sucesso."

