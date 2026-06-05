from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0011_merge_0002_restaurant_admin_notes_0010_admin_fields'),
    ]

    operations = [
        migrations.AddField(
            model_name='restaurantreview',
            name='admin_note',
            field=models.TextField(blank=True),
        ),
    ]
