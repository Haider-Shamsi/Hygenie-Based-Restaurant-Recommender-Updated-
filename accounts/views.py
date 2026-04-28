import random
from datetime import timedelta

import requests
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from django.contrib.auth.models import User
from django.db.models import Avg
from django.utils import timezone
from rest_framework import generics
from rest_framework import permissions
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view
from rest_framework.decorators import permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .google_serializers import GoogleSignInSerializer
from .google_serializers import UserSerializer
from .models import FavoriteRestaurant
from .models import HygieneAlert
from .models import HygieneIssueReport
from .models import NotificationSetting
from .models import Restaurant
from .models import RestaurantMenuItem
from .models import RestaurantReview
from .models import UserInteraction
from .models import UserPreference
from .models import UserProfile
from .serializers import AccountSettingsReadSerializer
from .serializers import AccountSettingsSerializer
from .serializers import FavoriteRestaurantCreateSerializer
from .serializers import FavoriteRestaurantSerializer
from .serializers import HygieneAlertSerializer
from .serializers import HygieneIssueReportCreateSerializer
from .serializers import HygieneIssueReportSerializer
from .serializers import NotificationSettingSerializer
from .serializers import ProfileBundleSerializer
from .serializers import ProfileReportSerializer
from .serializers import ProfileReviewSerializer
from .serializers import RestaurantSerializer
from .serializers import RestaurantDetailSerializer
from .serializers import RestaurantMenuItemSerializer
from .serializers import RestaurantReviewCreateSerializer
from .serializers import RestaurantReviewSerializer
from .serializers import UserInteractionSerializer
from .serializers import UserPreferenceSerializer


OTP_STORE = {}


def _score(restaurant):
    return 0.7 * restaurant.hygiene_score + 0.3 * restaurant.user_rating


def _ensure_user_state(user):
    profile, _ = UserProfile.objects.get_or_create(
        user=user,
        defaults={'full_name': user.get_full_name() or user.username},
    )
    preferences, _ = UserPreference.objects.get_or_create(user=user)
    notification_settings, _ = NotificationSetting.objects.get_or_create(user=user)
    return profile, preferences, notification_settings


class RecommendedRestaurantsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        interactions = UserInteraction.objects.filter(
            user=user,
            interaction_type__in=['view', 'like', 'favorite', 'rate'],
        )

        interacted_ids = list(interactions.values_list('restaurant', flat=True))
        if not interacted_ids:
            qs = Restaurant.objects.all()
            ranked = [(r, _score(r)) for r in qs]
            ranked.sort(key=lambda x: x[1], reverse=True)
            top = [r for r, _score_value in ranked[:10]]
            serializer = RestaurantSerializer(top, many=True)
            return Response(serializer.data)

        liked_types = Restaurant.objects.filter(id__in=interacted_ids).values_list('business_type', flat=True).distinct()

        recommended = Restaurant.objects.filter(
            business_type__in=liked_types
        ).exclude(
            id__in=interacted_ids
        )

        if not recommended.exists():
            qs = Restaurant.objects.exclude(id__in=interacted_ids)
            ranked = [(r, _score(r)) for r in qs]
            ranked.sort(key=lambda x: x[1], reverse=True)
            recommended = [r for r, _score_value in ranked[:10]]
            serializer = RestaurantSerializer(recommended, many=True)
            return Response(serializer.data)

        serializer = RestaurantSerializer(recommended[:10], many=True)
        return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AllowAny])
def restaurants_by_city(request):
    city = request.query_params.get('city')
    if not city:
        return Response({'error': 'city parameter required'}, status=status.HTTP_400_BAD_REQUEST)

    qs = Restaurant.objects.filter(province__iexact=city)
    restaurants = [(r, _score(r)) for r in qs]
    restaurants.sort(key=lambda x: x[1], reverse=True)
    sorted_restaurants = [r for r, score_value in restaurants]
    serializer = RestaurantSerializer(sorted_restaurants, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    username = request.data.get('username')
    otp = request.data.get('otp')
    if not username or not otp:
        return Response({'error': 'Username and OTP required.'}, status=status.HTTP_400_BAD_REQUEST)

    real_otp = OTP_STORE.get(username)
    if real_otp and otp == real_otp:
        del OTP_STORE[username]
        return Response({'message': 'OTP verified.'}, status=status.HTTP_200_OK)

    return Response({'error': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)


class SignUpView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        if not username or not password:
            return Response({'error': 'Username and password required.'}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username=username).exists():
            return Response({'error': 'Username already exists.'}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(username=username, password=password)
        _ensure_user_state(user)

        otp = str(random.randint(100000, 999999))
        OTP_STORE[username] = otp
        print(f"OTP for {username}: {otp}")
        return Response({'message': 'User created successfully.', 'otp': otp}, status=status.HTTP_201_CREATED)


class LogoutView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        return Response({'message': 'Logout successful.'}, status=status.HTTP_200_OK)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if user is None:
            return Response({'error': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)

        _ensure_user_state(user)
        token, _ = Token.objects.get_or_create(user=user)
        user_data = UserSerializer(user).data
        return Response({'message': 'Login successful.', 'token': token.key, 'user': user_data}, status=status.HTTP_200_OK)


class GoogleSignInView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = GoogleSignInSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        google_id_token = serializer.validated_data['token']
        google_url = f'https://oauth2.googleapis.com/tokeninfo?id_token={google_id_token}'
        resp = requests.get(google_url, timeout=10)
        if resp.status_code != 200:
            return Response({'error': 'Invalid Google token'}, status=status.HTTP_400_BAD_REQUEST)

        data = resp.json()
        email = data.get('email')
        if not email:
            return Response({'error': 'Google token missing email'}, status=status.HTTP_400_BAD_REQUEST)

        user_model = get_user_model()
        user, created = user_model.objects.get_or_create(username=email, defaults={'email': email})
        _ensure_user_state(user)

        token_obj, _ = Token.objects.get_or_create(user=user)
        user_serializer = UserSerializer(user)
        return Response({'user': user_serializer.data, 'created': created, 'token': token_obj.key}, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def top_restaurants(request):
    n = int(request.query_params.get('n', 10))
    qs = Restaurant.objects.all()
    restaurants = [(r, _score(r)) for r in qs]
    restaurants.sort(key=lambda x: x[1], reverse=True)
    top = [r for r, score_value in restaurants[:n]]
    serializer = RestaurantSerializer(top, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def restaurants_by_hygiene(request):
    qs = Restaurant.objects.all().order_by('-hygiene_score')
    serializer = RestaurantSerializer(qs, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


class UserInteractionCreateView(generics.CreateAPIView):
    queryset = UserInteraction.objects.all()
    serializer_class = UserInteractionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class UserInteractionListView(generics.ListAPIView):
    serializer_class = UserInteractionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserInteraction.objects.filter(user=self.request.user).order_by('-timestamp')


class HygieneAlertListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _, preferences, _ = _ensure_user_state(request.user)

        low_score_restaurants = Restaurant.objects.filter(
            hygiene_score__lt=preferences.min_hygiene_score
        ).order_by('hygiene_score')[:5]

        existing_restaurant_ids = set(
            HygieneAlert.objects.filter(
                user=request.user,
                alert_type=HygieneAlert.TYPE_LOW_SCORE,
            ).values_list('restaurant_id', flat=True)
        )

        for idx, restaurant in enumerate(low_score_restaurants):
            if restaurant.id in existing_restaurant_ids:
                continue
            HygieneAlert.objects.create(
                user=request.user,
                restaurant=restaurant,
                alert_type=HygieneAlert.TYPE_LOW_SCORE,
                message='Hygiene score dropped below your preferred threshold.',
                distance_km=round(1.2 + (idx * 0.9), 1),
                score_snapshot=int(round(restaurant.hygiene_score)),
            )

        qs = HygieneAlert.objects.filter(
            user=request.user,
            restaurant__hygiene_score__lt=preferences.min_hygiene_score,
        ).select_related('restaurant')

        max_distance = request.query_params.get('max_distance')
        if max_distance is not None:
            try:
                max_distance_val = float(max_distance)
                if max_distance_val < 0:
                    raise ValueError('max_distance must be non-negative')
                qs = qs.filter(distance_km__lte=max_distance_val)
            except ValueError:
                return Response({'error': 'max_distance must be a valid number.'}, status=status.HTTP_400_BAD_REQUEST)

        unread_only = request.query_params.get('unread_only', '').lower() in {'1', 'true', 'yes'}
        if unread_only:
            qs = qs.filter(is_read=False)

        sort = request.query_params.get('sort', 'recent')
        if sort == 'distance':
            qs = qs.order_by('distance_km', '-created_at')
        else:
            qs = qs.order_by('-created_at')

        serializer = HygieneAlertSerializer(qs, many=True)
        total_qs = HygieneAlert.objects.filter(
            user=request.user,
            restaurant__hygiene_score__lt=preferences.min_hygiene_score,
        )
        return Response(
            {
                'count': qs.count(),
                'unread_count': total_qs.filter(is_read=False).count(),
                'results': serializer.data,
            },
            status=status.HTTP_200_OK,
        )


class HygieneAlertMarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, alert_id):
        try:
            alert = HygieneAlert.objects.get(pk=alert_id, user=request.user)
        except HygieneAlert.DoesNotExist:
            return Response({'error': 'Alert not found.'}, status=status.HTTP_404_NOT_FOUND)

        alert.is_read = True
        alert.save(update_fields=['is_read'])
        return Response({'message': 'Alert marked as read.'}, status=status.HTTP_200_OK)


class AlertPreferenceView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _, preferences, notifications = _ensure_user_state(request.user)
        return Response(
            {
                'preferences': UserPreferenceSerializer(preferences).data,
                'notification_settings': NotificationSettingSerializer(notifications).data,
            },
            status=status.HTTP_200_OK,
        )

    def patch(self, request):
        _, preferences, notifications = _ensure_user_state(request.user)

        pref_keys = {'min_hygiene_score', 'exclude_flagged', 'distance_radius_km', 'cuisine_preferences'}
        notif_keys = {
            'hygiene_alerts_enabled',
            'inspection_warnings_enabled',
            'push_enabled',
            'email_enabled',
            'quiet_hours_enabled',
            'quiet_hours_start',
            'quiet_hours_end',
        }

        pref_payload = {k: v for k, v in request.data.items() if k in pref_keys}
        notif_payload = {k: v for k, v in request.data.items() if k in notif_keys}

        if pref_payload:
            pref_serializer = UserPreferenceSerializer(preferences, data=pref_payload, partial=True)
            if not pref_serializer.is_valid():
                return Response(pref_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            pref_serializer.save()

        if notif_payload:
            notif_serializer = NotificationSettingSerializer(notifications, data=notif_payload, partial=True)
            if not notif_serializer.is_valid():
                return Response(notif_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
            notif_serializer.save()

        return self.get(request)


class FavoriteRestaurantListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        favorites = FavoriteRestaurant.objects.filter(user=request.user).select_related('restaurant')
        serializer = FavoriteRestaurantSerializer(favorites, many=True)
        return Response({'count': favorites.count(), 'results': serializer.data}, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = FavoriteRestaurantCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        restaurant = serializer.validated_data['restaurant_obj']
        favorite, created = FavoriteRestaurant.objects.get_or_create(
            user=request.user,
            restaurant=restaurant,
        )
        if created:
            UserInteraction.objects.create(
                user=request.user,
                restaurant=restaurant,
                interaction_type='favorite',
            )

        output = FavoriteRestaurantSerializer(favorite)
        return Response(output.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class FavoriteRestaurantDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, restaurant_id):
        deleted, _ = FavoriteRestaurant.objects.filter(
            user=request.user,
            restaurant_id=restaurant_id,
        ).delete()
        if deleted == 0:
            return Response({'error': 'Favorite not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, preferences, notification_settings = _ensure_user_state(request.user)
        payload = {
            'profile': profile,
            'preferences': preferences,
            'notification_settings': notification_settings,
        }
        serializer = ProfileBundleSerializer(payload)
        return Response(serializer.data, status=status.HTTP_200_OK)


class ProfilePreferencesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _, preferences, _ = _ensure_user_state(request.user)
        serializer = UserPreferenceSerializer(preferences)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        _, preferences, _ = _ensure_user_state(request.user)
        serializer = UserPreferenceSerializer(preferences, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


class ProfileNotificationSettingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _, _, notifications = _ensure_user_state(request.user)
        serializer = NotificationSettingSerializer(notifications)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        _, _, notifications = _ensure_user_state(request.user)
        serializer = NotificationSettingSerializer(notifications, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


class ProfileAccountSettingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _ensure_user_state(request.user)
        serializer = AccountSettingsReadSerializer(request.user)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def patch(self, request):
        _ensure_user_state(request.user)
        serializer = AccountSettingsSerializer(
            instance=request.user,
            data=request.data,
            partial=True,
            context={'request': request},
        )
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        serializer.save()
        output = AccountSettingsReadSerializer(request.user)
        return Response(output.data, status=status.HTTP_200_OK)


def _build_hygiene_breakdown(restaurant, reports_count):
    base = float(restaurant.hygiene_score)
    penalty = min(10.0, reports_count * 1.2)

    def clamp(value):
        return max(0.0, min(100.0, value))

    return [
        {'label': 'Food Handling', 'score': round(clamp(base - penalty + 2.0), 1)},
        {'label': 'Kitchen Cleanliness', 'score': round(clamp(base - penalty + 1.0), 1)},
        {'label': 'Staff Training', 'score': round(clamp(base - penalty - 2.0), 1)},
        {'label': 'Storage Standards', 'score': round(clamp(base - penalty + 0.5), 1)},
    ]


def _build_hygiene_history(restaurant):
    inspection_date = restaurant.inspection_date
    base_score = float(restaurant.hygiene_score)
    points = []
    for idx in range(6):
        month_date = inspection_date - timedelta(days=(5 - idx) * 30)
        drift = (idx - 2) * 0.8
        score = max(0.0, min(100.0, base_score + drift))
        points.append({
            'month': month_date.strftime('%b'),
            'score': round(score, 1),
        })
    return points


class RestaurantDetailDataView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, restaurant_id):
        try:
            restaurant = Restaurant.objects.get(pk=restaurant_id)
        except Restaurant.DoesNotExist:
            return Response({'error': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        reviews_qs = RestaurantReview.objects.filter(restaurant=restaurant).select_related('user')[:20]
        reports_count = HygieneIssueReport.objects.filter(restaurant=restaurant).count()
        menu_qs = RestaurantMenuItem.objects.filter(restaurant=restaurant, is_available=True)
        avg_rating = reviews_qs.aggregate(avg=Avg('rating'))['avg']

        payload = {
            'restaurant': restaurant,
            'reviews': reviews_qs,
            'average_rating': round(float(avg_rating or 0.0), 2),
            'hygiene_breakdown': _build_hygiene_breakdown(restaurant, reports_count),
            'hygiene_history': _build_hygiene_history(restaurant),
            'menu_items': menu_qs,
            'recent_reports_count': reports_count,
        }
        serializer = RestaurantDetailSerializer(payload)
        return Response(serializer.data, status=status.HTTP_200_OK)


class RestaurantReviewListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, restaurant_id):
        reviews = RestaurantReview.objects.filter(restaurant_id=restaurant_id).select_related('user')
        serializer = RestaurantReviewSerializer(reviews, many=True)
        avg = reviews.aggregate(avg=Avg('rating'))['avg']
        return Response(
            {
                'count': reviews.count(),
                'average_rating': round(float(avg or 0.0), 2),
                'results': serializer.data,
            },
            status=status.HTTP_200_OK,
        )

    def post(self, request, restaurant_id):
        try:
            restaurant = Restaurant.objects.get(pk=restaurant_id)
        except Restaurant.DoesNotExist:
            return Response({'error': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = RestaurantReviewCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        review = RestaurantReview.objects.create(
            user=request.user,
            restaurant=restaurant,
            rating=serializer.validated_data['rating'],
            comment=serializer.validated_data['comment'].strip(),
        )
        UserInteraction.objects.create(
            user=request.user,
            restaurant=restaurant,
            interaction_type='rate',
            rating=float(review.rating),
        )

        profile, _, _ = _ensure_user_state(request.user)
        profile.reviews_written = RestaurantReview.objects.filter(user=request.user).count()
        profile.save(update_fields=['reviews_written', 'updated_at'])

        out = RestaurantReviewSerializer(review)
        return Response(out.data, status=status.HTTP_201_CREATED)


class HygieneIssueReportListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, restaurant_id):
        reports = HygieneIssueReport.objects.filter(restaurant_id=restaurant_id, user=request.user)
        serializer = HygieneIssueReportSerializer(reports, many=True)
        return Response({'count': reports.count(), 'results': serializer.data}, status=status.HTTP_200_OK)

    def post(self, request, restaurant_id):
        try:
            restaurant = Restaurant.objects.get(pk=restaurant_id)
        except Restaurant.DoesNotExist:
            return Response({'error': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = HygieneIssueReportCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        report = HygieneIssueReport.objects.create(
            user=request.user,
            restaurant=restaurant,
            category=serializer.validated_data['category'],
            description=serializer.validated_data['description'].strip(),
        )

        profile, _, _ = _ensure_user_state(request.user)
        profile.reports_submitted = HygieneIssueReport.objects.filter(user=request.user).count()
        profile.save(update_fields=['reports_submitted', 'updated_at'])

        _, _, notifications = _ensure_user_state(request.user)
        if notifications.hygiene_alerts_enabled:
            HygieneAlert.objects.create(
                user=request.user,
                restaurant=restaurant,
                alert_type=HygieneAlert.TYPE_INSPECTION_WARNING,
                message=f'Issue submitted: {report.get_category_display()}.',
                distance_km=1.0,
                score_snapshot=int(round(restaurant.hygiene_score)),
            )

        out = HygieneIssueReportSerializer(report)
        return Response(out.data, status=status.HTTP_201_CREATED)


class RestaurantMenuListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, restaurant_id):
        menu_items = RestaurantMenuItem.objects.filter(restaurant_id=restaurant_id, is_available=True)
        serializer = RestaurantMenuItemSerializer(menu_items, many=True)
        return Response({'count': menu_items.count(), 'results': serializer.data}, status=status.HTTP_200_OK)


class ProfileReviewListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        reviews = RestaurantReview.objects.filter(user=request.user).select_related('restaurant')
        serializer = ProfileReviewSerializer(reviews, many=True)
        return Response({'count': reviews.count(), 'results': serializer.data}, status=status.HTTP_200_OK)


class ProfileReviewDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, review_id):
        deleted, _ = RestaurantReview.objects.filter(id=review_id, user=request.user).delete()
        if deleted == 0:
            return Response({'error': 'Review not found.'}, status=status.HTTP_404_NOT_FOUND)

        profile, _, _ = _ensure_user_state(request.user)
        profile.reviews_written = RestaurantReview.objects.filter(user=request.user).count()
        profile.save(update_fields=['reviews_written', 'updated_at'])
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProfileReportListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        reports = HygieneIssueReport.objects.filter(user=request.user).select_related('restaurant')
        serializer = ProfileReportSerializer(reports, many=True)
        summary = {
            'total': reports.count(),
            'submitted': reports.filter(status=HygieneIssueReport.STATUS_SUBMITTED).count(),
            'reviewed': reports.filter(status=HygieneIssueReport.STATUS_REVIEWED).count(),
            'resolved': reports.filter(status=HygieneIssueReport.STATUS_RESOLVED).count(),
        }
        return Response({'count': reports.count(), 'summary': summary, 'results': serializer.data}, status=status.HTTP_200_OK)
