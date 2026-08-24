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
    StoreStockViewSet,
    ShelfStockViewSet,
    StockMovementViewSet,
    StockAdjustmentViewSet,
    StockReviewViewSet,
    UserViewSet,
    WhatsAppMessageViewSet,
    dashboard,
    store_to_shelf,
    shelf_to_store,
    auto_refill_product,
    stock_summary,
)


router = DefaultRouter()
router.register("users", UserViewSet)
router.register("clients", ClientViewSet)
router.register("categories", CategoryViewSet)
router.register("brands", BrandViewSet)
router.register("suppliers", SupplierViewSet)
router.register("items", ItemViewSet)
router.register("inventory-transactions", InventoryTransactionViewSet)
router.register("inventory/store-stock", StoreStockViewSet, basename="store-stock")
router.register("inventory/shelf-stock-records", ShelfStockViewSet, basename="shelf-stock-records")
router.register("inventory/stock-movements", StockMovementViewSet, basename="stock-movements")
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
    path("inventory/shelf-stock/", ShelfStockViewSet.as_view({"get": "list"}), name="shelf-stock"),
    path("inventory/store-to-shelf/", store_to_shelf, name="store-to-shelf"),
    path("inventory/move-to-shelf/", store_to_shelf, name="move-to-shelf"),
    path("inventory/shelf-to-store/", shelf_to_store, name="shelf-to-store"),
    path("inventory/shelf-stock/<int:product_id>/auto-refill/", auto_refill_product, name="auto-refill-shelf"),
    path("inventory/stock-summary/", stock_summary, name="stock-summary"),
    path("inventory/expiry/", ProductBatchViewSet.as_view({"get": "list"}), name="expiry-products"),
    path("", include(router.urls)),
]
