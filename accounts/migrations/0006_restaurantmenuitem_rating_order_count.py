from django.db import migrations
from django.db import models
import django.core.validators


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0005_restaurantmenuitem_category_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='restaurantmenuitem',
            name='order_count',
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddField(
            model_name='restaurantmenuitem',
            name='rating',
            field=models.FloatField(default=0.0, validators=[django.core.validators.MinValueValidator(0), django.core.validators.MaxValueValidator(5)]),
        ),
    ]
