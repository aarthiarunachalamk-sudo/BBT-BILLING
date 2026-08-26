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
    # dependencies are absent from django_migrations.  The first three are
    # essential migration *state*: without 0002 Django does not know Item
    # exists and crashes with KeyError before it can execute any migration.
    "0001_initial",
    # 0002_admin_flow replaces this filename. Django's migration loader checks
    # the replaced name when deciding whether the replacement is applied.
    "0002_admin_flow_models",
    "0002_admin_flow",
    "0003_item_expiry_date",
    "0004_item_catalog_details_and_sunflower_oil",
    "0005_item_manual_details",
    "0006_admin_visibility_inventory",
    "0007_brand_item_brand",
    "0008_brand_categories",
)
FIELD_NAMES = {
    Item: (
        "manual_details",
        "expiry_date",
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
PRODUCT_CATALOG_FIELDS = {
    # Migration 0013 was recorded without its DDL on some legacy Render
    # databases.  Item list queries select these columns, so either missing
    # column makes the whole product screen fail with a 500 response.
    Item: ("store_section", "rack_location"),
}
PRODUCT_CATALOG_MIGRATIONS = (
    "0013_item_store_section_item_rack_location",
    # Some legacy databases recorded the dependent migration without 0013.
    # In that state the columns should already exist and are safe to repair.
    "0014_secure_razorpay_payments",
)


def product_catalog_migration_is_applied():
    """Return whether migration history says the catalogue fields should exist."""
    return MigrationRecorder(connection).migration_qs.filter(
        app="billing", name__in=PRODUCT_CATALOG_MIGRATIONS
    ).exists()


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

    # A few legacy databases contain 0014 without its declared dependency
    # 0013. Django rejects that history before `migrate` can run, so restore
    # both the additive columns and dependency record during this pre-migrate
    # repair. Never fake 0013 on databases where no later migration proves it
    # was intended to be applied.
    catalog_migration = PRODUCT_CATALOG_MIGRATIONS[0]
    later_catalog_migration = PRODUCT_CATALOG_MIGRATIONS[1]
    if (
        recorder.migration_qs.filter(
            app="billing", name=later_catalog_migration
        ).exists()
        and not recorder.migration_qs.filter(
            app="billing", name=catalog_migration
        ).exists()
    ):
        repair_product_catalog_schema()
        recorder.record_applied("billing", catalog_migration)
        print(f"Repaired legacy billing migration record: {catalog_migration}")


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
    # Some Render services still use an older dashboard-level start command
    # that invokes only this repair after migrate. If 0013 is already marked
    # applied, restore its Item columns before any split-stock Item query.
    if product_catalog_migration_is_applied():
        repair_product_catalog_schema()

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
        # Location columns belong to migration 0013 and may still be absent
        # when this function is invoked by an older Render start command.
        for product in Item.objects.filter(
            item_type=Item.ItemType.MATERIAL
        ).defer("store_section", "rack_location").iterator():
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


def product_catalog_schema_status():
    """Return fields that can prevent the product catalogue from loading."""
    missing = []
    tables = set(connection.introspection.table_names())
    for model, names in PRODUCT_CATALOG_FIELDS.items():
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
    return missing


def repair_product_catalog_schema():
    """Idempotently restore product fields from an incorrectly faked 0013."""
    existing_tables = set(connection.introspection.table_names())
    with connection.schema_editor() as editor:
        for model, names in PRODUCT_CATALOG_FIELDS.items():
            table = model._meta.db_table
            if table not in existing_tables:
                continue
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
