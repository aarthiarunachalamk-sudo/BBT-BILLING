from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("billing", "0013_item_store_section_item_rack_location")]

    operations = [
        migrations.AlterField(
            model_name="payment",
            name="method",
            field=models.CharField(
                choices=[
                    ("upi", "UPI"),
                    ("razorpay", "Razorpay"),
                    ("bank", "Bank Transfer"),
                    ("card", "Card"),
                    ("cash", "Cash"),
                ],
                max_length=10,
            ),
        ),
        migrations.AddConstraint(
            model_name="payment",
            constraint=models.UniqueConstraint(
                condition=models.Q(("method", "razorpay")),
                fields=("transaction_reference",),
                name="unique_razorpay_payment_reference",
            ),
        ),
    ]
