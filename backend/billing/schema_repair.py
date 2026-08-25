"""Targeted recovery for legacy Render databases with broken migration history."""

from django.db import connection, transaction
from django.db.migrations.recorder import MigrationRecorder
from django.db.models import F
from django.utils import timezone

from .models import (
    AuditLog,
    Brand,
    Item,
    Payment,
    ProductBatch,
    ShelfStock,
    StockAdjustment,
    StockMovement,
    StockReview,
    StoreSettings,
    StoreStock,
    User,
)


MIGRATIONS = (
    # Legacy Render databases may have later migrations recorded while these
    # additive dependencies are absent from django_migrations.
    "0004_item_catalog_details_and_sunflower_oil",
    "0005_item_manual_details",
    "0006_admin_visibility_inventory",
    "0007_brand_item_brand",
    "0008_brand_categories",
)
FIELD_NAMES = {
    Item: (
        "manual_details",
        "barcode",
        "image",
        "mrp",
        "price_source_url",
        "price_verified_at",
        "last_stock_review_date",
        "shelf_added_date",
        "shelf_stock",
        "store_stock",
        "brand",
    ),
    Payment: ("balance_returned", "cash_received"),
    User: ("branch", "employee_id", "last_logout"),
    AuditLog: ("description",),
}
NEW_MODELS = (StockAdjustment, StockReview, ProductBatch, Brand)
SPLIT_STOCK_MODELS = (StoreStock, ShelfStock, StockMovement)


def admin_visibility_schema_status():
    missing = []
    tables = set(connection.introspection.table_names())
    for model, names in FIELD_NAMES.items():
        table = model._meta.db_table
        if table not in tables:
            missing.append(table)
            continue
        with connection.cursor() as cursor:
            columns = {
                column.name
                for column in connection.introspection.get_table_description(cursor, table)
            }
        missing.extend(
            f"{table}.{model._meta.get_field(name).column}"
            for name in names
            if model._meta.get_field(name).column not in columns
        )
    missing.extend(model._meta.db_table for model in NEW_MODELS if model._meta.db_table not in tables)
    brand_categories_table = Brand._meta.get_field("categories").remote_field.through._meta.db_table
    if brand_categories_table not in tables:
        missing.append(brand_categories_table)
    return missing


def repair_admin_visibility_schema():
    """Idempotently create additive admin and brand schema for legacy databases."""
    existing_tables = set(connection.introspection.table_names())
    with connection.schema_editor() as editor:
        for model in NEW_MODELS:
            if model._meta.db_table not in existing_tables:
                editor.create_model(model)
                existing_tables.add(model._meta.db_table)
                existing_tables.update(
                    field.remote_field.through._meta.db_table
                    for field in model._meta.local_many_to_many
                )

        brand_categories = Brand._meta.get_field("categories").remote_field.through
        if brand_categories._meta.db_table not in existing_tables:
            editor.create_model(brand_categories)
            existing_tables.add(brand_categories._meta.db_table)

        for model, names in FIELD_NAMES.items():
            table = model._meta.db_table
            with connection.cursor() as cursor:
                columns = {
                    column.name
                    for column in connection.introspection.get_table_description(cursor, table)
                }
            for name in names:
                field = model._meta.get_field(name)
                if field.column not in columns:
                    editor.add_field(model, field)
                    columns.add(field.column)

    Item.objects.filter(store_stock=0, shelf_stock=0, stock_quantity__gt=0).update(
        store_stock=F("stock_quantity")
    )
    # This repair runs before the normal migration chain. Legacy databases may
    # not yet have the later location columns, so do not select them here.
    for item in Item.objects.filter(brand__isnull=True).defer(
        "store_section", "rack_location"
    ).iterator():
        brand_name = str((item.manual_details or {}).get("brand", "")).strip()
        if brand_name:
            brand, _ = Brand.objects.get_or_create(name=brand_name)
            item.brand = brand
            item.save(update_fields=["brand"])
    recorder = MigrationRecorder(connection)
    for migration in MIGRATIONS:
        if not recorder.migration_qs.filter(app="billing", name=migration).exists():
            recorder.record_applied("billing", migration)
            print(f"Repaired legacy billing migration record: {migration}")


def split_stock_schema_status():
    """Return missing split-stock tables/fields for legacy databases."""
    missing = []
    tables = set(connection.introspection.table_names())
    missing.extend(model._meta.db_table for model in SPLIT_STOCK_MODELS if model._meta.db_table not in tables)
    settings_table = StoreSettings._meta.db_table
    if settings_table in tables:
        with connection.cursor() as cursor:
            columns = {column.name for column in connection.introspection.get_table_description(cursor, settings_table)}
        field = StoreSettings._meta.get_field("auto_refill_enabled")
        if field.column not in columns:
            missing.append(f"{settings_table}.{field.column}")
    return missing


def repair_split_stock_schema():
    """Repair migrations marked applied before the split-stock tables existed.

    Some legacy Render databases have migration 0010/0011 in django_migrations
    even though their DDL was never committed.  This is deliberately
    idempotent so it is safe to execute at every deployment.
    """
    existing_tables = set(connection.introspection.table_names())
    with connection.schema_editor() as editor:
        for model in SPLIT_STOCK_MODELS:
            if model._meta.db_table not in existing_tables:
                editor.create_model(model)
                existing_tables.add(model._meta.db_table)

        settings_table = StoreSettings._meta.db_table
        if settings_table in existing_tables:
            with connection.cursor() as cursor:
                columns = {column.name for column in connection.introspection.get_table_description(cursor, settings_table)}
            field = StoreSettings._meta.get_field("auto_refill_enabled")
            if field.column not in columns:
                editor.add_field(StoreSettings, field)

    # Migration 0011 cannot backfill data when it was incorrectly recorded as
    # applied.  Create only missing per-product records; existing production
    # quantities and movement history are never overwritten or duplicated.
    with transaction.atomic():
        for product in Item.objects.filter(item_type=Item.ItemType.MATERIAL).iterator():
            store_quantity = product.store_stock
            shelf_quantity = product.shelf_stock
            if store_quantity == 0 and shelf_quantity == 0 and product.stock_quantity:
                store_quantity = product.stock_quantity
            store, store_created = StoreStock.objects.get_or_create(
                product=product,
                branch="Main Branch",
                defaults={"quantity": store_quantity, "minimum_quantity": product.reorder_level},
            )
            shelf, shelf_created = ShelfStock.objects.get_or_create(
                product=product,
                branch="Main Branch",
                defaults={
                    "quantity": shelf_quantity,
                    "target_quantity": shelf_quantity,
                    "minimum_quantity": min(product.reorder_level, shelf_quantity),
                    "shelf_added_date": timezone.now() if shelf_quantity else None,
                },
            )
            if store_created and store.quantity:
                StockMovement.objects.create(
                    product=product, branch="Main Branch", movement_type=StockMovement.MovementType.INITIAL_STORE_STOCK,
                    source_location="", destination_location="STORE", quantity=store.quantity,
                    store_before=0, store_after=store.quantity, shelf_before=0, shelf_after=0,
                    reference_type="MIGRATION_REPAIR", reference_id=str(product.pk),
                    notes="Recovered from legacy Item store stock.",
                )
            if shelf_created and shelf.quantity:
                StockMovement.objects.create(
                    product=product, branch="Main Branch", movement_type=StockMovement.MovementType.INITIAL_SHELF_STOCK,
                    source_location="", destination_location="SHELF", quantity=shelf.quantity,
                    store_before=store.quantity, store_after=store.quantity, shelf_before=0, shelf_after=shelf.quantity,
                    reference_type="MIGRATION_REPAIR", reference_id=str(product.pk),
                    notes="Recovered from legacy Item shelf stock.",
                )
