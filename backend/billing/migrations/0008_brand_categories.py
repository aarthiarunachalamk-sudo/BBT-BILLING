from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("billing", "0007_brand_item_brand")]

    operations = [
        migrations.AddField(
            model_name="brand",
            name="categories",
            field=models.ManyToManyField(blank=True, related_name="brands", to="billing.category"),
        ),
    ]
