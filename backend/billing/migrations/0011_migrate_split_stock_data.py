from django.db import migrations
from django.utils import timezone


def migrate_split_stock(apps, schema_editor):
    Item = apps.get_model("billing", "Item")
    StoreStock = apps.get_model("billing", "StoreStock")
    ShelfStock = apps.get_model("billing", "ShelfStock")
    StockMovement = apps.get_model("billing", "StockMovement")
    for product in Item.objects.filter(item_type="material").iterator():
        store_quantity = product.store_stock
        shelf_quantity = product.shelf_stock
        if store_quantity == 0 and shelf_quantity == 0 and product.stock_quantity:
            store_quantity = product.stock_quantity
        store, _ = StoreStock.objects.get_or_create(
            product=product,
            branch="Main Branch",
            defaults={"quantity": store_quantity, "minimum_quantity": product.reorder_level},
        )
        shelf, _ = ShelfStock.objects.get_or_create(
            product=product,
            branch="Main Branch",
            defaults={
                "quantity": shelf_quantity,
                "target_quantity": shelf_quantity,
                "minimum_quantity": min(product.reorder_level, shelf_quantity),
                "shelf_added_date": timezone.now() if shelf_quantity else None,
            },
        )
        if store.quantity:
            StockMovement.objects.create(
                product=product, branch="Main Branch", movement_type="INITIAL_STORE_STOCK",
                source_location="", destination_location="STORE", quantity=store.quantity,
                store_before=0, store_after=store.quantity,
                shelf_before=0, shelf_after=0,
                reference_type="MIGRATION", reference_id=str(product.pk),
                notes="Migrated from legacy Item store stock.",
            )
        if shelf.quantity:
            StockMovement.objects.create(
                product=product, branch="Main Branch", movement_type="INITIAL_SHELF_STOCK",
                source_location="", destination_location="SHELF", quantity=shelf.quantity,
                store_before=store.quantity, store_after=store.quantity,
                shelf_before=0, shelf_after=shelf.quantity,
                reference_type="MIGRATION", reference_id=str(product.pk),
                notes="Migrated from legacy Item shelf stock.",
            )


class Migration(migrations.Migration):
    dependencies = [("billing", "0010_separate_store_and_shelf_stock")]
    operations = [migrations.RunPython(migrate_split_stock, migrations.RunPython.noop)]
