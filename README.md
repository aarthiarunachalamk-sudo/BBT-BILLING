# Supermarket Billing Admin

Flutter admin application backed by Django REST Framework and JWT authentication.

## Local setup

```powershell
cd backend
python -m pip install -r requirements.txt
python manage.py migrate
python manage.py seed_demo
python manage.py runserver
```

The seeded admin login is `admin@supermart.com` / `admin123`.

In another terminal, run Flutter. Desktop and web can use the default local API URL:

```powershell
flutter run
```

For the Android emulator, point the app at the host machine:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

For a deployed backend, pass its HTTPS API URL using the same `API_BASE_URL` define.

For Render, use `backend` as the service Root Directory and set the Start
Command to `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT --workers 2
--timeout 120 --access-logfile - --error-logfile -`. If the service Root
Directory is the repository root, use `cd backend && gunicorn config.wsgi:application
--bind 0.0.0.0:$PORT --workers 2 --timeout 120 --access-logfile - --error-logfile -`.

## Verification

```powershell
flutter analyze
flutter test
cd backend
python manage.py test
```
