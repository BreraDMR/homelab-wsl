FROM php:8.3-apache

# gd (+webp) is needed for CatPhotoUploader.php to resize/convert kitten
# photos uploaded via the Telegram bot. -dev packages stay installed
# (not purged) since the gd .so links against the runtime libs at startup,
# not just at compile time.
RUN apt-get update && apt-get install -y --no-install-recommends       libjpeg62-turbo-dev libpng-dev libwebp-dev     && docker-php-ext-configure gd --with-jpeg --with-webp     && docker-php-ext-install gd pdo_mysql     && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/html
COPY app/site/ /var/www/html/
RUN composer install --no-dev --no-interaction --optimize-autoloader  && chown -R www-data:www-data /var/www/html
