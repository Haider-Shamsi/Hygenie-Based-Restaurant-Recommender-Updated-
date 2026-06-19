import csv
from decimal import Decimal, InvalidOperation
from pathlib import Path

from django.core.management.base import BaseCommand
from django.db import transaction

from accounts.models import Restaurant
from accounts.models import RestaurantMenuItem


class Command(BaseCommand):
    help = 'Load restaurant menu items from menu_data_updated.csv'

    def add_arguments(self, parser):
        parser.add_argument(
            '--path',
            default='menu_data_updated.csv',
            help='Path to CSV file (default: menu_data_updated.csv)',
        )
        parser.add_argument(
            '--replace',
            action='store_true',
            help='Delete existing menu items before loading.',
        )

    def handle(self, *args, **options):
        csv_path = Path(options['path'])
        if not csv_path.exists():
            self.stderr.write(f'CSV file not found: {csv_path}')
            return

        # Fetch all restaurants sorted by ID to match their sequential insertion order
        restaurants = list(Restaurant.objects.all().order_by('id'))
        
        # Build mapping from original business names to Django Restaurant model instances
        old_name_to_restaurant = {}
        try:
            with open('Updated_restaurant_with_hygiene_score.csv', newline='', encoding='utf-8') as old_file:
                old_reader = list(csv.DictReader(old_file))
                for i in range(min(len(old_reader), len(restaurants))):
                    row_old = old_reader[i]
                    old_name = row_old['BusinessName'].strip().lower()
                    if old_name:
                        old_name_to_restaurant[old_name] = restaurants[i]
        except Exception as e:
            self.stderr.write(f"Error loading name mapping: {e}")
            return

        if options['replace']:
            deleted, _ = RestaurantMenuItem.objects.all().delete()
            self.stdout.write(f'Deleted {deleted} existing menu items.')

        created = 0
        skipped = 0

        with csv_path.open('r', newline='', encoding='utf-8') as handle:
            reader = csv.DictReader(handle)
            required = {'BusinessName', 'Cuisine', 'DishName', 'DishRating', 'DishPrice'}
            if not required.issubset(set(reader.fieldnames or [])):
                self.stderr.write('CSV headers do not match expected format.')
                self.stderr.write(f'Expected headers: {sorted(required)}')
                return

            with transaction.atomic():
                for row in reader:
                    business_name = (row.get('BusinessName') or '').strip()
                    cuisine = (row.get('Cuisine') or '').strip()
                    dish_name = (row.get('DishName') or '').strip()
                    rating_raw = (row.get('DishRating') or '').strip()
                    price_raw = (row.get('DishPrice') or '').strip()

                    if not business_name or not dish_name:
                        skipped += 1
                        continue

                    old_name_clean = business_name.strip().lower()
                    restaurant = old_name_to_restaurant.get(old_name_clean)
                    if not restaurant:
                        skipped += 1
                        continue

                    try:
                        rating_val = float(rating_raw) if rating_raw else 0.0
                    except ValueError:
                        rating_val = 0.0

                    try:
                        price_val = Decimal(price_raw) if price_raw else Decimal('0')
                    except (InvalidOperation, ValueError):
                        price_val = Decimal('0')

                    RestaurantMenuItem.objects.create(
                        restaurant=restaurant,
                        name=dish_name,
                        category=cuisine or 'Other',
                        description='',
                        price=price_val,
                        rating=rating_val,
                        order_count=0,
                        is_available=True,
                    )
                    created += 1

        self.stdout.write(f'Created {created} menu items. Skipped {skipped}.')
