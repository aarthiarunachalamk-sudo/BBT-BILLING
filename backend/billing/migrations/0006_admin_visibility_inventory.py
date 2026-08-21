import django.db.models.deletion
import django.utils.timezone
from decimal import Decimal
from django.conf import settings
from django.db import migrations, models


def copy_existing_stock(apps, schema_editor):
    Item = apps.get_model("billing", "Item")
    for item in Item.objects.all().iterator():
        item.store_stock = max(item.stock_quantity, 0)
        item.save(update_fields=["store_stock"])


class Migration(migrations.Migration):
    dependencies = [("billing", "0005_item_manual_details")]
    operations = [
        migrations.AddField(model_name="auditlog", name="description", field=models.TextField(blank=True)),
        migrations.AddField(model_name="item", name="barcode", field=models.CharField(blank=True, db_index=True, max_length=80, null=True, unique=True)),
        migrations.AddField(model_name="item", name="last_stock_review_date", field=models.DateField(blank=True, null=True)),
        migrations.AddField(model_name="item", name="shelf_added_date", field=models.DateField(blank=True, null=True)),
        migrations.AddField(model_name="item", name="shelf_stock", field=models.PositiveIntegerField(default=0)),
        migrations.AddField(model_name="item", name="store_stock", field=models.PositiveIntegerField(default=0)),
        migrations.RunPython(copy_existing_stock, migrations.RunPython.noop),
        migrations.AddField(model_name="payment", name="balance_returned", field=models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=14)),
        migrations.AddField(model_name="payment", name="cash_received", field=models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=14)),
        migrations.AddField(model_name="user", name="branch", field=models.CharField(default="Main Branch", max_length=120)),
        migrations.AddField(model_name="user", name="employee_id", field=models.CharField(blank=True, db_index=True, max_length=30, null=True, unique=True)),
        migrations.AddField(model_name="user", name="last_logout", field=models.DateTimeField(blank=True, null=True)),
        migrations.AlterField(model_name="user", name="role", field=models.CharField(choices=[("sales", "Sales"), ("accountant", "Accountant"), ("inventory", "Inventory"), ("manager", "Store Manager"), ("cashier", "Cashier"), ("admin", "Admin")], default="sales", max_length=20)),
        migrations.CreateModel(
            name="StockAdjustment",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)), ("updated_at", models.DateTimeField(auto_now=True)),
                ("previous_quantity", models.IntegerField()), ("new_quantity", models.IntegerField()),
                ("difference", models.IntegerField()), ("reason", models.TextField()),
                ("adjusted_by", models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="stock_adjustments", to=settings.AUTH_USER_MODEL)),
                ("item", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="stock_adjustments", to="billing.item")),
            ], options={"ordering": ["-created_at"]},
        ),
        migrations.CreateModel(
            name="StockReview",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)), ("updated_at", models.DateTimeField(auto_now=True)),
                ("system_quantity", models.IntegerField()), ("physical_quantity", models.IntegerField()),
                ("difference", models.IntegerField(default=0)),
                ("status", models.CharField(choices=[("due", "Due"), ("updated", "Updated"), ("overdue", "Overdue")], default="updated", max_length=12)),
                ("reviewed_at", models.DateTimeField(default=django.utils.timezone.now)),
                ("next_review_date", models.DateField(db_index=True)),
                ("item", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="stock_reviews", to="billing.item")),
                ("reviewed_by", models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="stock_reviews", to=settings.AUTH_USER_MODEL)),
            ], options={"ordering": ["next_review_date"]},
        ),
        migrations.CreateModel(
            name="ProductBatch",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)), ("updated_at", models.DateTimeField(auto_now=True)),
                ("batch_number", models.CharField(db_index=True, max_length=80)),
                ("quantity", models.PositiveIntegerField(default=0)),
                ("manufactured_date", models.DateField(blank=True, null=True)),
                ("expiry_date", models.DateField(db_index=True)),
                ("purchase_date", models.DateField(default=django.utils.timezone.localdate)),
                ("shelf_quantity", models.PositiveIntegerField(default=0)),
                ("status", models.CharField(default="active", max_length=20)),
                ("item", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="batches", to="billing.item")),
                ("supplier", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to="billing.supplier")),
            ], options={"ordering": ["expiry_date"], "constraints": [models.UniqueConstraint(fields=("item", "batch_number"), name="unique_item_batch")]},
        ),
    ]
