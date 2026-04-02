#!/bin/sh
set -e

echo "==> Romduol Library — Container Init"

# ── 1. Install Composer dependencies ─────────────────────────────────────────
if [ ! -d "/var/www/vendor" ]; then
    echo "==> Installing Composer dependencies..."
    cd /var/www && composer install --no-interaction --no-dev --optimize-autoloader
fi

# ── 2. Copy .env if missing ───────────────────────────────────────────────────
if [ ! -f "/var/www/.env" ]; then
    echo "==> Creating .env from .env.example..."
    cp /var/www/.env.example /var/www/.env
fi

# ── 3. Generate app key if empty ─────────────────────────────────────────────
APP_KEY_VALUE=$(grep '^APP_KEY=' /var/www/.env | cut -d'=' -f2)
if [ -z "$APP_KEY_VALUE" ]; then
    echo "==> Generating application key..."
    cd /var/www && php artisan key:generate --force
fi

# ── 4. Fix permissions ────────────────────────────────────────────────────────
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# ── 5. Wait for PostgreSQL ────────────────────────────────────────────────────
echo "==> Waiting for PostgreSQL..."
until php -r "
    \$dsn = 'pgsql:host=' . getenv('DB_HOST') . ';port=' . getenv('DB_PORT') . ';dbname=' . getenv('DB_DATABASE');
    new PDO(\$dsn, getenv('DB_USERNAME'), getenv('DB_PASSWORD'));
    echo 'ok';
" 2>/dev/null | grep -q ok; do
    echo "   PostgreSQL not ready — retrying in 2s..."
    sleep 2
done
echo "==> PostgreSQL is ready."

# ── 6. Run migrations & seeders ──────────────────────────────────────────────
echo "==> Running migrations..."
cd /var/www && php artisan migrate --force

echo "==> Seeding database..."
cd /var/www && php artisan db:seed --force 2>/dev/null || echo "   Seed skipped (already done or error)."

# ── 7. Create storage symlink ─────────────────────────────────────────────────
cd /var/www && php artisan storage:link --force 2>/dev/null || true

echo "==> Init complete — Starting PHP-FPM"
exec php-fpm
