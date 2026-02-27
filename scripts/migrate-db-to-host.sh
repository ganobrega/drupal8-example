#!/usr/bin/env bash
set -euo pipefail

# Migra o banco do volume Docker (db_data) para a pasta ./mysql-data no host.
# Execute a partir da raiz do projeto ou de scripts/.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

BACKUP_DIR="${PROJECT_ROOT}/backups"
DUMP_FILE="${BACKUP_DIR}/db-migrate-dump.sql"
MYSQL_DATA="${PROJECT_ROOT}/mysql-data"

# Nome do volume antigo (Docker Compose usa <projeto>_db_data)
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$(pwd)")}"
OLD_VOLUME="${COMPOSE_PROJECT_NAME}_db_data"

echo "=== Migração do banco para ./mysql-data ==="

# 1) Descobrir o volume com os dados atuais
if ! docker volume inspect "${OLD_VOLUME}" &>/dev/null; then
  # Tentar qualquer volume que termine com _db_data
  FOUND="$(docker volume ls -q | grep '_db_data$' | head -n 1)"
  if [ -z "${FOUND}" ]; then
    echo "Nenhum volume de banco encontrado (ex.: ${OLD_VOLUME})." >&2
    echo "Se você já fez o dump antes, coloque em: ${DUMP_FILE}" >&2
    echo "e rode este script de novo para só restaurar em ./mysql-data." >&2
    exit 1
  fi
  OLD_VOLUME="${FOUND}"
  echo "Usando volume: ${OLD_VOLUME}"
else
  echo "Volume encontrado: ${OLD_VOLUME}"
fi

mkdir -p "${BACKUP_DIR}"

# Remover containers temporários de execuções anteriores (ex.: migrate que deu timeout)
for c in $(docker ps -aq -f "name=db-migrate-src-"); do
  docker rm -f "$c" 2>/dev/null || true
done

# 2) Liberar o volume antigo: parar e remover QUALQUER container que use esse volume
#    (senão InnoDB dá "Unable to lock ./ibdata1 error: 11")
echo "Parando qualquer container que use o volume ${OLD_VOLUME}..."
for c in $(docker ps -aq --filter "volume=${OLD_VOLUME}"); do
  echo "  Parando e removendo container: $c"
  docker rm -f "$c" 2>/dev/null || true
done
echo "Parando serviço db do compose (se estiver rodando)..."
docker-compose stop db 2>/dev/null || true
echo "Aguardando 3s para o volume ser liberado..."
sleep 3

# 3) Subir MySQL temporário com o volume antigo e fazer o dump
TMP_CONTAINER="db-migrate-src-$$"
echo "Iniciando MySQL temporário com o volume antigo..."
docker run -d --name "${TMP_CONTAINER}" \
  -v "${OLD_VOLUME}:/var/lib/mysql" \
  -e MYSQL_ROOT_PASSWORD=root \
  mysql:5.7

cleanup_tmp() {
  docker stop "${TMP_CONTAINER}" 2>/dev/null || true
  docker rm "${TMP_CONTAINER}" 2>/dev/null || true
}
trap cleanup_tmp EXIT

echo "Aguardando MySQL temporário ficar pronto (pode levar 1–2 min com dados existentes)..."
sleep 10
MAX_WAIT=180
for i in $(seq 1 "${MAX_WAIT}"); do
  if ! docker inspect -f '{{.State.Running}}' "${TMP_CONTAINER}" 2>/dev/null | grep -q true; then
    echo "" >&2
    echo "Container MySQL temporário parou. Logs:" >&2
    docker logs "${TMP_CONTAINER}" 2>&1
    exit 1
  fi
  if docker exec "${TMP_CONTAINER}" mysql -uroot -proot -e "SELECT 1" &>/dev/null; then
    echo " MySQL pronto após ${i}s."
    break
  fi
  if [ "$i" -eq "${MAX_WAIT}" ]; then
    echo "" >&2
    echo "Timeout aguardando MySQL temporário. Últimos logs do container:" >&2
    docker logs "${TMP_CONTAINER}" 2>&1 | tail -n 40
    exit 1
  fi
  printf "."
  sleep 1
done

echo "Fazendo dump do banco..."
docker exec "${TMP_CONTAINER}" mysqldump -uroot -proot \
  --all-databases --single-transaction --routines --triggers \
  > "${DUMP_FILE}"

if [ ! -s "${DUMP_FILE}" ]; then
  echo "Erro: dump vazio ou falhou." >&2
  exit 1
fi
echo "Dump salvo em: ${DUMP_FILE}"

# 4) Garantir que ./mysql-data existe e subir o db com ele
mkdir -p "${MYSQL_DATA}"
echo "Subindo MySQL com ./mysql-data..."
docker-compose up -d db

# 5) Esperar o MySQL ficar pronto
echo "Aguardando MySQL ficar pronto..."
for i in {1..30}; do
  if docker-compose exec -T db mysql -uroot -proot -e "SELECT 1" &>/dev/null; then
    break
  fi
  [ "$i" -eq 30 ] && { echo "Timeout aguardando MySQL." >&2; exit 1; }
  sleep 1
done

# 6) Restaurar o dump
echo "Restaurando dump em ./mysql-data..."
docker-compose exec -T db mysql -uroot -proot < "${DUMP_FILE}"

echo "Migração concluída. Banco agora está em: ${MYSQL_DATA}"
echo "Dump mantido em: ${DUMP_FILE} (pode apagar depois se quiser)."
