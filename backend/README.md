# BBT Billing Django backend

This backend provides the REST API, admin panel, JWT login, billing workflow, payments, and inventory tracking for the Flutter application.

## Database design

The application has 13 main business tables:

1. User
2. Client
3. Category
4. Supplier
5. Item (service or material)
6. Inventory transaction
7. Quotation
8. Quotation item
9. Discount approval
10. Invoice
11. Invoice item
12. Payment
13. WhatsApp message

Django also creates its own internal tables for permissions, sessions, migrations, and the admin history.

## Run locally (beginner steps)

Open PowerShell in the `backend` folder:

```powershell
cd C:\BBT-BILLING\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py seed_demo
python manage.py runserver
```

Then open:

- Admin: `http://127.0.0.1:8000/admin/`
- API: `http://127.0.0.1:8000/api/`
- Health check: `http://127.0.0.1:8000/health/`

Local development uses SQLite when `DATABASE_URL` is not set.

## Neon + Render setup

The project reads PostgreSQL credentials from `DATABASE_URL`. Never paste the real URL into a source file or commit it to Git.

In Render, create or open the web service and use:

- Root Directory: `backend`
- Build Command: `bash build.sh`
- Start Command: `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers $WEB_CONCURRENCY --timeout 120 --access-logfile - --error-logfile -`
- Health Check Path: `/health/`
- Python version: `3.13` (already pinned in `.python-version`)

Add these Render environment variables:

- `DATABASE_URL`: the Neon pooled connection string
- `DJANGO_SECRET_KEY`: generate a long random secret
- `DJANGO_DEBUG`: `false`
- `DJANGO_ALLOWED_HOSTS`: your Render host, for example `your-api.onrender.com` (Render's automatic hostname is also detected)
- `CORS_ALLOWED_ORIGINS`: the deployed Flutter Web URL, only if using Flutter Web

Deploy the service. The build script installs packages, collects static files, and creates/updates all database tables.

If the deploy log says `Running build command 'pip install -r requirements.txt'`, the Render dashboard is overriding this repository configuration. Open **Settings → Build & Deploy**, change **Build Command** to `bash build.sh`, save it, and deploy again using **Clear build cache & deploy**. The build script retries temporary PyPI 5xx failures automatically.

After the first deploy, open Render Shell and run:

```bash
python manage.py createsuperuser
python manage.py seed_demo
```

## Authentication

Send the username and password to:

```text
POST /api/auth/login/
```

Use the returned access token on protected API calls:

```text
Authorization: Bearer YOUR_ACCESS_TOKEN
```

Refresh an expired access token with:

```text
POST /api/auth/refresh/
```

## Important API routes

- `/api/dashboard/`
- `/api/clients/`
- `/api/categories/`
- `/api/suppliers/`
- `/api/items/`
- `/api/items/{id}/adjust_stock/`
- `/api/inventory-transactions/`
- `/api/quotations/`
- `/api/quotations/{id}/request_discount/`
- `/api/quotations/{id}/convert_to_invoice/`
- `/api/discount-approvals/{id}/decide/`
- `/api/invoices/`
- `/api/payments/`
- `/api/payments/{id}/verify/`
- `/api/whatsapp-messages/`

## Tests

```powershell
python manage.py test
```
