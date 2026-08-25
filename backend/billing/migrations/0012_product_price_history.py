from decimal import Decimal

from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("billing", "0011_migrate_split_stock_data")]

    operations = [
        migrations.CreateModel(
            name="ProductPriceHistory",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("purchase_price", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=14)),
                ("selling_price", models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=14)),
                ("tax_percent", models.DecimalField(decimal_places=2, default=Decimal("18.00"), max_digits=5)),
                ("effective_date", models.DateField(db_index=True)),
                ("created_by", models.ForeignKey(blank=True, null=True, on_delete=models.deletion.SET_NULL, related_name="product_price_changes", to=settings.AUTH_USER_MODEL)),
                ("item", models.ForeignKey(on_delete=models.deletion.CASCADE, related_name="price_history", to="billing.item")),
            ],
            options={"ordering": ["-effective_date", "-created_at"]},
        ),
        migrations.AddConstraint(model_name="productpricehistory", constraint=models.UniqueConstraint(fields=("item", "effective_date"), name="unique_item_price_effective_date")),
    ]
