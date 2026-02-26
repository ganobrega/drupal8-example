FROM php:7.4-apache

RUN apt-get update && apt-get install -y \
    unzip git libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install gd pdo pdo_mysql zip opcache \
 && docker-php-ext-enable opcache \
 && a2enmod rewrite

# Drupal recommended-project usa /web como docroot
ENV APACHE_DOCUMENT_ROOT /var/www/html/web

RUN sed -ri 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Permitir .htaccess (necessário pro Drupal)
RUN sed -ri 's/AllowOverride\s+None/AllowOverride All/g' /etc/apache2/apache2.conf

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY php.ini /usr/local/etc/php/

# Tradução pt-BR (copiada para sites/default/files/translations pelo entrypoint)
RUN mkdir -p /opt/drupal-translations
COPY drupal-8.9.20.pt-br.po /opt/drupal-translations/

# Entrypoint: cria files/, settings.php e copia .po (compatível com volume ./app)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

WORKDIR /var/www/html