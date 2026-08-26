#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

readonly MAX_INSTALL_ATTEMPTS=5

for attempt in $(seq 1 "$MAX_INSTALL_ATTEMPTS"); do
  echo "Installing Python dependencies (attempt ${attempt}/${MAX_INSTALL_ATTEMPTS})..."
  if python -m pip install \
    --disable-pip-version-check \
    --prefer-binary \
    --retries 20 \
    --timeout 120 \
    -r requirements.txt; then
    break
  fi

  if [ "$attempt" -eq "$MAX_INSTALL_ATTEMPTS" ]; then
    echo "Dependency installation failed after ${MAX_INSTALL_ATTEMPTS} attempts."
    exit 1
  fi

  retry_delay=$((attempt * 10))
  echo "Package host unavailable; retrying in ${retry_delay} seconds..."
  sleep "$retry_delay"
done

mkdir -p staticfiles
python manage.py collectstatic --no-input
echo "Running Django database migrations..."
if ! python manage.py migrate --noinput; then
  echo "Normal migration history is inconsistent; applying targeted additive repair."
  python manage.py shell -c "from billing.schema_repair import repair_admin_visibility_schema; repair_admin_visibility_schema()"
  echo "Retrying Django migrations after repairing their legacy dependencies."
  python manage.py migrate --noinput
fi
echo "Billing migration status after build:"
python manage.py showmigrations billing
python manage.py shell -c "from billing.schema_repair import repair_product_catalog_schema; repair_product_catalog_schema()"
python manage.py shell -c "from billing.schema_repair import repair_split_stock_schema; repair_split_stock_schema()"
python manage.py seed_weight_products
python manage.py seed_brand_catalog
