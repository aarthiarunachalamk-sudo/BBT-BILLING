from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    CategoryViewSet,
    ClientViewSet,
    DiscountApprovalViewSet,
    InventoryTransactionViewSet,
    InvoiceViewSet,
    ItemViewSet,
    PaymentViewSet,
    QuotationViewSet,
    SupplierViewSet,
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

urlpatterns = [
    path("dashboard/", dashboard, name="dashboard"),
    path("", include(router.urls)),
]
