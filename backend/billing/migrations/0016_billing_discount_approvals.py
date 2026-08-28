from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [("billing", "0015_rack_item_rack")]

    operations = [
        migrations.AlterField(
            model_name="discountapproval",
            name="quotation",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="approvals",
                to="billing.quotation",
            ),
        ),
        migrations.AddField(
            model_name="discountapproval",
            name="billing_items",
            field=models.JSONField(blank=True, default=list),
        ),
        migrations.AddField(
            model_name="discountapproval",
            name="billing_subtotal",
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=14, null=True),
        ),
        migrations.AddField(
            model_name="discountapproval",
            name="billing_tax",
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=14, null=True),
        ),
        migrations.AddField(
            model_name="discountapproval",
            name="billing_total",
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=14, null=True),
        ),
        migrations.AddField(
            model_name="discountapproval",
            name="applied_invoice",
            field=models.OneToOneField(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="discount_approval",
                to="billing.invoice",
            ),
        ),
    ]
