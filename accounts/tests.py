import datetime
import os
from django.test import TestCase, override_settings
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from .models import Restaurant, RestaurantReview, UserProfile

@override_settings(GOOGLE_PLACES_API_KEY='')
class GoogleReviewSyncTest(TestCase):
    def setUp(self):
        self.orig_env_key = os.environ.get('GOOGLE_PLACES_API_KEY')
        if 'GOOGLE_PLACES_API_KEY' in os.environ:
            del os.environ['GOOGLE_PLACES_API_KEY']

        # Create an owner user
        self.owner = User.objects.create_user(username='owner_user', password='password123', email='owner@owner.com')
        self.profile = UserProfile.objects.create(user=self.owner, role=UserProfile.ROLE_OWNER)
        
        # Create a restaurant
        self.restaurant = Restaurant.objects.create(
            owner=self.owner,
            business_name="Test Restaurant",
            business_type="Fast Food",
            rating_value="80.0",
            inspection_date=datetime.date.today(),
            address="123 Street",
            post_code="12345",
            province="Punjab",
            user_rating=4.0,
            hygiene_score=80.0
        )
        
        self.client = APIClient()
        self.client.force_authenticate(user=self.owner)

    def tearDown(self):
        if self.orig_env_key is not None:
            os.environ['GOOGLE_PLACES_API_KEY'] = self.orig_env_key

    def test_restaurant_fields(self):
        self.assertIsNone(self.restaurant.google_place_id)
        self.assertIsNone(self.restaurant.last_google_sync)

    def test_sync_throttling_cooldown(self):
        # Set last sync to recently
        self.restaurant.last_google_sync = timezone.now() - datetime.timedelta(minutes=30)
        self.restaurant.save()
        
        response = self.client.post('/api/accounts/owner/reviews/sync-google/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        self.assertTrue(data['success'])
        self.assertTrue(data['credits_saved'])
        self.assertIn("Google reviews synced recently", data['message'])

    def test_sync_google_reviews_success(self):
        # Ensure we have no synced reviews initially
        self.assertEqual(self.restaurant.reviews.count(), 0)
        
        # Trigger sync (without placing API key, so it falls back to demo/mock data)
        response = self.client.post('/api/accounts/owner/reviews/sync-google/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()
        
        self.assertTrue(data['success'])
        self.assertEqual(data['reviews_imported'], 3)
        self.assertTrue(data['demo_mode'])
        
        # Verify reviews were created
        self.assertEqual(self.restaurant.reviews.count(), 3)
        
        # Verify restaurant hygiene score was updated and is not 7.5
        self.restaurant.refresh_from_db()
        self.assertNotEqual(self.restaurant.hygiene_score, 7.5)
        # Expected score: 0.925 * 80.0 + 0.075 * ((5+2+4)/3 * 20) = 74.0 + 5.5 = 79.5
        self.assertAlmostEqual(self.restaurant.hygiene_score, 79.5, places=1)

    def test_sync_google_reviews_pass_mapping(self):
        self.restaurant.rating_value = "Pass"
        self.restaurant.save()
        
        response = self.client.post('/api/accounts/owner/reviews/sync-google/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        self.restaurant.refresh_from_db()
        # Expected score: 0.925 * 85.0 + 0.075 * ((5+2+4)/3 * 20) = 78.625 + 5.5 = 84.125
        self.assertAlmostEqual(self.restaurant.hygiene_score, 84.1, places=1)
