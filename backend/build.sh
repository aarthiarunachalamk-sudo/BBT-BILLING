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
python manage.py migrate
if python manage.py showmigrations billing | grep -q '\[ \]'; then
  echo "Unapplied billing migrations remain; refusing to deploy."
  exit 1
fi
python manage.py seed_weight_products
