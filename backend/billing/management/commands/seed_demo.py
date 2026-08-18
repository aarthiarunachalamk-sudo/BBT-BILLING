from decimal import Decimal

from django.core.management.base import BaseCommand

from billing.models import Category, Client, Item, RolePermission, StoreSettings, Supplier, User


class Command(BaseCommand):
    help = "Create safe starter data for the BBT Billing application"

    def handle(self, *args, **options):
        admin, created = User.objects.get_or_create(
            username="admin",
            defaults={"email": "admin@supermart.com", "first_name": "Rahul", "last_name": "Kumar", "role": User.Role.ADMIN, "is_staff": True, "is_superuser": True},
        )
        if created:
            admin.set_password("admin123")
            admin.save()
        StoreSettings.objects.get_or_create(pk=1)
        permission_defaults = {
            "admin": dict.fromkeys(["products", "billing", "inventory", "discounts", "reports", "returns", "settings"], True),
            "cashier": {"products": True, "billing": True, "discounts": True, "returns": True},
            "inventory_manager": {"products": True, "inventory": True, "reports": True},
        }
        for role, defaults in permission_defaults.items():
            RolePermission.objects.get_or_create(role=role, defaults=defaults)
        services, _ = Category.objects.get_or_create(name="Services")
        networking, _ = Category.objects.get_or_create(name="Networking")
        supplier, _ = Supplier.objects.get_or_create(
            name="BitByte Default Supplier",
            defaults={"contact_person": "Purchase Team"},
        )

        starter_items = [
            {
                "sku": "CS-MON",
                "defaults": {
                    "name": "Cloud Support (Monthly)",
                    "item_type": Item.ItemType.SERVICE,
                    "category": services,
                    "selling_price": Decimal("15000.00"),
                    "purchase_price": Decimal("10000.00"),
                    "stock_quantity": 0,
                },
            },
            {
                "sku": "RTR-001",
                "defaults": {
                    "name": "Router",
                    "item_type": Item.ItemType.MATERIAL,
                    "category": networking,
                    "supplier": supplier,
                    "selling_price": Decimal("8500.00"),
                    "purchase_price": Decimal("6500.00"),
                    "stock_quantity": 24,
                },
            },
            {
                "sku": "NCB-CS",
                "defaults": {
                    "name": "Network Cable (Cat6)",
                    "item_type": Item.ItemType.MATERIAL,
                    "category": networking,
                    "supplier": supplier,
                    "unit": "metre",
                    "selling_price": Decimal("45.00"),
                    "purchase_price": Decimal("28.00"),
                    "stock_quantity": 156,
                },
            },
        ]
        for item_data in starter_items:
            Item.objects.get_or_create(**item_data)

        Client.objects.get_or_create(
            name="Acme Solutions Pvt. Ltd.",
            defaults={
                "contact_person": "Mr. Ankit Verma",
                "whatsapp_mobile": "+919876543210",
                "email": "ankit.verma@acmesolutions.com",
                "gstin": "27AABCA1234B1Z5",
                "billing_address": "S01, Skyline Tower, Andheri East, Mumbai - 400069, Maharashtra, India",
            },
        )
        self.stdout.write(self.style.SUCCESS("Starter categories, supplier, items, and client are ready."))
