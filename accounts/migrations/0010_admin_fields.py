from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0009_restaurant_owner_profile_fields_inspection_request'),
    ]

    operations = [
        migrations.AddField(
            model_name='restaurant',
            name='status',
            field=models.CharField(choices=[('active', 'Active'), ('suspended', 'Suspended'), ('under_review', 'Under Review')], default='active', max_length=20),
        ),
        migrations.AddField(
            model_name='restaurantreview',
            name='moderation_status',
            field=models.CharField(choices=[('pending', 'Pending'), ('approved', 'Approved'), ('removed', 'Removed'), ('dismissed', 'Dismissed')], default='pending', max_length=20),
        ),
    ]
