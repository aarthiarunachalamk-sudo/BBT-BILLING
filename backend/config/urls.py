from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.db import connection
from django.db.migrations.recorder import MigrationRecorder
from django.http import JsonResponse
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

from billing.schema_repair import admin_visibility_schema_status, repair_admin_visibility_schema
from billing.views import AdminTokenObtainPairView, change_password, checkout, current_user, dashboard, logout_view


def api_root(request):
    return JsonResponse(
        {
            "status": "ok",
            "service": "bbt-billing-api",
            "health": request.build_absolute_uri("/health/"),
            "api": request.build_absolute_uri("/api/"),
        }
    )


def health_check(request):
    def schema_is_ready():
        applied = MigrationRecorder(connection).migration_qs.filter(
            app="billing",
            name="0006_admin_visibility_inventory",
        ).exists()
        return applied and not admin_visibility_schema_status()

    try:
        schema_ready = schema_is_ready()
        if not schema_ready:
            # This legacy database has an inconsistent squashed-migration
            # history, so repair only the known additive 0006 schema changes.
            repair_admin_visibility_schema()
            connection.close()
            schema_ready = schema_is_ready()
    except Exception as exception:
        return JsonResponse(
            {"status": "error", "service": "bbt-billing-api", "database": exception.__class__.__name__},
            status=503,
        )
    return JsonResponse(
        {
            "status": "ok" if schema_ready else "error",
            "service": "bbt-billing-api",
            "database": "ready" if schema_ready else "migration_required",
            "schema": "0006",
            "missing": admin_visibility_schema_status() if not schema_ready else [],
        },
        status=200 if schema_ready else 503,
    )


urlpatterns = [
    path("", api_root, name="api-root"),
    path("health/", health_check, name="health-check"),
    path("admin/", admin.site.urls),
    path("api/auth/login/", AdminTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/auth/change-password/", change_password, name="change-password"),
    path("api/auth/logout/", logout_view, name="logout"),
    path("api/auth/me/", current_user, name="current-user"),
    path("api/auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/billing/checkout/", checkout, name="billing-checkout"),
    path("api/dashboard/admin-summary/", dashboard, name="admin-dashboard-summary"),
    path("api/", include("billing.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
