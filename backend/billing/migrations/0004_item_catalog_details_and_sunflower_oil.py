from datetime import date
from decimal import Decimal

from django.db import migrations, models


PRODUCT_SKU = "FORTUNE-SUNLITE-840G"


def add_sunflower_oil(apps, schema_editor):
    Category = apps.get_model("billing", "Category")
    Item = apps.get_model("billing", "Item")
    category, _ = Category.objects.get_or_create(
        name="Edible Oils",
        defaults={
            "description": "Cooking oils and edible oil products",
            "is_active": True,
        },
    )
    Item.objects.update_or_create(
        sku=PRODUCT_SKU,
        defaults={
            "item_type": "material",
            "name": "Fortune Sunlite Refined Sunflower Oil 840 g",
            "description": (
                "Fortune Sunlite refined sunflower oil pouch. Retail price "
                "verified against the linked BigBasket listing."
            ),
            "category": category,
            "unit": "Pouch",
            "purchase_price": Decimal("145.50"),
            "selling_price": Decimal("145.50"),
            "mrp": Decimal("190.00"),
            "tax_percent": Decimal("5.00"),
            "stock_quantity": 24,
            "reorder_level": 6,
            "is_active": True,
            "price_source_url": (
                "https://www.bigbasket.com/pd/40361379/"
                "fortune-sunlite-refined-sunflower-oil-840-g/"
            ),
            "price_verified_at": date(2026, 8, 19),
        },
    )


def remove_sunflower_oil(apps, schema_editor):
    Item = apps.get_model("billing", "Item")
    Item.objects.filter(sku=PRODUCT_SKU).delete()


class Migration(migrations.Migration):
    dependencies = [("billing", "0003_item_expiry_date")]

    operations = [
        migrations.AddField(
            model_name="item",
            name="image",
            field=models.ImageField(blank=True, upload_to="products/%Y/%m/"),
        ),
        migrations.AddField(
            model_name="item",
            name="mrp",
            field=models.DecimalField(
                blank=True, decimal_places=2, max_digits=14, null=True
            ),
        ),
        migrations.AddField(
            model_name="item",
            name="price_source_url",
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name="item",
            name="price_verified_at",
            field=models.DateField(blank=True, null=True),
        ),
        migrations.RunPython(add_sunflower_oil, remove_sunflower_oil),
    ]
