from decimal import Decimal
from pathlib import Path

from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand

from billing.models import Brand, Category, Item, Supplier


class Command(BaseCommand):
    help = "Create 20 category-aware brands and one matching sample product per brand."

    CATALOG = (
        ("India Gate", "KRBL Limited", "Groceries", "Basmati Rice 5 kg", "BR-INDIAGATE-RICE", "Bag", "620", "760", 18),
        ("Aashirvaad", "ITC Limited", "Groceries", "Whole Wheat Atta 5 kg", "BR-AASHIRVAAD-ATTA", "Bag", "245", "295", 24),
        ("Tata Sampann", "Tata Consumer Products", "Groceries", "Toor Dal 1 kg", "BR-TATA-TOORDAL", "Pack", "145", "175", 28),
        ("Sakthi Masala", "Sakthi Masala Private Limited", "Groceries", "Turmeric Powder 200 g", "BR-SAKTHI-TURMERIC", "Pack", "48", "62", 35),
        ("Aachi", "Aachi Group", "Spices", "Chilli Powder 500 g", "BR-AACHI-CHILLI", "Pack", "209", "247", 30),
        ("Fortune", "AWL Agri Business", "Edible Oils", "Sunflower Oil 1 L", "BR-FORTUNE-OIL", "Bottle", "125", "155", 32),
        ("Gold Winner", "Kaleesuwari Refinery", "Edible Oils", "Sunflower Oil 1 L", "BR-GOLDWINNER-OIL", "Pouch", "122", "150", 30),
        ("Tata Salt", "Tata Consumer Products", "Groceries", "Iodized Salt 1 kg", "BR-TATASALT-1KG", "Pack", "24", "30", 45),
        ("Amul", "GCMMF", "Dairy", "Fresh Milk 1 L", "BR-AMUL-MILK", "Carton", "58", "66", 25),
        ("Britannia", "Britannia Industries", "Snacks", "Good Day Biscuits 200 g", "BR-BRITANNIA-BISCUIT", "Pack", "32", "40", 40),
        ("Parle", "Parle Products", "Snacks", "Parle-G Biscuits 250 g", "BR-PARLE-BISCUIT", "Pack", "22", "30", 48),
        ("Sunfeast", "ITC Limited", "Snacks", "Marie Light Biscuits 250 g", "BR-SUNFEAST-BISCUIT", "Pack", "30", "38", 36),
        ("Nestle", "Nestle India", "Instant Foods", "Maggi Noodles 280 g", "BR-NESTLE-NOODLES", "Pack", "55", "68", 42),
        ("BRU", "Hindustan Unilever", "Beverages", "Instant Coffee 200 g", "BR-BRU-COFFEE", "Jar", "175", "210", 22),
        ("Red Label", "Hindustan Unilever", "Beverages", "Tea 250 g", "BR-REDLABEL-TEA", "Pack", "125", "155", 24),
        ("Dove", "Hindustan Unilever", "Personal Care", "Cream Beauty Bathing Bar 100 g", "BR-DOVE-SOAP", "Piece", "52", "65", 34),
        ("Lux", "Hindustan Unilever", "Personal Care", "Fragrant Bathing Soap 100 g", "BR-LUX-SOAP", "Piece", "31", "40", 38),
        ("Surf Excel", "Hindustan Unilever", "Household", "Detergent Powder 1 kg", "BR-SURFEXCEL-DETERGENT", "Pack", "118", "145", 26),
        ("Ariel", "Procter & Gamble", "Household", "Matic Detergent 1 kg", "BR-ARIEL-DETERGENT", "Pack", "185", "225", 20),
        ("Colgate", "Colgate-Palmolive", "Personal Care", "Strong Teeth Toothpaste 200 g", "BR-COLGATE-PASTE", "Tube", "92", "115", 30),
    )

    IMAGE_BY_SKU = {
        "BR-INDIAGATE-RICE": "india-gate-rice-5kg.png",
        "BR-AASHIRVAAD-ATTA": "aashirvaad-atta-5kg.png",
        "BR-TATA-TOORDAL": "tata-sampann-toor-dal-1kg.png",
        "BR-SAKTHI-TURMERIC": "sakthi-turmeric-200g.png",
        "BR-AACHI-CHILLI": "aachi-chilli-500g-official.webp",
        "BR-FORTUNE-OIL": "fortune-sunflower-oil-1l.png",
        "BR-GOLDWINNER-OIL": "gold-winner-sunflower-oil-1l.png",
        "BR-TATASALT-1KG": "tata-salt-1kg.png",
        "BR-AMUL-MILK": "amul-milk-1l.png",
        "BR-BRITANNIA-BISCUIT": "britannia-good-day-200g.png",
        "BR-PARLE-BISCUIT": "parle-g-250g.png",
        "BR-SUNFEAST-BISCUIT": "sunfeast-marie-250g.png",
        "BR-NESTLE-NOODLES": "nestle-maggi-280g.png",
        "BR-BRU-COFFEE": "bru-coffee-200g.png",
        "BR-REDLABEL-TEA": "red-label-tea-250g.png",
        "BR-DOVE-SOAP": "dove-soap-100g.png",
        "BR-LUX-SOAP": "lux-soap-100g.png",
        "BR-SURFEXCEL-DETERGENT": "surf-excel-1kg.png",
        "BR-ARIEL-DETERGENT": "ariel-matic-1kg.png",
        "BR-COLGATE-PASTE": "colgate-200g.png",
    }

    def add_arguments(self, parser):
        parser.add_argument(
            "--replace-images",
            action="store_true",
            help="Replace catalog images with exact brand/product/quantity assets.",
        )

    def handle(self, *args, **options):
        image_directory = Path(__file__).with_name("brand_product_images")
        supplier, _ = Supplier.objects.get_or_create(
            name="National FMCG Distributor",
            defaults={"contact_person": "Catalog Supply", "phone": "9999999999"},
        )
        created_products = 0
        for brand_name, manufacturer, category_name, product_name, sku, unit, purchase, selling, stock in self.CATALOG:
            category, _ = Category.objects.get_or_create(
                name=category_name,
                defaults={"description": f"{category_name} supermarket products"},
            )
            brand, _ = Brand.objects.update_or_create(
                name=brand_name,
                defaults={
                    "manufacturer": manufacturer,
                    "country": "India",
                    "description": f"{brand_name} products available at BBT Supermarket.",
                    "is_active": True,
                },
            )
            brand.categories.add(category)
            item, created = Item.objects.update_or_create(
                sku=sku,
                defaults={
                    "item_type": Item.ItemType.MATERIAL,
                    "name": product_name,
                    "category": category,
                    "brand": brand,
                    "supplier": supplier,
                    "unit": unit,
                    "manual_details": {"brand": brand_name},
                    "purchase_price": Decimal(purchase),
                    "selling_price": Decimal(selling),
                    "mrp": Decimal(selling) + Decimal("10.00"),
                    "tax_percent": Decimal("5.00"),
                    "stock_quantity": stock,
                    "store_stock": stock,
                    "reorder_level": 5,
                    "is_active": True,
                },
            )
            if not item.image or options["replace_images"]:
                image_path = image_directory / self.IMAGE_BY_SKU[sku]
                item.image.save(
                    f"brand-catalog-{sku.lower()}{image_path.suffix}",
                    ContentFile(image_path.read_bytes()),
                    save=True,
                )
            created_products += int(created)

        legacy_assignments = {
            "WT-RICE-5KG": "India Gate", "WT-FLOUR-5KG": "Aashirvaad",
            "WT-TOOR-DAL-1KG": "Tata Sampann", "WT-URAD-DAL-1KG": "Tata Sampann",
            "WT-SUGAR-1KG": "Tata Sampann",
            "WT-SALT-1KG": "Tata Salt", "WT-TURMERIC-250G": "Sakthi Masala",
            "WT-CHILLI-500G": "Aachi", "WT-TEA-250G": "Red Label",
            "WT-COFFEE-200G": "BRU",
        }
        for sku, brand_name in legacy_assignments.items():
            Item.objects.filter(sku=sku).update(brand=Brand.objects.get(name=brand_name))
        Brand.objects.filter(name__in=("BBT Select", "Golden Harvest", "Daily Choice", "BBT Brew"), items__isnull=True).delete()
        self.stdout.write(self.style.SUCCESS(f"20 brands ready; {created_products} sample products created."))
