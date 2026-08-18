from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import (
    AuditLog,
    Category,
    Client,
    DiscountApproval,
    InventoryTransaction,
    Invoice,
    InvoiceItem,
    Item,
    Payment,
    PurchaseOrder,
    PurchaseOrderItem,
    Quotation,
    QuotationItem,
    Supplier,
    ReturnItem,
    ReturnRequest,
    RolePermission,
    StoreSettings,
    User,
    WhatsAppMessage,
)


@admin.register(User)
class BillingUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (("Billing app", {"fields": ("role", "phone")}),)
    add_fieldsets = UserAdmin.add_fieldsets + (("Billing app", {"fields": ("email", "role", "phone")}),)
    list_display = ("username", "email", "first_name", "last_name", "role", "is_active")


class QuotationItemInline(admin.TabularInline):
    model = QuotationItem
    extra = 0


class InvoiceItemInline(admin.TabularInline):
    model = InvoiceItem
    extra = 0


@admin.register(Quotation)
class QuotationAdmin(admin.ModelAdmin):
    list_display = ("number", "client", "status", "total", "created_at")
    list_filter = ("status",)
    search_fields = ("number", "client__name")
    inlines = [QuotationItemInline]


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    list_display = ("number", "client", "invoice_date", "due_date", "status", "total")
    list_filter = ("status", "invoice_date")
    search_fields = ("number", "client__name")
    inlines = [InvoiceItemInline]


@admin.register(Item)
class ItemAdmin(admin.ModelAdmin):
    list_display = ("name", "sku", "item_type", "category", "selling_price", "stock_quantity", "is_active")
    list_filter = ("item_type", "category", "is_active")
    search_fields = ("name", "sku")


@admin.register(Client)
class ClientAdmin(admin.ModelAdmin):
    list_display = ("name", "contact_person", "whatsapp_mobile", "gstin", "is_active")
    search_fields = ("name", "contact_person", "whatsapp_mobile", "gstin")


admin.site.register(Category)
admin.site.register(Supplier)
admin.site.register(InventoryTransaction)
admin.site.register(DiscountApproval)
admin.site.register(Payment)
admin.site.register(WhatsAppMessage)
admin.site.register(RolePermission)
admin.site.register(PurchaseOrder)
admin.site.register(PurchaseOrderItem)
admin.site.register(ReturnRequest)
admin.site.register(ReturnItem)
admin.site.register(StoreSettings)
admin.site.register(AuditLog)
