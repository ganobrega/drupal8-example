#!/bin/bash
set -e

SITES_DEFAULT="/var/www/html/web/sites/default"
FILES_DIR="${SITES_DEFAULT}/files"
TRANSLATIONS_DIR="${FILES_DIR}/translations"

# BACKUP_MOUNT="/backups"
# SITES_ROOT="/var/www/html/web/sites"

# # Restaurar último backup de sites, se existir e se o volume /backups estiver montado
# if [ -d "${BACKUP_MOUNT}" ]; then
#   LATEST_BACKUP="$(
#     find "${BACKUP_MOUNT}" -maxdepth 1 -type f -name 'backup-*.tar.gz' -printf '%T@ %p\n' 2>/dev/null \
#       | sort -n \
#       | tail -n 1 \
#       | awk '{print $2}'
#   )"

#   if [ -n "${LATEST_BACKUP:-}" ]; then
#     echo "Restaurando conteúdo de sites a partir do backup: ${LATEST_BACKUP}"
#     # O backup foi criado com -C app/web sites, então extraímos em /var/www/html/web
#     tar -xzf "${LATEST_BACKUP}" -C /var/www/html/web
#     chown -R www-data:www-data "${SITES_ROOT}"
#   else
#     echo "Nenhum backup encontrado em ${BACKUP_MOUNT}, seguindo sem restore."
#   fi
# else
#   echo "Diretório de backups ${BACKUP_MOUNT} não montado, seguindo sem restore."
# fi

# Criar diretório de arquivos (uploads) com permissões para o Apache
mkdir -p "${FILES_DIR}" "${TRANSLATIONS_DIR}"
chown -R www-data:www-data "${FILES_DIR}"

# Copiar default.settings.php para settings.php se não existir
if [ ! -f "${SITES_DEFAULT}/settings.php" ] && [ -f "${SITES_DEFAULT}/default.settings.php" ]; then
  cp "${SITES_DEFAULT}/default.settings.php" "${SITES_DEFAULT}/settings.php"
  chown www-data:www-data "${SITES_DEFAULT}/settings.php"
fi

# Injetar configuração do banco a partir do ambiente (host=db no Docker) — só uma vez
if [ -n "${DRUPAL_DB_HOST}" ] && [ -f "${SITES_DEFAULT}/settings.php" ] && ! grep -q 'DRUPAL_DB_HOST' "${SITES_DEFAULT}/settings.php"; then
  cat >> "${SITES_DEFAULT}/settings.php" << 'PHPEOF'

// Configuração do banco via ambiente (docker-compose)
if (getenv('DRUPAL_DB_HOST')) {
  $databases['default']['default'] = [
    'database' => getenv('DRUPAL_DB_NAME') ?: 'drupal',
    'username' => getenv('DRUPAL_DB_USER') ?: 'drupal',
    'password' => getenv('DRUPAL_DB_PASSWORD') ?: 'drupal',
    'host' => getenv('DRUPAL_DB_HOST'),
    'port' => getenv('DRUPAL_DB_PORT') ?: '3306',
    'driver' => 'mysql',
    'prefix' => '',
    'collation' => 'utf8mb4_general_ci',
  ];
}
PHPEOF
  chown www-data:www-data "${SITES_DEFAULT}/settings.php"
fi

# Copiar tradução pt-BR do core (vinda da imagem) para files/translations
if [ -f /opt/drupal-translations/drupal-8.9.20.pt-br.po ]; then
  cp /opt/drupal-translations/drupal-8.9.20.pt-br.po "${TRANSLATIONS_DIR}/"
  chown www-data:www-data "${TRANSLATIONS_DIR}/drupal-8.9.20.pt-br.po"
fi

# Iniciar Apache (garante comando mesmo se CMD não for passado)
if [ $# -eq 0 ]; then
  exec apache2-foreground
else
  exec "$@"
fi
