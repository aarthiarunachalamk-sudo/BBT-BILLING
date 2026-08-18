from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AuditLogViewSet,
    CategoryViewSet,
    ClientViewSet,
    DiscountApprovalViewSet,
    InventoryTransactionViewSet,
    InvoiceViewSet,
    ItemViewSet,
    PaymentViewSet,
    PurchaseOrderViewSet,
    QuotationViewSet,
    SupplierViewSet,
    ReturnRequestViewSet,
    RolePermissionViewSet,
    StoreSettingsViewSet,
    UserViewSet,
    WhatsAppMessageViewSet,
    dashboard,
)


router = DefaultRouter()
router.register("users", UserViewSet)
router.register("clients", ClientViewSet)
router.register("categories", CategoryViewSet)
router.register("suppliers", SupplierViewSet)
router.register("items", ItemViewSet)
router.register("inventory-transactions", InventoryTransactionViewSet)
router.register("quotations", QuotationViewSet)
router.register("discount-approvals", DiscountApprovalViewSet)
router.register("invoices", InvoiceViewSet)
router.register("payments", PaymentViewSet)
router.register("whatsapp-messages", WhatsAppMessageViewSet)
router.register("role-permissions", RolePermissionViewSet)
router.register("purchase-orders", PurchaseOrderViewSet)
router.register("returns", ReturnRequestViewSet)
router.register("store-settings", StoreSettingsViewSet)
router.register("audit-logs", AuditLogViewSet)

urlpatterns = [
    path("dashboard/", dashboard, name="dashboard"),
    path("", include(router.urls)),
]
