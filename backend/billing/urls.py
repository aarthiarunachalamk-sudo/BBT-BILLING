from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AuditLogViewSet,
    BrandViewSet,
    CategoryViewSet,
    ClientViewSet,
    DiscountApprovalViewSet,
    InventoryTransactionViewSet,
    InvoiceViewSet,
    ItemViewSet,
    PaymentViewSet,
    ProductBatchViewSet,
    PurchaseOrderViewSet,
    QuotationViewSet,
    SupplierViewSet,
    ReturnRequestViewSet,
    RolePermissionViewSet,
    StoreSettingsViewSet,
    StockAdjustmentViewSet,
    StockReviewViewSet,
    UserViewSet,
    WhatsAppMessageViewSet,
    dashboard,
)


router = DefaultRouter()
router.register("users", UserViewSet)
router.register("clients", ClientViewSet)
router.register("categories", CategoryViewSet)
router.register("brands", BrandViewSet)
router.register("suppliers", SupplierViewSet)
router.register("items", ItemViewSet)
router.register("inventory-transactions", InventoryTransactionViewSet)
router.register("quotations", QuotationViewSet)
router.register("discount-approvals", DiscountApprovalViewSet)
router.register("invoices", InvoiceViewSet)
router.register("payments", PaymentViewSet)
router.register("inventory/batches", ProductBatchViewSet, basename="product-batches")
router.register("inventory/quantity-reviews", StockReviewViewSet, basename="stock-reviews")
router.register("inventory/stock-adjustments", StockAdjustmentViewSet, basename="stock-adjustments")
router.register("whatsapp-messages", WhatsAppMessageViewSet)
router.register("role-permissions", RolePermissionViewSet)
router.register("purchase-orders", PurchaseOrderViewSet)
router.register("returns", ReturnRequestViewSet)
router.register("store-settings", StoreSettingsViewSet)
router.register("audit-logs", AuditLogViewSet)

urlpatterns = [
    path("dashboard/", dashboard, name="dashboard"),
    path("admin/dashboard/", dashboard, name="admin-dashboard"),
    path("admin/users/", UserViewSet.as_view({"get": "list", "post": "create"}), name="admin-users"),
    path("admin/users/<int:pk>/", UserViewSet.as_view({"get": "retrieve", "patch": "partial_update"}), name="admin-user-detail"),
    path("products/", ItemViewSet.as_view({"get": "list", "post": "create"}), name="products"),
    path("products/<int:pk>/", ItemViewSet.as_view({"get": "retrieve", "patch": "partial_update"}), name="product-detail"),
    path("inventory/current-stock/", ItemViewSet.as_view({"get": "current_stock"}), name="current-stock"),
    path("inventory/shelf-stock/", ItemViewSet.as_view({"get": "shelf_stock_list"}), name="shelf-stock"),
    path("inventory/expiry/", ProductBatchViewSet.as_view({"get": "list"}), name="expiry-products"),
    path("", include(router.urls)),
]
