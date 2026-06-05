from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='restaurant',
            name='admin_notes',
            field=models.TextField(blank=True),
        ),
    ]
