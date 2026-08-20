from io import BytesIO
from decimal import Decimal

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from PIL import Image, ImageDraw, ImageFont

from billing.models import Category, Client, Item, RolePermission, StoreSettings, Supplier, User


class Command(BaseCommand):
    help = "Create or update the demo admin account and starter billing data."

    @staticmethod
    def _product_image(name, category):
        colors = {
            "Groceries": (31, 96, 168),
            "Beverages": (14, 137, 109),
            "Snacks": (224, 132, 32),
            "Household": (113, 82, 164),
        }
        background = colors.get(category, (31, 96, 168))
        image = Image.new("RGB", (800, 600), (246, 249, 253))
        draw = ImageDraw.Draw(image)
        draw.rounded_rectangle((30, 30, 770, 570), radius=36, fill=background)
        draw.ellipse((250, 85, 550, 385), fill=(255, 255, 255))
        draw.rounded_rectangle((315, 150, 485, 320), radius=24, fill=background)
        draw.rectangle((340, 180, 460, 290), fill=(255, 255, 255))
        font = ImageFont.load_default(size=32)
        small_font = ImageFont.load_default(size=24)
        draw.text((70, 420), name, fill=(255, 255, 255), font=font)
        draw.text((70, 480), category.upper(), fill=(220, 235, 250), font=small_font)
        output = BytesIO()
        image.save(output, format="PNG", optimize=True)
        return output.getvalue()

    def handle(self, *args, **options):
        admin, created = User.objects.get_or_create(
            username="admin",
            defaults={
                "email": "admin@supermart.com",
                "first_name": "Supermarket",
                "last_name": "Admin",
                "role": User.Role.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "is_active": True,
            },
        )
        admin.email = "admin@supermart.com"
        admin.role = User.Role.ADMIN
        admin.is_staff = True
        admin.is_superuser = True
        admin.is_active = True
        admin.set_password("admin123")
        admin.save()

        permission_defaults = {
            "dashboard": True,
            "products": True,
            "billing": True,
            "inventory": True,
            "discounts": True,
            "reports": True,
            "returns": True,
            "settings": True,
        }
        RolePermission.objects.update_or_create(
            role="admin", defaults=permission_defaults
        )
        for role in ("sales", "accountant", "inventory"):
            RolePermission.objects.get_or_create(
                role=role,
                defaults={
                    "dashboard": True,
                    "billing": role in {"sales", "accountant"},
                    "inventory": role == "inventory",
                    "reports": role == "accountant",
                },
            )

        StoreSettings.objects.get_or_create(
            pk=1,
            defaults={
                "store_name": "Supermarket",
                "invoice_prefix": "BILL-",
                "default_gst": Decimal("5.00"),
                "max_cashier_discount": Decimal("10.00"),
                "approval_threshold": Decimal("10.00"),
                "round_off": Decimal("0.01"),
            },
        )

        categories = {}
        for name, description in {
            "Groceries": "Rice, flour, pulses, and everyday staples",
            "Beverages": "Tea, coffee, and ready-to-drink beverages",
            "Snacks": "Packaged snacks and quick bites",
            "Household": "Cleaning and household essentials",
        }.items():
            categories[name], _ = Category.objects.get_or_create(
                name=name, defaults={"description": description}
            )
        supplier, _ = Supplier.objects.get_or_create(
            name="Demo Wholesale Supplier",
            defaults={
                "contact_person": "Demo Supplier",
                "phone": "9999999999",
                "email": "supplier@example.com",
                "address": "Demo supplier address",
            },
        )
        products = [
            ("DEMO-RICE-001", "Premium Rice 5kg", "Groceries", "Bag", "280.00", "340.00", "360.00", 25),
            ("DEMO-FLOUR-002", "Wheat Flour 5kg", "Groceries", "Bag", "190.00", "240.00", "260.00", 30),
            ("DEMO-DAL-003", "Toor Dal 1kg", "Groceries", "Pack", "110.00", "145.00", "155.00", 40),
            ("DEMO-OIL-004", "Sunflower Oil 1L", "Groceries", "Bottle", "105.00", "135.00", "145.00", 35),
            ("DEMO-TEA-005", "Premium Tea 250g", "Beverages", "Pack", "95.00", "125.00", "135.00", 20),
            ("DEMO-JUICE-006", "Mango Juice 1L", "Beverages", "Bottle", "70.00", "95.00", "105.00", 18),
            ("DEMO-BISCUIT-007", "Butter Biscuits 200g", "Snacks", "Pack", "25.00", "35.00", "40.00", 50),
            ("DEMO-CHIPS-008", "Classic Potato Chips 100g", "Snacks", "Pack", "20.00", "30.00", "35.00", 45),
            ("DEMO-SOAP-009", "Bath Soap 100g", "Household", "Piece", "28.00", "40.00", "45.00", 32),
            ("DEMO-DETERGENT-010", "Laundry Detergent 2kg", "Household", "Pack", "150.00", "195.00", "215.00", 22),
        ]
        for sku, name, category_name, unit, purchase, selling, mrp, stock in products:
            item, _ = Item.objects.get_or_create(
                sku=sku,
                defaults={
                    "item_type": Item.ItemType.MATERIAL,
                    "name": name,
                    "category": categories[category_name],
                    "supplier": supplier,
                    "unit": unit,
                    "purchase_price": Decimal(purchase),
                    "selling_price": Decimal(selling),
                    "mrp": Decimal(mrp),
                    "tax_percent": Decimal("5.00"),
                    "stock_quantity": stock,
                    "reorder_level": 5,
                },
            )
            if not item.image:
                item.image.save(
                    f"{sku.lower()}.png",
                    ContentFile(self._product_image(name, category_name)),
                    save=True,
                )
        Client.objects.get_or_create(
            name="Walk-in Customer",
            defaults={
                "contact_person": "Walk-in Customer",
                "whatsapp_mobile": "9999999999",
                "billing_address": "Counter sale",
            },
        )

        action = "Created" if created else "Updated"
        self.stdout.write(
            self.style.SUCCESS(
                f"{action} demo admin data. Login: admin@supermart.com / admin123"
            )
        )
