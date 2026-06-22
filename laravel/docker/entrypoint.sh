#!/usr/bin/env bash
set -e

cd /var/www/html

# Drop any stale bootstrap config cache from the host mount BEFORE anything else,
# so migrate and config:cache below use this container's live env (DB_HOST=db,
# REDIS_HOST=redis), not a value baked by a previous run.
php artisan config:clear || true

# Ensure an app key exists (generate one if the .env placeholder is empty).
if ! grep -q "^APP_KEY=base64:" .env 2>/dev/null; then
    php artisan key:generate --force || true
fi

# Wait for Postgres, then migrate + seed (the Laravel analogue of Flyway-on-boot).
echo "Waiting for database ${DB_HOST:-db}:${DB_PORT:-5432}…"
until php -r "exit(@fsockopen(getenv('DB_HOST')?:'db', (int)(getenv('DB_PORT')?:5432)) ? 0 : 1);" 2>/dev/null; do
    sleep 2
done

# Migrate is best-effort — a hiccup here must never crash the container (set -e).
php artisan migrate --force || true

# Seed ONLY on an empty database, so a restored/real dataset is never clobbered
# (e.g. role-permission re-sync, extra bootstrap admin). Fresh DBs still seed.
USERS=$(php -r 'try { require "vendor/autoload.php"; $a=require "bootstrap/app.php"; $a->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap(); echo (int) App\Features\Users\Models\User::count(); } catch (\Throwable $e) { echo "-1"; }' 2>/dev/null)
if [ "$USERS" = "0" ]; then
    echo "Empty database → seeding."
    php artisan db:seed --force || true
else
    echo "Database already has data (users=$USERS) → skipping seeders."
fi

# Cache config so the resolved values (DB_HOST=db, REDIS_HOST=redis — read here
# via getenv) are baked in for every worker / artisan process that follows.
php artisan config:cache || php artisan config:clear || true

# APP_RUNTIME=serve → run the built-in PHP server (HTTP directly, no nginx).
# Default (fpm) → php-fpm behind the nginx "web" service.
if [ "${APP_RUNTIME:-fpm}" = "serve" ]; then
    echo "Serving via php artisan serve on 0.0.0.0:${APP_SERVE_PORT:-8080}"
    exec php artisan serve --host=0.0.0.0 --port="${APP_SERVE_PORT:-8080}"
fi

exec php-fpm
