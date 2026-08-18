from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("billing", "0002_admin_flow")]

    operations = [
        migrations.AddField(
            model_name="item",
            name="expiry_date",
            field=models.DateField(blank=True, null=True),
        ),
    ]
