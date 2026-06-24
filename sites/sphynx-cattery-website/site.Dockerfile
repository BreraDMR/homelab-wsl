FROM php:8.3-apache
RUN docker-php-ext-install pdo_mysql > /dev/null
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/html
COPY app/site/ /var/www/html/
RUN composer install --no-dev --no-interaction --optimize-autoloader \
 && chown -R www-data:www-data /var/www/html
