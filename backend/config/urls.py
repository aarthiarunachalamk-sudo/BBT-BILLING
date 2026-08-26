from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.db import connection
from django.db.migrations.recorder import MigrationRecorder
from django.http import JsonResponse
from django.urls import include, path
from rest_framework_simplejwt.views import TokenRefreshView

from billing.schema_repair import (
    admin_visibility_schema_status,
    product_catalog_schema_status,
    repair_admin_visibility_schema,
    repair_product_catalog_schema,
    repair_split_stock_schema,
    split_stock_schema_status,
)
from billing.views import AdminTokenObtainPairView, change_password, checkout, current_user, dashboard, logout_view, razorpay_order


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
            name="0014_secure_razorpay_payments",
        ).exists()
        return (
            applied
            and not admin_visibility_schema_status()
            and not split_stock_schema_status()
            and not product_catalog_schema_status()
        )

    try:
        schema_ready = schema_is_ready()
        if not schema_ready:
            # This legacy database has an inconsistent migration history, so
            # repair the known additive schema changes before serving traffic.
            repair_admin_visibility_schema()
            repair_split_stock_schema()
            # Only repair 0013 after Django considers it applied. Otherwise
            # the normal migration must own creation of these columns.
            if MigrationRecorder(connection).migration_qs.filter(
                app="billing",
                name="0013_item_store_section_item_rack_location",
            ).exists():
                repair_product_catalog_schema()
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
            "schema": "0014",
            "missing": (
                admin_visibility_schema_status()
                + split_stock_schema_status()
                + product_catalog_schema_status()
            ) if not schema_ready else [],
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
    path("api/billing/razorpay/order/", razorpay_order, name="razorpay-order"),
    path("api/dashboard/admin-summary/", dashboard, name="admin-dashboard-summary"),
    path("api/", include("billing.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
