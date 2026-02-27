#!/usr/bin/env bash
set -euo pipefail

# Diretório raiz do projeto (pasta onde está o docker-compose.yml)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SITES_DIR="${PROJECT_ROOT}/app/web/sites"
BACKUP_DIR="${PROJECT_ROOT}/backups"

if [ ! -d "${SITES_DIR}" ]; then
  echo "Diretório de sites não encontrado: ${SITES_DIR}" >&2
  exit 1
fi

mkdir -p "${BACKUP_DIR}"

# Permite reutilizar um timestamp externo (por exemplo, via backup-all.sh)
TIMESTAMP="${TIMESTAMP:-$(date +"%Y-%m-%d-%H-%M-%S")}"
BACKUP_FILE="${BACKUP_DIR}/sites-backup-${TIMESTAMP}.tar.gz"

echo "Gerando backup de ${SITES_DIR} em ${BACKUP_FILE}..."

# Arquiva a pasta 'sites' preservando estrutura relativa a partir de app/web
tar -czf "${BACKUP_FILE}" -C "${PROJECT_ROOT}/app/web" sites

echo "Backup criado com sucesso: ${BACKUP_FILE}"

