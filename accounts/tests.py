import hashlib
from datetime import timedelta
from unittest.mock import patch
from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from django.test import override_settings
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Restaurant, RestaurantReview, UserProfile
from .views import _update_hygiene_from_reviews

class GoogleReviewsSyncTests(APITestCase):
    def setUp(self):
        # Create Admin User & Profile
        self.admin_user = User.objects.create_superuser(username='admin_user', password='password123', email='admin@admin.com')
        self.admin_profile = UserProfile.objects.create(user=self.admin_user, role=UserProfile.ROLE_ADMIN)
        
        # Create Owner User
        self.owner_user = User.objects.create_user(username='owner_user', password='password123')
        self.owner_profile = UserProfile.objects.create(user=self.owner_user, role=UserProfile.ROLE_OWNER)

        # Create Restaurant
        self.restaurant = Restaurant.objects.create(
            owner=self.owner_user,
            business_name="Test Diner",
            business_type="Restaurant",
            rating_value="Pass",
            inspection_date=timezone.now().date(),
            address="123 Main St",
            post_code="12345",
            province="Punjab",
            user_rating=4.0,
            hygiene_score=85.0
        )
        
        # Authenticate Admin
        self.client.force_authenticate(user=self.admin_user)

    def test_hygiene_recalculation_with_pass_mapping(self):
        # Mapped 'Pass' is 85.0. No reviews yet.
        # User rating is 4.0.
        # Expected hygiene score: 0.7 * 85.0 + 0.3 * (4.0 * 20.0) = 59.5 + 24.0 = 83.5
        _update_hygiene_from_reviews(self.restaurant)
        self.restaurant.refresh_from_db()
        self.assertAlmostEqual(self.restaurant.hygiene_score, 83.5)

    def test_hygiene_recalculation_with_fhrs_numeric_rating(self):
        # Numeric '5' maps to 5.0 * 20 = 100.0. No reviews yet.
        # Expected hygiene score: 0.7 * 100.0 + 0.3 * (4.0 * 20.0) = 70.0 + 24.0 = 94.0
        self.restaurant.rating_value = "5"
        self.restaurant.save()
        _update_hygiene_from_reviews(self.restaurant)
        self.restaurant.refresh_from_db()
        self.assertAlmostEqual(self.restaurant.hygiene_score, 94.0)

    def test_weighted_score_calculation(self):
        # Create a local review: rating 4.0
        # Create a Google review: rating 2.0
        # local reviews are weighted 75%, Google reviews are weighted 25%
        # average review rating for hygiene = 0.75 * 4.0 + 0.25 * 2.0 = 3.0 + 0.5 = 3.5
        # Expected hygiene score: 0.7 * 85.0 (Pass) + 0.3 * (3.5 * 20.0) = 59.5 + 21.0 = 80.5
        
        RestaurantReview.objects.create(
            restaurant=self.restaurant,
            user=self.owner_user,
            rating=4,
            comment="Local review comment",
            moderation_status=RestaurantReview.MODERATION_APPROVED,
            is_google_review=False
        )
        
        RestaurantReview.objects.create(
            restaurant=self.restaurant,
            rating=2,
            comment="Google review comment",
            moderation_status=RestaurantReview.MODERATION_APPROVED,
            is_google_review=True,
            google_reviewer_name="Google Reviewer",
            google_review_hash="hash123"
        )
        
        _update_hygiene_from_reviews(self.restaurant)
        self.restaurant.refresh_from_db()
        self.assertAlmostEqual(self.restaurant.hygiene_score, 80.5)

    @override_settings(GOOGLE_PLACES_API_KEY='')
    def test_sync_google_reviews_preview_mode(self):
        url = reverse('admin-restaurant-actions', kwargs={'restaurant_id': self.restaurant.id})
        
        # Trigger Sync preview in demo mode
        response = self.client.post(url, {'action': 'sync_google_reviews'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertEqual(data['status'], 'preview')
        self.assertEqual(data['mode'], 'demo')
        # 3 mock reviews should be previewed
        self.assertEqual(data['new_reviews_count'], 3)
        self.assertEqual(len(data['reviews_preview']), 3)
        
        # In preview mode, database should NOT contain Google reviews yet
        google_reviews = RestaurantReview.objects.filter(restaurant=self.restaurant, is_google_review=True)
        self.assertEqual(google_reviews.count(), 0)

    @override_settings(GOOGLE_PLACES_API_KEY='')
    def test_sync_google_reviews_confirm_mode(self):
        url = reverse('admin-restaurant-actions', kwargs={'restaurant_id': self.restaurant.id})
        
        # Confirm sync in demo mode
        response = self.client.post(url, {'action': 'sync_google_reviews', 'confirm': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        data = response.json()
        self.assertEqual(data['status'], 'success')
        self.assertEqual(data['new_reviews_count'], 3)
        
        # Google reviews should now be committed to DB
        google_reviews = RestaurantReview.objects.filter(restaurant=self.restaurant, is_google_review=True)
        self.assertEqual(google_reviews.count(), 3)
        
        # Test cooldown restriction on subsequent attempts
        response2 = self.client.post(url, {'action': 'sync_google_reviews'}, format='json')
        self.assertEqual(response2.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("Sync is limited to once every 24 hours", response2.json()['detail'])

    @patch('requests.get')
    def test_sync_google_reviews_live_mode_mocked(self, mock_get):
        with override_settings(GOOGLE_PLACES_API_KEY='fake_live_api_key'):
            url = reverse('admin-restaurant-actions', kwargs={'restaurant_id': self.restaurant.id})
            
            # Setup mocked responses for findplacefromtext and details APIs
            class MockResponse:
                def __init__(self, json_data, status_code=200):
                    self.json_data = json_data
                    self.status_code = status_code
                def json(self):
                    return self.json_data
                def raise_for_status(self):
                    pass
            
            mock_get.side_effect = [
                # Response for findplacefromtext
                MockResponse({
                    'candidates': [{'place_id': 'chicago_pizza_place_123'}]
                }),
                # Response for place details
                MockResponse({
                    'result': {
                        'reviews': [
                            {
                                'author_name': 'Live User One',
                                'rating': 5,
                                'text': 'Amazing places review content',
                                'time': 1718873456
                            }
                        ]
                    }
                })
            ]
            
            # Request preview first
            response = self.client.post(url, {'action': 'sync_google_reviews'}, format='json')
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            self.assertEqual(response.json()['status'], 'preview')
            self.assertEqual(response.json()['new_reviews_count'], 1)
            
            # Setup mock for confirmation call
            mock_get.side_effect = [
                MockResponse({
                    'candidates': [{'place_id': 'chicago_pizza_place_123'}]
                }),
                MockResponse({
                    'result': {
                        'reviews': [
                            {
                                'author_name': 'Live User One',
                                'rating': 5,
                                'text': 'Amazing places review content',
                                'time': 1718873456
                            }
                        ]
                    }
                })
            ]
            
            # Request confirmation
            response_confirm = self.client.post(url, {'action': 'sync_google_reviews', 'confirm': True}, format='json')
            self.assertEqual(response_confirm.status_code, status.HTTP_200_OK)
            self.assertEqual(response_confirm.json()['status'], 'success')
            self.assertEqual(response_confirm.json()['new_reviews_count'], 1)
            
            # Verify resolved place ID is saved
            self.restaurant.refresh_from_db()
            self.assertEqual(self.restaurant.google_place_id, 'chicago_pizza_place_123')
            
            # Verify review saved
            google_reviews = RestaurantReview.objects.filter(restaurant=self.restaurant, is_google_review=True)
            self.assertEqual(google_reviews.count(), 1)
            self.assertEqual(google_reviews.first().google_reviewer_name, 'Live User One')
