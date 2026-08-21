"""Targeted recovery for legacy Render databases with broken migration history."""

from django.db import connection
from django.db.migrations.recorder import MigrationRecorder
from django.db.models import F

from .models import AuditLog, Item, Payment, ProductBatch, StockAdjustment, StockReview, User


MIGRATION = "0006_admin_visibility_inventory"
FIELD_NAMES = {
    Item: (
        "manual_details",
        "barcode",
        "last_stock_review_date",
        "shelf_added_date",
        "shelf_stock",
        "store_stock",
    ),
    Payment: ("balance_returned", "cash_received"),
    User: ("branch", "employee_id", "last_logout"),
    AuditLog: ("description",),
}
NEW_MODELS = (StockAdjustment, StockReview, ProductBatch)


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
    return missing


def repair_admin_visibility_schema():
    """Idempotently create only the columns/tables introduced by migration 0006."""
    existing_tables = set(connection.introspection.table_names())
    with connection.schema_editor() as editor:
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

        for model in NEW_MODELS:
            if model._meta.db_table not in existing_tables:
                editor.create_model(model)
                existing_tables.add(model._meta.db_table)

    Item.objects.filter(store_stock=0, shelf_stock=0, stock_quantity__gt=0).update(
        store_stock=F("stock_quantity")
    )
    MigrationRecorder(connection).record_applied("billing", MIGRATION)
