#!/bin/bash
set -e

SITES_DEFAULT="/var/www/html/web/sites/default"
FILES_DIR="${SITES_DEFAULT}/files"
TRANSLATIONS_DIR="${FILES_DIR}/translations"

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
