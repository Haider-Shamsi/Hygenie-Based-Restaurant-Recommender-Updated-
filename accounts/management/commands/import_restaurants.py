import csv
from django.core.management.base import BaseCommand
from accounts.models import Restaurant
from datetime import datetime

class Command(BaseCommand):
    help = 'Import restaurants from restaurant_with_hygiene_score.csv'

    def handle(self, *args, **kwargs):
        with open('restaurant_with_hygiene_score.csv', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            count = 0
            for row in reader:
                # Parse date
                try:
                    inspection_date = datetime.strptime(row['InspectionDate'], '%Y-%m-%d').date()
                except Exception:
                    inspection_date = None
                # Create or update Restaurant
                obj, created = Restaurant.objects.update_or_create(
                    business_name=row['BusinessName'],
                    address=row['Address'],
                    defaults={
                        'business_type': row['BusinessType'],
                        'rating_value': row['RatingValue'],
                        'inspection_date': inspection_date,
                        'post_code': row['PostCode'],
                        'province': row['Province'],
                        'user_rating': float(row['user_rating']),
                        'hygiene_score': float(row['Hygiene_Score']),
                    }
                )
                count += 1
            self.stdout.write(self.style.SUCCESS(f'Successfully imported {count} restaurants.'))
