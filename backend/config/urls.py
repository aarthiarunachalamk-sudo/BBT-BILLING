from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.db import connection
from django.db.migrations.recorder import MigrationRecorder
from django.http import JsonResponse
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

from billing.schema_repair import repair_admin_visibility_schema
from billing.views import AdminTokenObtainPairView, change_password, current_user, logout_view


def health_check(request):
    def schema_is_ready():
        applied = MigrationRecorder(connection).migration_qs.filter(
            app="billing",
            name="0006_admin_visibility_inventory",
        ).exists()
        columns = {
            column.name
            for column in connection.introspection.get_table_description(
                connection.cursor(),
                "billing_item",
            )
        }
        return applied and "barcode" in columns

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
        },
        status=200 if schema_ready else 503,
    )


urlpatterns = [
    path("health/", health_check, name="health-check"),
    path("admin/", admin.site.urls),
    path("api/auth/login/", AdminTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/auth/change-password/", change_password, name="change-password"),
    path("api/auth/logout/", logout_view, name="logout"),
    path("api/auth/me/", current_user, name="current-user"),
    path("api/auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/", include("billing.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
