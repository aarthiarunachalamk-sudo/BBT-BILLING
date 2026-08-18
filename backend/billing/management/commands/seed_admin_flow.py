from datetime import timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from billing.models import (
    AuditLog,
    Category,
    Client,
    DiscountApproval,
    Invoice,
    InvoiceItem,
    Item,
    Payment,
    PurchaseOrder,
    PurchaseOrderItem,
    Quotation,
    QuotationItem,
    RolePermission,
    StoreSettings,
    Supplier,
    User,
    WhatsAppMessage,
)


class Command(BaseCommand):
    help = "Create idempotent data used by the supermarket admin flow"

    @transaction.atomic
    def handle(self, *args, **options):
        admin = User.objects.filter(email__iexact="aarthi@gmail.com").first()
        if admin is None:
            admin = User(username="aarthi", email="aarthi@gmail.com")
            admin.set_unusable_password()
        admin.first_name = admin.first_name or "Aarthi"
        admin.role = User.Role.ADMIN
        admin.is_staff = True
        admin.is_superuser = True
        admin.is_active = True
        admin.save()

        staff = [
            ("rahul", "Rahul", "Kumar", "rahul@supermart.com", User.Role.ADMIN, True),
            ("anita", "Anita", "Sharma", "anita@supermart.com", User.Role.SALES, True),
            ("vikram", "Vikram", "Singh", "vikram@supermart.com", User.Role.SALES, True),
            ("neha", "Neha", "Joshi", "neha@supermart.com", User.Role.INVENTORY, True),
            ("pooja", "Pooja", "Mehta", "pooja@supermart.com", User.Role.SALES, False),
        ]
        for username, first, last, email, role, active in staff:
            user, created = User.objects.get_or_create(
                username=username,
                defaults={
                    "email": email,
                    "first_name": first,
                    "last_name": last,
                    "role": role,
                    "is_active": active,
                },
            )
            if created:
                user.set_unusable_password()
                user.save(update_fields=["password"])

        permission_rows = {
            "admin": {name: True for name in ("products", "billing", "inventory", "discounts", "reports", "returns", "settings")},
            "cashier": {"products": True, "billing": True, "discounts": True, "returns": True},
            "inventory_manager": {"products": True, "inventory": True, "reports": True},
        }
        for role, values in permission_rows.items():
            RolePermission.objects.get_or_create(role=role, defaults=values)
        StoreSettings.objects.get_or_create(
            pk=1,
            defaults={
                "store_name": "Supermarket",
                "invoice_prefix": "BILL-",
                "default_gst": Decimal("5.00"),
                "max_cashier_discount": Decimal("10.00"),
                "approval_threshold": Decimal("10.00"),
                "round_off": Decimal("0.01"),
                "whatsapp_enabled": True,
            },
        )

        category_names = [
            "Grocery & Staples",
            "Fruits & Vegetables",
            "Dairy & Bakery",
            "Beverages",
            "Snacks",
            "Household",
            "Personal Care",
        ]
        categories = {
            name: Category.objects.get_or_create(name=name)[0]
            for name in category_names
        }
        supplier_rows = [
            ("Balaji Distributors", "27AACCB1234F1Z5", "9876543210"),
            ("Shree Traders", "07CCAZQ0002G2Z1", "9911122233"),
            ("Fresh Foods Pvt. Ltd.", "01AABCP4567H1Z2", "9877754456"),
            ("Quality Supplies", "19BBRTY9001F2Z3", "9355066670"),
        ]
        suppliers = {}
        for name, gstin, phone in supplier_rows:
            suppliers[name], _ = Supplier.objects.get_or_create(
                name=name,
                defaults={"gstin": gstin, "phone": phone, "is_active": True},
            )

        product_rows = [
            ("AASH5000", "Aashirvaad Atta 5kg", "Grocery & Staples", "215.00", "190.00", 120, 20),
            ("FORT-OIL1L", "Fortune Oil 1L", "Grocery & Staples", "140.00", "125.00", 85, 20),
            ("AMULMILK-1L", "Amul Fresh Milk 1L", "Dairy & Bakery", "60.00", "52.00", 45, 15),
            ("TATA-SALT-1KG", "Tata Salt 1kg", "Grocery & Staples", "18.00", "15.00", 0, 10),
            ("SUN-MARIE-250", "Sunfeast Marie Biscuit 250g", "Snacks", "45.00", "40.00", 20, 20),
        ]
        items = {}
        for sku, name, category, selling, purchase, stock, reorder in product_rows:
            items[sku], _ = Item.objects.get_or_create(
                sku=sku,
                defaults={
                    "item_type": Item.ItemType.MATERIAL,
                    "name": name,
                    "category": categories[category],
                    "supplier": suppliers["Balaji Distributors"],
                    "unit": "Pack",
                    "selling_price": Decimal(selling),
                    "purchase_price": Decimal(purchase),
                    "tax_percent": Decimal("5.00"),
                    "stock_quantity": stock,
                    "reorder_level": reorder,
                    "is_active": True,
                },
            )

        customer, _ = Client.objects.get_or_create(
            name="Walk-in Customer",
            defaults={
                "contact_person": "Walk-in Customer",
                "whatsapp_mobile": "+919876543210",
                "billing_address": "Supermarket counter sale",
                "is_active": True,
            },
        )
        quotation, _ = Quotation.objects.get_or_create(
            number="QT-2025-0145",
            defaults={"client": customer, "created_by": admin},
        )
        QuotationItem.objects.update_or_create(
            quotation=quotation,
            item=items["AASH5000"],
            defaults={
                "name": items["AASH5000"].name,
                "sku": items["AASH5000"].sku,
                "quantity": 10,
                "unit_price": Decimal("365.00"),
            },
        )
        quotation.recalculate()
        DiscountApproval.objects.get_or_create(
            quotation=quotation,
            defaults={
                "requested_percent": Decimal("18.00"),
                "requested_by": User.objects.get(username="anita"),
                "request_note": "Festival offer for regular customer",
            },
        )

        invoice, _ = Invoice.objects.get_or_create(
            number="BILL-2025-0145",
            defaults={
                "client": customer,
                "created_by": admin,
                "invoice_date": timezone.localdate(),
                "due_date": timezone.localdate() + timedelta(days=15),
                "status": Invoice.Status.PAID,
                "subtotal": Decimal("3650.00"),
                "discount_amount": Decimal("0.00"),
                "taxable_amount": Decimal("3650.00"),
                "cgst_amount": Decimal("0.00"),
                "sgst_amount": Decimal("0.00"),
                "total": Decimal("3650.00"),
            },
        )
        InvoiceItem.objects.get_or_create(
            invoice=invoice,
            item=items["AASH5000"],
            defaults={
                "name": items["AASH5000"].name,
                "sku": items["AASH5000"].sku,
                "quantity": 1,
                "unit_price": Decimal("215.00"),
            },
        )
        Payment.objects.get_or_create(
            receipt_number="RCPT-2025-0145",
            defaults={
                "invoice": invoice,
                "payment_type": Payment.PaymentType.FULL,
                "method": Payment.Method.UPI,
                "amount": Decimal("3650.00"),
                "status": Payment.Status.VERIFIED,
                "collected_by": admin,
                "verified_by": admin,
                "verified_at": timezone.now(),
                "stock_processed": True,
            },
        )

        order, _ = PurchaseOrder.objects.get_or_create(
            number="PO-2025-0054",
            defaults={
                "supplier": suppliers["Balaji Distributors"],
                "created_by": admin,
                "status": PurchaseOrder.Status.PENDING,
            },
        )
        PurchaseOrderItem.objects.get_or_create(
            purchase_order=order,
            item=items["AASH5000"],
            defaults={"quantity": 50, "unit_cost": Decimal("210.00"), "tax_percent": Decimal("6.00")},
        )
        order.recalculate()

        WhatsAppMessage.objects.get_or_create(
            invoice=invoice,
            recipient=customer.whatsapp_mobile,
            message_type=WhatsAppMessage.MessageType.INVOICE,
            defaults={
                "message": f"Your invoice {invoice.number} is ready.",
                "status": WhatsAppMessage.Status.SENT,
                "sent_by": admin,
                "sent_at": timezone.now(),
            },
        )
        for action, module in [
            ("Login", "Auth"),
            ("Product catalogue prepared", "Products"),
            ("Purchase order created", "Purchase"),
        ]:
            if not AuditLog.objects.filter(
                user=admin,
                action=action,
                module=module,
            ).exists():
                AuditLog.objects.create(user=admin, action=action, module=module)

        self.stdout.write(self.style.SUCCESS("Admin flow starter data is ready."))
