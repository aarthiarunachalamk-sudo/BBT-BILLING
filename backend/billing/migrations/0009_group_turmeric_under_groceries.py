from django.db import migrations


def group_turmeric_under_groceries(apps, schema_editor):
    Category = apps.get_model("billing", "Category")
    Item = apps.get_model("billing", "Item")
    groceries, _ = Category.objects.get_or_create(
        name="Groceries",
        defaults={"description": "Rice, flour, pulses, spices, and everyday staples"},
    )
    Item.objects.filter(name__icontains="turmeric").update(category=groceries)


class Migration(migrations.Migration):
    dependencies = [("billing", "0008_brand_categories")]

    operations = [migrations.RunPython(group_turmeric_under_groceries, migrations.RunPython.noop)]
