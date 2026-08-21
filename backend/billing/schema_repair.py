"""Targeted recovery for legacy Render databases with broken migration history."""

from django.db import connection
from django.db.migrations.recorder import MigrationRecorder
from django.db.models import F

from .models import AuditLog, Item, Payment, ProductBatch, StockAdjustment, StockReview, User


MIGRATION = "0006_admin_visibility_inventory"


def repair_admin_visibility_schema():
    """Idempotently create only the columns/tables introduced by migration 0006."""
    existing_tables = set(connection.introspection.table_names())
    field_names = {
        Item: ("barcode", "last_stock_review_date", "shelf_added_date", "shelf_stock", "store_stock"),
        Payment: ("balance_returned", "cash_received"),
        User: ("branch", "employee_id", "last_logout"),
        AuditLog: ("description",),
    }
    with connection.schema_editor() as editor:
        for model, names in field_names.items():
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

        for model in (StockAdjustment, StockReview, ProductBatch):
            if model._meta.db_table not in existing_tables:
                editor.create_model(model)
                existing_tables.add(model._meta.db_table)

    Item.objects.filter(store_stock=0, shelf_stock=0, stock_quantity__gt=0).update(
        store_stock=F("stock_quantity")
    )
    MigrationRecorder(connection).record_applied("billing", MIGRATION)
