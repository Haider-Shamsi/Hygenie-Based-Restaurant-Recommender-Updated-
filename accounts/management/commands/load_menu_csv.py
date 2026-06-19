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

        # Build mapping from original business names to new Lahore business names
        old_to_new = {}
        try:
            with open('Updated_restaurant_with_hygiene_score.csv', newline='', encoding='utf-8') as old_file, \
                 open('lahore_restaurants.csv', newline='', encoding='utf-8') as new_file:
                old_reader = list(csv.DictReader(old_file))
                new_reader = list(csv.DictReader(new_file))
                for i in range(len(old_reader)):
                    row_old = old_reader[i]
                    row_new = new_reader[i % len(new_reader)]
                    
                    old_name = row_old['BusinessName'].strip().lower()
                    new_name = (row_new.get('Restaurant Name') or row_new.get('DBA') or '').strip()
                    if old_name and new_name:
                        old_to_new[old_name] = new_name
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
                    mapped_name = old_to_new.get(old_name_clean)
                    if not mapped_name:
                        skipped += 1
                        continue

                    restaurant = Restaurant.objects.filter(business_name__iexact=mapped_name).first()
                    if restaurant is None:
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
