from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("billing", "0012_product_price_history")]

    operations = [
        migrations.AddField(
            model_name="item",
            name="store_section",
            field=models.CharField(db_index=True, default="General", max_length=100),
        ),
        migrations.AddField(
            model_name="item",
            name="rack_location",
            field=models.CharField(blank=True, db_index=True, max_length=60),
        ),
    ]
