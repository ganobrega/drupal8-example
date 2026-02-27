#!/usr/bin/env bash
set -euo pipefail

# Restaura o banco MySQL do container db a partir de um dump .sql em backups/
# Uso:
#   ./scripts/restore-db.sh                    # restaura a partir do dump mais recente
#   ./scripts/restore-db.sh caminho/arquivo.sql # restaura a partir de um dump específico
#   BACKUP=db-backup-2025-01-01-00-00.sql make restore-db

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

BACKUP_DIR="${PROJECT_ROOT}/backups"

if [ ! -d "${BACKUP_DIR}" ]; then
  echo "Diretório de backups não encontrado: ${BACKUP_DIR}" >&2
  exit 1
fi

BACKUP_NAME="${1:-${BACKUP:-}}"
DUMP_FILE=""

if [ -n "${BACKUP_NAME}" ]; then
  # Se o usuário passou um caminho ou nome de arquivo específico
  if [ -f "${BACKUP_NAME}" ]; then
    DUMP_FILE="${BACKUP_NAME}"
  elif [ -f "${BACKUP_DIR}/${BACKUP_NAME}" ]; then
    DUMP_FILE="${BACKUP_DIR}/${BACKUP_NAME}"
  else
    echo "Dump especificado não encontrado: ${BACKUP_NAME}" >&2
    exit 1
  fi
else
  # Usar o dump mais recente em BACKUP_DIR (db-backup-*.sql ou *.sql em geral)
  DUMP_FILE="$(
    find "${BACKUP_DIR}" -maxdepth 1 -type f -name '*.sql' -printf '%T@ %p\n' 2>/dev/null \
      | sort -n \
      | tail -n 1 \
      | awk '{print $2}'
  )"

  if [ -z "${DUMP_FILE:-}" ]; then
    echo "Nenhum dump .sql encontrado em ${BACKUP_DIR}" >&2
    exit 1
  fi
fi

echo "Restaurando banco a partir de: ${DUMP_FILE}"

echo "Garantindo que o serviço db esteja rodando..."
docker compose up -d db

echo "Aguardando MySQL ficar pronto..."
for i in {1..30}; do
  if docker compose exec -T db mysql -uroot -proot -e "SELECT 1" &>/dev/null; then
    break
  fi
  [ "$i" -eq 30 ] && { echo "Timeout aguardando MySQL." >&2; exit 1; }
  sleep 1
done

echo "Limpando e recriando o banco 'drupal'..."
docker compose exec -T db mysql -uroot -proot -e "DROP DATABASE IF EXISTS drupal; CREATE DATABASE drupal DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

echo "Importando dump..."
docker compose exec -T db mysql -uroot -proot drupal < "${DUMP_FILE}"

echo "Restore do banco concluído com sucesso."

