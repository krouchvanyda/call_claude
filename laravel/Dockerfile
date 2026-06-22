# ===========================================================================
# ERP backend — Laravel 8 / PHP 7.4 (php-fpm)
# ===========================================================================
FROM php:7.4-fpm

# System deps + PHP extensions (pdo_pgsql for Postgres, pcntl for the
# websockets server, bcmath/zip for general use).
RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip libpq-dev libzip-dev libonig-dev \
    && docker-php-ext-install pdo pdo_pgsql pcntl bcmath zip mbstring \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# CLI php.ini override (variables_order=EGPCS so `php artisan serve` propagates
# container env vars to its child server process).
COPY docker/php/cli.ini /usr/local/etc/php/conf.d/zz-erp-cli.ini

# Composer (pinned to 2.7 — reports, rather than blocks on, the security
# advisories that the EOL Laravel 8 / PHP 7.4 stack inevitably carries).
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Install PHP deps first (better layer caching).
COPY composer.json composer.lock* ./
RUN composer install --no-interaction --no-scripts --no-autoloader --prefer-dist || true

# App source
COPY . .

# Drop any stale bootstrap cache copied from the host (a packages.php manifest
# referencing dev-only packages like Ignition would crash the no-dev image).
# --no-scripts: package discovery runs at first boot (when .env is present).
RUN rm -f bootstrap/cache/*.php \
    && composer install --no-interaction --optimize-autoloader --no-dev --no-scripts \
    && composer dump-autoload --optimize --no-scripts \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
