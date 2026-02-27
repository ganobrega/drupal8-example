#!/usr/bin/env bash
set -euo pipefail

# Restaura o banco MySQL dentro do container "db" a partir de um dump .sql
# Uso:
#   ./scripts/restore-db.sh               # usa o db-backup-*.sql mais recente em backups/
#   ./scripts/restore-db.sh caminho.sql   # usa o arquivo informado (relativo ou absoluto)

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

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
    echo "Dump de banco especificado não encontrado: ${BACKUP_NAME}" >&2
    exit 1
  fi
else
  # Caso contrário, usar o dump de banco mais recente
  BACKUP_FILE="$(
    find "${BACKUP_DIR}" -maxdepth 1 -type f -name 'db-backup-*.sql' -printf '%T@ %p\n' 2>/dev/null \
      | sort -n \
      | tail -n 1 \
      | awk '{print $2}'
  )"

  if [ -z "${BACKUP_FILE:-}" ]; then
    echo "Nenhum dump de banco encontrado em ${BACKUP_DIR} (db-backup-*.sql)" >&2
    exit 1
  fi
fi

echo "Restaurando banco a partir de: ${BACKUP_FILE}"

echo "Testando conexão com MySQL no serviço 'db'..."
if ! docker compose exec -T db mysql -uroot -proot -e "SELECT 1" >/dev/null 2>&1; then
  echo "Não foi possível conectar ao MySQL no serviço 'db'." >&2
  echo "Certifique-se de que ele está rodando (ex.: 'docker compose up -d db' ou 'make up')." >&2
  exit 1
fi

echo "Importando dump para o banco 'drupal'..."
docker compose exec db mysql -uroot -proot -e "DROP DATABASE IF EXISTS drupal; CREATE DATABASE drupal;"
docker compose exec -T db mysql -uroot -proot drupal < "${BACKUP_FILE}"

echo "Restore do banco concluído."

