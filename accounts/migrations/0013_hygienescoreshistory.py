from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('accounts', '0012_restaurantreview_admin_note'),
    ]

    operations = [
        migrations.CreateModel(
            name='HygieneScoreHistory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('score', models.FloatField()),
                ('previous_score', models.FloatField(blank=True, null=True)),
                ('source', models.CharField(default='nlp_update', max_length=40)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('restaurant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='hygiene_score_history', to='accounts.restaurant')),
            ],
            options={
                'ordering': ['created_at'],
            },
        ),
    ]
