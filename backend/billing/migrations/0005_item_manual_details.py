from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("billing", "0004_item_catalog_details_and_sunflower_oil")]

    operations = [
        migrations.AddField(
            model_name="item",
            name="manual_details",
            field=models.JSONField(blank=True, default=dict),
        ),
    ]
