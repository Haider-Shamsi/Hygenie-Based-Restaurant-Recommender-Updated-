
# Item-based collaborative filtering recommendation endpoint
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

class RecommendedRestaurantsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        # Get restaurants the user has interacted with.
        # Include 'view' so new users can get recommendations quickly.
        interactions = UserInteraction.objects.filter(
            user=user,
            interaction_type__in=['view', 'like', 'favorite', 'rate'],
        )

        interacted_ids = list(interactions.values_list('restaurant', flat=True))
        if not interacted_ids:
            # Cold-start fallback: return top restaurants by ML score.
            qs = Restaurant.objects.all()
            ranked = [(r, 0.7 * r.hygiene_score + 0.3 * r.user_rating) for r in qs]
            ranked.sort(key=lambda x: x[1], reverse=True)
            top = [r for r, _score in ranked[:10]]
            serializer = RestaurantSerializer(top, many=True)
            return Response(serializer.data)

        # Get unique business types from user's history
        liked_types = Restaurant.objects.filter(
            id__in=interacted_ids
        ).values_list('business_type', flat=True).distinct()

        # Recommend restaurants with similar types, excluding already interacted.
        recommended = Restaurant.objects.filter(
            business_type__in=liked_types
        ).exclude(
            id__in=interacted_ids
        )

        if not recommended.exists():
            # Fallback if nothing matches the user's types.
            qs = Restaurant.objects.exclude(id__in=interacted_ids)
            ranked = [(r, 0.7 * r.hygiene_score + 0.3 * r.user_rating) for r in qs]
            ranked.sort(key=lambda x: x[1], reverse=True)
            recommended = [r for r, _score in ranked[:10]]
            serializer = RestaurantSerializer(recommended, many=True)
            return Response(serializer.data)

        serializer = RestaurantSerializer(recommended[:10], many=True)
        return Response(serializer.data)

# -------------------- IMPORTS (moved to top) --------------------
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from rest_framework.permissions import AllowAny
from rest_framework.decorators import api_view, permission_classes
import random
from .models import Restaurant
from .serializers import RestaurantSerializer
from .google_serializers import GoogleSignInSerializer, UserSerializer
import requests
from django.contrib.auth import get_user_model
from rest_framework import generics, permissions
from rest_framework.authtoken.models import Token
from .models import UserInteraction
from .serializers import UserInteractionSerializer
# -------------------- END IMPORTS --------------------

# Location-based recommendations by city
@api_view(['GET'])
@permission_classes([AllowAny])
def restaurants_by_city(request):
    """
    Returns restaurants filtered by city (province field), sorted by ML score.
    Query param: city (case-insensitive, required)
    """
    city = request.query_params.get('city')
    if not city:
        return Response({'error': 'city parameter required'}, status=status.HTTP_400_BAD_REQUEST)
    qs = Restaurant.objects.filter(province__iexact=city)
    restaurants = [
        (r, 0.7 * r.hygiene_score + 0.3 * r.user_rating)
        for r in qs
    ]
    restaurants.sort(key=lambda x: x[1], reverse=True)
    sorted_restaurants = [r for r, score in restaurants]
    serializer = RestaurantSerializer(sorted_restaurants, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)

# In-memory OTP store for development (username: otp)
OTP_STORE = {}

# OTP verification API
@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    username = request.data.get('username')
    otp = request.data.get('otp')
    if not username or not otp:
        return Response({'error': 'Username and OTP required.'}, status=status.HTTP_400_BAD_REQUEST)
    real_otp = OTP_STORE.get(username)
    if real_otp and otp == real_otp:
        # Optionally, delete OTP after verification
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
        # Generate OTP and store in-memory for development
        otp = str(random.randint(100000, 999999))
        OTP_STORE[username] = otp
        print(f"OTP for {username}: {otp}")  # Print OTP to terminal for development
        return Response({'message': 'User created successfully.', 'otp': otp}, status=status.HTTP_201_CREATED)

class LogoutView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # For stateless APIs, just return success (frontend will clear local session)
        return Response({'message': 'Logout successful.'}, status=status.HTTP_200_OK)

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        user = authenticate(username=username, password=password)
        if user is None:
            return Response({'error': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)

        token, _ = Token.objects.get_or_create(user=user)
        # Keep response consistent with GoogleSignInView
        user_data = UserSerializer(user).data
        return Response({'message': 'Login successful.', 'token': token.key, 'user': user_data}, status=status.HTTP_200_OK)


# Google Sign-In API
class GoogleSignInView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = GoogleSignInSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        google_id_token = serializer.validated_data['token']

        # Verify token with Google
        google_url = f'https://oauth2.googleapis.com/tokeninfo?id_token={google_id_token}'
        resp = requests.get(google_url)
        if resp.status_code != 200:
            return Response({'error': 'Invalid Google token'}, status=status.HTTP_400_BAD_REQUEST)
        data = resp.json()
        email = data.get('email')
        if not email:
            return Response({'error': 'Google token missing email'}, status=status.HTTP_400_BAD_REQUEST)

        User = get_user_model()
        user, created = User.objects.get_or_create(username=email, defaults={'email': email})
        # Optionally, update user fields here

        token_obj, _ = Token.objects.get_or_create(user=user)
        user_serializer = UserSerializer(user)
        return Response({'user': user_serializer.data, 'created': created, 'token': token_obj.key}, status=status.HTTP_200_OK)


# Recommendation API: Top N restaurants by ML score
@api_view(['GET'])
@permission_classes([AllowAny])
def top_restaurants(request):
    """
    Returns top N restaurants sorted by ML score: 0.7 * hygiene_score + 0.3 * user_rating
    Query param: n (default 10)
    """
    n = int(request.query_params.get('n', 10))
    qs = Restaurant.objects.all()
    # Compute ML score for each restaurant
    restaurants = [
        (r, 0.7 * r.hygiene_score + 0.3 * r.user_rating)
        for r in qs
    ]
    # Sort by score descending
    restaurants.sort(key=lambda x: x[1], reverse=True)
    top = [r for r, score in restaurants[:n]]
    serializer = RestaurantSerializer(top, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# Hygiene score sorted endpoint (for initial display)
@api_view(['GET'])
@permission_classes([AllowAny])
def restaurants_by_hygiene(request):
    """
    Returns all restaurants sorted by hygiene_score descending
    """
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