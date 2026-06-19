import csv
from datetime import datetime
from django.core.management.base import BaseCommand
from accounts.models import Restaurant

class Command(BaseCommand):
    help = 'Import restaurants by replacing names/locations of current restaurants with Lahore dataset while keeping numerical ratings the same.'

    def handle(self, *args, **options):
        # Clear existing restaurants to prevent duplicates
        Restaurant.objects.all().delete()
        
        with open('Updated_restaurant_with_hygiene_score.csv', newline='', encoding='utf-8') as old_file, \
             open('lahore_restaurants.csv', newline='', encoding='utf-8') as new_file:
            
            old_reader = list(csv.DictReader(old_file))
            new_reader = list(csv.DictReader(new_file))
            
            count = 0
            # Map up to the length of the original 531 entries
            for i in range(len(old_reader)):
                row_old = old_reader[i]
                row_new = new_reader[i % len(new_reader)]
                
                # Parse date
                try:
                    inspection_date = datetime.strptime(row_old['InspectionDate'], '%d/%m/%Y').date()
                except Exception:
                    inspection_date = None
                    
                # Build address
                building = (row_new.get('BUILDING') or '').strip()
                street = (row_new.get('STREET') or '').strip()
                neighbourhood = (row_new.get('NEIGHBOURHOOD') or '').strip()
                addr_parts = [p for p in [building, street] if p]
                address = ' '.join(addr_parts)
                if neighbourhood:
                    address = f"{address}, {neighbourhood}" if address else neighbourhood
                if not address:
                    address = row_old['Address'] # Fallback
                
                # Restaurant Name
                name = (row_new.get('Restaurant Name') or row_new.get('DBA') or '').strip()
                if not name:
                    name = row_old['BusinessName'] # Fallback
                
                # Parse Coordinates
                try:
                    latitude = float(row_new.get('Latitude') or 0) or None
                except (ValueError, TypeError):
                    latitude = None
                try:
                    longitude = float(row_new.get('Longitude') or 0) or None
                except (ValueError, TypeError):
                    longitude = None
                
                # Fallback to old coordinates if new coordinates are not available
                if latitude is None:
                    try:
                        latitude = float(row_old.get('Latitude') or 0) or None
                    except (ValueError, TypeError):
                        pass
                if longitude is None:
                    try:
                        longitude = float(row_old.get('Longitude') or 0) or None
                    except (ValueError, TypeError):
                        pass

                Restaurant.objects.create(
                    business_name=name,
                    address=address,
                    business_type=row_old['BusinessType'],
                    rating_value=row_old['RatingValue'],
                    inspection_date=inspection_date,
                    post_code=row_old['PostCode'],
                    province=row_old['Province'],
                    user_rating=float(row_old['user_rating']),
                    hygiene_score=float(row_old['Hygiene_Score']),
                    latitude=latitude,
                    longitude=longitude,
                )
                count += 1
                
            self.stdout.write(self.style.SUCCESS(f'Successfully imported {count} restaurants with Lahore names and locations.'))
