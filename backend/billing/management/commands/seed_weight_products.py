from decimal import Decimal

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand

from billing.management.commands.seed_demo import Command as DemoSeedCommand
from billing.models import Category, Item, Supplier


class Command(BaseCommand):
    help = "Add or update ten gram/kg grocery products with catalog images."

    PRODUCTS = (
        ("WT-RICE-5KG", "Premium Rice 5 kg", "Groceries", "Kg", "5 kg", "280.00", "340.00", "360.00", 25),
        ("WT-FLOUR-5KG", "Wheat Flour 5 kg", "Groceries", "Kg", "5 kg", "190.00", "240.00", "260.00", 30),
        ("WT-TOOR-DAL-1KG", "Toor Dal 1 kg", "Groceries", "Kg", "1 kg", "110.00", "145.00", "155.00", 40),
        ("WT-URAD-DAL-1KG", "Urad Dal 1 kg", "Groceries", "Kg", "1 kg", "120.00", "155.00", "165.00", 35),
        ("WT-SUGAR-1KG", "White Sugar 1 kg", "Groceries", "Kg", "1 kg", "42.00", "50.00", "55.00", 50),
        ("WT-SALT-1KG", "Iodized Salt 1 kg", "Groceries", "Kg", "1 kg", "18.00", "24.00", "28.00", 60),
        ("WT-TURMERIC-250G", "Turmeric Powder 250 g", "Groceries", "Gram", "250 g", "35.00", "45.00", "50.00", 40),
        ("WT-CHILLI-500G", "Chilli Powder 500 g", "Groceries", "Gram", "500 g", "95.00", "125.00", "135.00", 30),
        ("WT-TEA-250G", "Premium Tea 250 g", "Beverages", "Gram", "250 g", "95.00", "125.00", "135.00", 20),
        ("WT-COFFEE-200G", "Instant Coffee 200 g", "Beverages", "Gram", "200 g", "140.00", "180.00", "195.00", 20),
    )

    def handle(self, *args, **options):
        categories = {}
        for name in ("Groceries", "Beverages"):
            categories[name], _ = Category.objects.get_or_create(
                name=name,
                defaults={"description": "Products sold by gram or kilogram"},
            )
        supplier, _ = Supplier.objects.get_or_create(
            name="BBT Grocery Supplier",
            defaults={
                "contact_person": "Store Supplier",
                "phone": "9999999999",
                "email": "supplier@example.com",
                "address": "Local wholesale market",
            },
        )

        created_count = 0
        updated_count = 0
        for sku, name, category_name, unit, size, purchase, selling, mrp, stock in self.PRODUCTS:
            item, created = Item.objects.update_or_create(
                sku=sku,
                defaults={
                    "item_type": Item.ItemType.MATERIAL,
                    "name": name,
                    "category": categories[category_name],
                    "supplier": supplier,
                    "unit": unit,
                    "manual_details": {"size": size},
                    "purchase_price": Decimal(purchase),
                    "selling_price": Decimal(selling),
                    "mrp": Decimal(mrp),
                    "tax_percent": Decimal("5.00"),
                    "stock_quantity": stock,
                    "reorder_level": 5,
                    "is_active": True,
                },
            )
            if not item.image:
                image_bytes = DemoSeedCommand._product_image(name, category_name)
                item.image.save(f"{sku.lower()}.png", ContentFile(image_bytes), save=True)
            created_count += int(created)
            updated_count += int(not created)

        self.stdout.write(
            self.style.SUCCESS(
                f"Weight products ready: {created_count} created, {updated_count} updated."
            )
        )
