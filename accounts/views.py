import math
import os
import pickle
import random
import re
from datetime import date, timedelta

import requests
from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth import get_user_model
from django.contrib.auth.models import User
from django.db.models import Avg, Count, Q
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
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser


from .google_serializers import GoogleSignInSerializer
from .google_serializers import UserSerializer
from .models import FavoriteRestaurant
from .models import HygieneAlert
from .models import HygieneIssueReport
from .models import HygieneScoreHistory
from .models import NotificationSetting
from .models import Restaurant
from .models import RestaurantMenuItem
from .models import OwnerReportResponse
from .models import OwnerReviewResponse
from .models import OwnerReviewFlag
from .models import RestaurantReview
from .models import InspectionRequest
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

_SENTIMENT_MODEL = None
_SENTIMENT_VECTORIZER = None


def _clean_review_text(text):
    if not isinstance(text, str):
        return ''
    text = text.lower()
    text = re.sub(r'http\S+|www\S+', '', text)
    text = re.sub(r'[^a-zA-Z\s]', '', text)
    words = text.split()
    stop_words = {
        'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from', 'has',
        'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the', 'to', 'was',
        'were', 'will', 'with', 'i', 'you', 'we', 'they', 'this', 'those', 'these',
        'or', 'but', 'if', 'then', 'so', 'not', 'no', 'yes', 'my', 'your', 'our',
    }
    words = [w for w in words if w not in stop_words]
    return ' '.join(words)


def _load_sentiment_artifacts():
    global _SENTIMENT_MODEL
    global _SENTIMENT_VECTORIZER

    if _SENTIMENT_MODEL is not None and _SENTIMENT_VECTORIZER is not None:
        return _SENTIMENT_MODEL, _SENTIMENT_VECTORIZER

    model_path = os.path.join(settings.BASE_DIR, 'sentiment_model (2).pkl')
    vectorizer_path = os.path.join(settings.BASE_DIR, 'tfidf_vectorizer (2).pkl')

    if not os.path.exists(model_path) or not os.path.exists(vectorizer_path):
        return None, None

    try:
        with open(model_path, 'rb') as f:
            _SENTIMENT_MODEL = pickle.load(f)
        with open(vectorizer_path, 'rb') as f:
            _SENTIMENT_VECTORIZER = pickle.load(f)
    except Exception:
        _SENTIMENT_MODEL = None
        _SENTIMENT_VECTORIZER = None

    return _SENTIMENT_MODEL, _SENTIMENT_VECTORIZER


def _predict_sentiment(review_text):
    model, vectorizer = _load_sentiment_artifacts()
    if model is None or vectorizer is None:
        return {
            'label': 'Neutral',
            'score': 0.0,
            'confidence': 0,
        }

    cleaned = _clean_review_text(review_text)
    features = vectorizer.transform([cleaned])
    prediction = model.predict(features)[0]

    confidence = 0
    score = 0.0
    if hasattr(model, 'predict_proba'):
        probs = model.predict_proba(features)[0]
        confidence = int(round(max(probs) * 100))
        if len(probs) >= 2:
            negative_prob = float(probs[0])
            positive_prob = float(probs[1])
            score = positive_prob - negative_prob
    elif hasattr(model, 'decision_function'):
        decision = model.decision_function(features)
        try:
            score = float(decision[0])
        except Exception:
            score = 0.0

    if score > 0.15:
        label = 'Positive'
    elif score < -0.15:
        label = 'Negative'
    else:
        label = 'Neutral'

    return {
        'label': label,
        'score': float(score),
        'confidence': confidence,
    }


def _analyze_report_nlp(description):
    sentiment = _predict_sentiment(description)
    text = (description or '').lower()
    
    # Auto-detected tags
    flags = []
    pest_keywords = ['pest', 'rat', 'rats', 'mouse', 'mice', 'cockroach', 'cockroaches', 'maggot', 'maggots', 'bug', 'bugs', 'insect', 'insects', 'fly', 'flies', 'infestation', 'rodent']
    food_keywords = ['raw', 'undercooked', 'blood', 'hair', 'nail', 'foreign object', 'expired', 'spoil', 'spoiled', 'mould', 'mold', 'glass', 'metal', 'contamination']
    sanitation_keywords = ['dirty', 'filthy', 'grease', 'smell', 'odor', 'trash', 'garbage', 'dust', 'sink', 'toilet', 'washroom', 'restroom', 'cleanliness', 'stink']
    health_keywords = ['poison', 'sick', 'hospital', 'vomit', 'diarrhea', 'ill', 'illness', 'allergic', 'allergy', 'stomach ache']
    
    if any(k in text for k in pest_keywords):
        flags.append('Pest Control')
    if any(k in text for k in food_keywords):
        flags.append('Food Safety')
    if any(k in text for k in sanitation_keywords):
        flags.append('Sanitation')
    if any(k in text for k in health_keywords):
        flags.append('Health Risk')
        
    if not flags:
        flags.append('General')
        
    # Severity classification
    critical_keywords = ['poison', 'hospital', 'vomit', 'diarrhea', 'illness', 'sick', 'infestation', 'rat', 'rats', 'mouse', 'mice', 'cockroach', 'cockroaches', 'maggot', 'maggots', 'raw chicken', 'expired', 'blood']
    major_keywords = ['dirty', 'filthy', 'grease', 'smell', 'odor', 'stink', 'hair', 'nail', 'bug', 'insect', 'fly', 'flies', 'garbage', 'waste']
    
    if any(k in text for k in critical_keywords):
        severity = 'Critical'
    elif any(k in text for k in major_keywords):
        severity = 'Major'
    else:
        severity = 'Minor'
        
    return {
        'severity_assessment': severity,
        'confidence_score': sentiment['confidence'] if sentiment['confidence'] > 0 else 85,
        'auto_flags': flags,
    }


def _analyze_review_nlp(comment):
    sentiment = _predict_sentiment(comment)
    text = (comment or '').lower()
    
    # Auto-detected issues
    issues = []
    if any(k in text for k in ['hair', 'nail', 'stone', 'glass', 'metal', 'thread']):
        issues.append('Foreign Object')
    if any(k in text for k in ['dirty', 'filthy', 'greasy', 'smell', 'stink', 'dusty', 'trash']):
        issues.append('Poor Sanitation')
    if any(k in text for k in ['sick', 'vomit', 'poison', 'diarrhea', 'ill', 'allergic']):
        issues.append('Foodborne Illness Risk')
    if any(k in text for k in ['raw', 'undercooked', 'cold', 'burnt', 'stale', 'bad taste']):
        issues.append('Food Quality Issue')
        
    # Extracted Key Phrases
    words = _clean_review_text(comment).split()
    key_phrases = []
    for w in words:
        if len(w) > 3 and w not in key_phrases:
            key_phrases.append(w.capitalize())
        if len(key_phrases) >= 5:
            break
            
    # Toxicity score (0-100)
    bad_words = ['awful', 'terrible', 'worst', 'horrible', 'disgusting', 'filthy', 'nasty', 'gross', 'scam', 'fraud', 'cheat', 'hate', 'stupid', 'bad', 'crap', 'garbage', 'rubbish', 'poison']
    toxicity_matches = sum(1 for w in words if w in bad_words)
    toxicity_score = min(toxicity_matches * 25, 100)
    
    problematic = [w.capitalize() for w in words if w in bad_words]
    
    return {
        'sentiment_label': sentiment['label'],
        'sentiment_score': sentiment['score'],
        'confidence_score': sentiment['confidence'] if sentiment['confidence'] > 0 else 80,
        'detected_issues': issues if issues else ['None'],
        'key_phrases': key_phrases,
        'toxicity_score': toxicity_score,
        'problematic_words': problematic,
    }


def _review_flag_metadata(review, nlp_data):
    reasons = []
    flag_category = 'nlp-auto'

    if nlp_data['toxicity_score'] >= 50 or nlp_data['problematic_words']:
        flag_category = 'inappropriate'
        reasons.append('Toxicity')

    if nlp_data['sentiment_label'] == 'Negative':
        reasons.append('Negative sentiment')

    if int(review.rating or 0) <= 2:
        reasons.append('Low rating')

    if nlp_data['detected_issues'] and nlp_data['detected_issues'][0] != 'None':
        reasons.append('Detected issues')

    flagged = bool(reasons)
    reason_source = ', '.join(reasons) if reasons else 'NLP'

    return {
        'flagged': flagged,
        'flag_category': flag_category,
        'flag_reason_source': reason_source,
        'flag_reason_type': 'auto',
    }


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


def _apply_role_from_email(user):
    email = (user.email or user.username or '').strip().lower()
    if '@' not in email:
        return

    domain = email.split('@')[-1]
    profile, _, _ = _ensure_user_state(user)

    if domain == 'admin.com':
        profile.role = UserProfile.ROLE_ADMIN
        user.is_staff = True
    elif domain == 'owner.com':
        profile.role = UserProfile.ROLE_OWNER
    elif domain == 'customer.com':
        profile.role = UserProfile.ROLE_CUSTOMER
    else:
        return

    profile.save(update_fields=['role', 'updated_at'])
    user.save(update_fields=['is_staff'])


def _get_restaurant_from_request(request):
    restaurant_id = request.query_params.get('restaurant_id') or request.data.get('restaurant_id')
    if restaurant_id:
        return Restaurant.objects.filter(id=restaurant_id).first()
    return Restaurant.objects.first()


def _get_owner_restaurant(request):
    user = request.user
    if not user or not user.is_authenticated:
        return None

    profile, _, _ = _ensure_user_state(user)
    is_owner = profile.role == UserProfile.ROLE_OWNER
    is_admin = user.is_staff or user.is_superuser

    if not is_owner and not is_admin:
        return None

    if is_admin:
        restaurant_id = request.query_params.get('restaurant_id') or request.data.get('restaurant_id')
        if restaurant_id:
            return Restaurant.objects.filter(id=restaurant_id).first()

    return Restaurant.objects.filter(owner=user).first()


def _is_admin_user(user):
    if not user or not user.is_authenticated:
        return False
    if user.is_staff or user.is_superuser:
        return True
    profile, _, _ = _ensure_user_state(user)
    return profile.role == UserProfile.ROLE_ADMIN


def _admin_report_status(report_status):
    if report_status == HygieneIssueReport.STATUS_SUBMITTED:
        return 'pending'
    if report_status == HygieneIssueReport.STATUS_REVIEWED:
        return 'investigating'
    if report_status == HygieneIssueReport.STATUS_RESOLVED:
        return 'resolved'
    return 'pending'


def _admin_issue_type(category):
    mapping = {
        HygieneIssueReport.CATEGORY_FOOD_HANDLING: 'food-safety',
        HygieneIssueReport.CATEGORY_CLEANLINESS: 'cleanliness',
        HygieneIssueReport.CATEGORY_PEST_CONTROL: 'pest-control',
        HygieneIssueReport.CATEGORY_OTHER: 'other',
    }
    return mapping.get(category, 'other')


def _admin_report_priority(category):
    if category in [HygieneIssueReport.CATEGORY_FOOD_HANDLING, HygieneIssueReport.CATEGORY_PEST_CONTROL]:
        return 'high'
    if category == HygieneIssueReport.CATEGORY_CLEANLINESS:
        return 'medium'
    return 'low'


def _restaurant_status(score):
    if score < 40:
        return 'Suspended'
    if score < 60:
        return 'Under Review'
    return 'Active'


def _cosine_similarity(vec_a, vec_b):
    dot = 0.0
    norm_a = 0.0
    norm_b = 0.0
    for a, b in zip(vec_a, vec_b):
        dot += a * b
        norm_a += a * a
        norm_b += b * b
    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0
    return dot / (math.sqrt(norm_a) * math.sqrt(norm_b))


def _cosine_similarity_dict(vec_a, vec_b):
    if not vec_a or not vec_b:
        return 0.0
    dot = 0.0
    norm_a = 0.0
    norm_b = 0.0
    keys = set(vec_a.keys()) | set(vec_b.keys())
    for key in keys:
        a = float(vec_a.get(key, 0.0))
        b = float(vec_b.get(key, 0.0))
        dot += a * b
        norm_a += a * a
        norm_b += b * b
    if norm_a == 0.0 or norm_b == 0.0:
        return 0.0
    return dot / (math.sqrt(norm_a) * math.sqrt(norm_b))


def _update_hygiene_from_reviews(restaurant):
    reviews = RestaurantReview.objects.filter(
        restaurant=restaurant,
    ).exclude(moderation_status=RestaurantReview.MODERATION_REMOVED)

    total = reviews.count()
    if total > 0:
        avg_rating = reviews.aggregate(Avg('rating'))['rating__avg']
        restaurant.user_rating = float(avg_rating or 0.0)
        restaurant.save(update_fields=['user_rating'])

    try:
        inspected_rating = float(restaurant.rating_value or 0.0)
    except ValueError:
        inspected_rating = 0.0

    user_rating = float(restaurant.user_rating or 0.0)
    prev_score = restaurant.hygiene_score
    new_score = 0.7 * inspected_rating + 0.3 * (user_rating * 20.0)
    new_score = max(0.0, min(100.0, new_score))

    if not HygieneScoreHistory.objects.filter(restaurant=restaurant).exists():
        HygieneScoreHistory.objects.create(
            restaurant=restaurant,
            score=prev_score,
            previous_score=None,
            source='initial',
        )

    restaurant.hygiene_score = new_score
    restaurant.save(update_fields=['hygiene_score'])

    if abs(new_score - prev_score) >= 0.001:
        HygieneScoreHistory.objects.create(
            restaurant=restaurant,
            score=new_score,
            previous_score=prev_score,
            source='nlp_update',
        )


def _build_user_restaurant_vectors():
    vectors = {}

    for review in RestaurantReview.objects.select_related('user', 'restaurant'):
        vectors.setdefault(review.user_id, {})[review.restaurant_id] = float(review.rating or 0.0)

    interaction_weights = {
        'view': 1.0,
        'like': 2.0,
        'favorite': 3.0,
        'rate': 4.0,
    }
    for interaction in UserInteraction.objects.select_related('user', 'restaurant'):
        weight = interaction_weights.get(interaction.interaction_type, 1.0)
        base = float(interaction.rating or weight)
        vectors.setdefault(interaction.user_id, {})
        current = vectors[interaction.user_id].get(interaction.restaurant_id, 0.0)
        vectors[interaction.user_id][interaction.restaurant_id] = max(current, base)

    return vectors


def _recommend_restaurants_user_based(user_id, limit=10):
    vectors = _build_user_restaurant_vectors()
    target = vectors.get(user_id)
    if not target:
        return []

    similarities = []
    for other_id, vec in vectors.items():
        if other_id == user_id:
            continue
        sim = _cosine_similarity_dict(target, vec)
        if sim > 0:
            similarities.append((other_id, sim))

    if not similarities:
        return []

    similarities.sort(key=lambda x: x[1], reverse=True)
    top_neighbors = similarities[:10]

    scores = {}
    sim_sums = {}
    for neighbor_id, sim in top_neighbors:
        neighbor_vec = vectors.get(neighbor_id, {})
        for rest_id, rating in neighbor_vec.items():
            if rest_id in target:
                continue
            scores[rest_id] = scores.get(rest_id, 0.0) + sim * float(rating)
            sim_sums[rest_id] = sim_sums.get(rest_id, 0.0) + abs(sim)

    ranked = []
    for rest_id, total in scores.items():
        denom = sim_sums.get(rest_id) or 1.0
        ranked.append((rest_id, total / denom))

    ranked.sort(key=lambda x: x[1], reverse=True)
    return [rest_id for rest_id, _ in ranked[:limit]]


def _build_dish_vectors():
    restaurants = list(Restaurant.objects.all())
    restaurant_ids = [r.id for r in restaurants]
    if not restaurant_ids:
        return [], {}, {}

    menu_items = list(
        RestaurantMenuItem.objects.filter(is_available=True)
        .values('restaurant_id', 'name', 'rating')
    )

    ratings_by_restaurant = {}
    for item in menu_items:
        rest_id = item['restaurant_id']
        ratings_by_restaurant.setdefault(rest_id, []).append(float(item.get('rating') or 0.0))

    mean_by_restaurant = {
        rest_id: (sum(ratings) / len(ratings) if ratings else 0.0)
        for rest_id, ratings in ratings_by_restaurant.items()
    }

    dish_vectors = {}
    for item in menu_items:
        dish = item['name']
        rest_id = item['restaurant_id']
        mean_rating = mean_by_restaurant.get(rest_id, 0.0)
        adjusted = float(item.get('rating') or 0.0) - mean_rating
        if dish not in dish_vectors:
            dish_vectors[dish] = [0.0 for _ in restaurant_ids]
        dish_vectors[dish][restaurant_ids.index(rest_id)] = adjusted

    return restaurant_ids, dish_vectors, mean_by_restaurant


def _rank_restaurants_by_dish_similarity(user_restaurant_ids, limit=10):
    # Item-based collaborative filtering (dish-to-dish cosine similarity)
    restaurant_ids, dish_vectors, _ = _build_dish_vectors()
    if not restaurant_ids or not dish_vectors:
        return []

    user_dishes = set(
        RestaurantMenuItem.objects.filter(
            restaurant_id__in=user_restaurant_ids,
            is_available=True,
        ).values_list('name', flat=True)
    )

    if not user_dishes:
        return []

    user_dish_vectors = [dish_vectors[d] for d in user_dishes if d in dish_vectors]
    if not user_dish_vectors:
        return []

    candidate_ids = [rid for rid in restaurant_ids if rid not in user_restaurant_ids]
    scores = []
    for rest_id in candidate_ids:
        candidate_dishes = list(
            RestaurantMenuItem.objects.filter(
                restaurant_id=rest_id,
                is_available=True,
            ).values_list('name', flat=True)
        )
        if not candidate_dishes:
            continue

        dish_scores = []
        for dish in candidate_dishes:
            vec = dish_vectors.get(dish)
            if vec is None:
                continue
            sims = [_cosine_similarity(vec, user_vec) for user_vec in user_dish_vectors]
            if sims:
                dish_scores.append(sum(sims) / len(sims))

        if dish_scores:
            scores.append((rest_id, sum(dish_scores) / len(dish_scores)))

    scores.sort(key=lambda x: x[1], reverse=True)
    return [rid for rid, _ in scores[:limit]]


def _recommend_dishes_item_based(user_restaurant_ids, limit=10):
    restaurant_ids, dish_vectors, mean_by_restaurant = _build_dish_vectors()
    if not restaurant_ids or not dish_vectors:
        return []

    user_dishes = set(
        RestaurantMenuItem.objects.filter(
            restaurant_id__in=user_restaurant_ids,
            is_available=True,
        ).values_list('name', flat=True)
    )
    if not user_dishes:
        return []

    user_dish_vectors = [dish_vectors[d] for d in user_dishes if d in dish_vectors]
    if not user_dish_vectors:
        return []

    dish_scores = []
    for dish_name, vec in dish_vectors.items():
        if dish_name in user_dishes:
            continue
        sims = [_cosine_similarity(vec, user_vec) for user_vec in user_dish_vectors]
        if not sims:
            continue
        dish_scores.append((dish_name, sum(sims) / len(sims)))

    dish_scores.sort(key=lambda x: x[1], reverse=True)
    top_dishes = [name for name, _ in dish_scores[:limit]]

    recommendations = []
    for dish_name in top_dishes:
        item = (
            RestaurantMenuItem.objects
            .filter(name=dish_name, is_available=True)
            .select_related('restaurant')
            .order_by('-rating')
            .first()
        )
        if item is None:
            continue
        avg = mean_by_restaurant.get(item.restaurant_id, 0.0)
        adjusted = float(item.rating or 0.0) - avg
        recommendations.append((item, adjusted))

    recommendations.sort(key=lambda x: x[1], reverse=True)
    return [item for item, _ in recommendations[:limit]]


class RecommendedRestaurantsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        interactions = UserInteraction.objects.filter(
            user=user,
            interaction_type__in=['view', 'like', 'favorite', 'rate'],
        )

        interacted_ids = list(interactions.values_list('restaurant', flat=True))
        if interacted_ids:
            ranked_ids = _rank_restaurants_by_dish_similarity(interacted_ids, limit=10)
            if ranked_ids:
                ranked_restaurants = list(Restaurant.objects.filter(id__in=ranked_ids))
                ranked_restaurants.sort(key=lambda r: ranked_ids.index(r.id))
                serializer = RestaurantSerializer(ranked_restaurants, many=True)
                return Response(serializer.data)

        qs = Restaurant.objects.all()
        ranked = [(r, _score(r)) for r in qs]
        ranked.sort(key=lambda x: x[1], reverse=True)
        top = [r for r, _score_value in ranked[:10]]
        serializer = RestaurantSerializer(top, many=True)
        return Response(serializer.data)


class UserBasedRecommendationsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        ranked_ids = _recommend_restaurants_user_based(user.id, limit=10)
        if ranked_ids:
            ranked_restaurants = list(Restaurant.objects.filter(id__in=ranked_ids))
            ranked_restaurants.sort(key=lambda r: ranked_ids.index(r.id))
            serializer = RestaurantSerializer(ranked_restaurants, many=True)
            return Response(serializer.data)

        return Response([], status=status.HTTP_200_OK)


class DishRecommendationsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        interactions = UserInteraction.objects.filter(
            user=user,
            interaction_type__in=['view', 'like', 'favorite', 'rate'],
        )
        interacted_ids = list(interactions.values_list('restaurant', flat=True))
        if not interacted_ids:
            return Response([], status=status.HTTP_200_OK)

        items = _recommend_dishes_item_based(interacted_ids, limit=10)
        results = []
        for item in items:
            results.append({
                'id': item.id,
                'name': item.name,
                'category': item.category,
                'description': item.description,
                'price': str(item.price),
                'rating': float(item.rating or 0.0),
                'restaurant': {
                    'id': item.restaurant.id,
                    'business_name': item.restaurant.business_name,
                    'business_type': item.restaurant.business_type,
                    'address': item.restaurant.address,
                    'province': item.restaurant.province,
                    'hygiene_score': float(item.restaurant.hygiene_score),
                },
            })
        return Response(results, status=status.HTTP_200_OK)


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
        user = User.objects.filter(username=username).first()
        if user is None:
            return Response({'message': 'OTP verified.'}, status=status.HTTP_200_OK)

        _ensure_user_state(user)
        token, _ = Token.objects.get_or_create(user=user)
        user_data = UserSerializer(user).data
        return Response(
            {'message': 'OTP verified.', 'token': token.key, 'user': user_data},
            status=status.HTTP_200_OK,
        )

    return Response({'error': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)


class SignUpView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        email = request.data.get('email') or username
        password = request.data.get('password')
        if not username or not password:
            return Response({'error': 'Username and password required.'}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username=username).exists():
            return Response({'error': 'Username already exists.'}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(username=username, password=password, email=email)
        _ensure_user_state(user)
        _apply_role_from_email(user)

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
        _apply_role_from_email(user)
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
        _apply_role_from_email(user)

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


@api_view(['GET'])
@permission_classes([AllowAny])
def restaurants_by_top_rating(request):
    qs = Restaurant.objects.all().order_by('-user_rating')
    serializer = RestaurantSerializer(qs, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([AllowAny])
def trending_restaurants(request):
    limit = int(request.query_params.get('n', 10))
    interactions = (
        UserInteraction.objects.values('restaurant')
        .annotate(total=Count('id'))
        .order_by('-total')
    )
    ranked_ids = [row['restaurant'] for row in interactions[:limit] if row['restaurant']]
    if not ranked_ids:
        qs = Restaurant.objects.all()
        ranked = [(r, _score(r)) for r in qs]
        ranked.sort(key=lambda x: x[1], reverse=True)
        top = [r for r, _score_value in ranked[:limit]]
        serializer = RestaurantSerializer(top, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    ranked_restaurants = list(Restaurant.objects.filter(id__in=ranked_ids))
    ranked_restaurants.sort(key=lambda r: ranked_ids.index(r.id))
    serializer = RestaurantSerializer(ranked_restaurants, many=True)
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
            Q(user=request.user) &
            (Q(restaurant__hygiene_score__lt=preferences.min_hygiene_score) | Q(alert_type=HygieneAlert.TYPE_INSPECTION_WARNING))
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
            Q(user=request.user) &
            (Q(restaurant__hygiene_score__lt=preferences.min_hygiene_score) | Q(alert_type=HygieneAlert.TYPE_INSPECTION_WARNING))
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
    history = list(
        HygieneScoreHistory.objects.filter(restaurant=restaurant).order_by('created_at')
    )
    if history:
        points = [
            {
                'month': entry.created_at.strftime('%b %d'),
                'score': round(float(entry.score), 1),
                'previous_score': round(float(entry.previous_score), 1) if entry.previous_score is not None else None,
                'source': entry.source,
            }
            for entry in history
        ]

        first_entry = history[0]
        if first_entry.source != 'initial' and first_entry.previous_score is not None:
            points.insert(
                0,
                {
                    'month': restaurant.inspection_date.strftime('%b %d'),
                    'score': round(float(first_entry.previous_score), 1),
                    'previous_score': None,
                    'source': 'initial',
                },
            )

        return points

    inspection_date = restaurant.inspection_date
    return [{
        'month': inspection_date.strftime('%b %d'),
        'score': round(float(restaurant.hygiene_score), 1),
        'previous_score': None,
        'source': 'current',
    }]


def _percent_change(current, previous):
    if previous == 0:
        return 100.0 if current > 0 else 0.0
    return ((current - previous) / previous) * 100.0


def _trend_label(current, previous):
    change = _percent_change(current, previous)
    return f"{change:+.0f}%"


def _inspection_color(score):
    if score < 70:
        return 'red'
    if score < 85:
        return 'amber'
    return 'green'


def _map_owner_report_status(status_value):
    if status_value == HygieneIssueReport.STATUS_SUBMITTED:
        return 'Open'
    if status_value == HygieneIssueReport.STATUS_REVIEWED:
        return 'Investigating'
    if status_value == HygieneIssueReport.STATUS_RESOLVED:
        return 'Resolved'
    return 'Open'


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

        _update_hygiene_from_reviews(restaurant)

        out = RestaurantReviewSerializer(review)
        return Response(out.data, status=status.HTTP_201_CREATED)


class HygieneIssueReportListCreateView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request, restaurant_id):
        reports = HygieneIssueReport.objects.filter(restaurant_id=restaurant_id, user=request.user)
        serializer = HygieneIssueReportSerializer(reports, many=True, context={'request': request})
        return Response({'count': reports.count(), 'results': serializer.data}, status=status.HTTP_200_OK)

    def post(self, request, restaurant_id):
        try:
            restaurant = Restaurant.objects.get(pk=restaurant_id)
        except Restaurant.DoesNotExist:
            return Response({'error': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        serializer = HygieneIssueReportCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        image_proof_file = request.FILES.get('image_proof')

        report = HygieneIssueReport.objects.create(
            user=request.user,
            restaurant=restaurant,
            category=serializer.validated_data['category'],
            description=serializer.validated_data['description'].strip(),
            image_proof=image_proof_file,
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

        out = HygieneIssueReportSerializer(report, context={'request': request})
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
        review = RestaurantReview.objects.filter(id=review_id, user=request.user).first()
        if review is None:
            return Response({'error': 'Review not found.'}, status=status.HTTP_404_NOT_FOUND)

        review_restaurant = review.restaurant
        review.delete()

        profile, _, _ = _ensure_user_state(request.user)
        profile.reviews_written = RestaurantReview.objects.filter(user=request.user).count()
        profile.save(update_fields=['reviews_written', 'updated_at'])

        if review_restaurant is not None:
            _update_hygiene_from_reviews(review_restaurant)
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


class OwnerDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        now = timezone.now()
        month_ago = now - timedelta(days=30)

        reviews = RestaurantReview.objects.filter(restaurant=restaurant)
        views = UserInteraction.objects.filter(restaurant=restaurant, interaction_type='view')

        total_reviews = reviews.count()
        avg_rating = reviews.aggregate(avg=Avg('rating')).get('avg') or 0.0
        monthly_visitors = views.filter(timestamp__gte=month_ago).count()
        prev_month = now - timedelta(days=60)
        prev_month_reviews = reviews.filter(created_at__gte=prev_month, created_at__lt=month_ago).count()
        prev_month_visitors = views.filter(timestamp__gte=prev_month, timestamp__lt=month_ago).count()

        recent_activities = []
        recent_reviews = reviews.order_by('-created_at')[:2]
        for review in recent_reviews:
            recent_activities.append({
                'type': 'review',
                'description': f"New review from {review.user.username}.",
                'time_ago': review.created_at.strftime('%b %d, %Y'),
            })

        recent_reports = HygieneIssueReport.objects.filter(restaurant=restaurant).order_by('-created_at')[:2]
        for report in recent_reports:
            recent_activities.append({
                'type': 'report',
                'description': f"New hygiene report: {report.get_category_display()}.",
                'time_ago': report.created_at.strftime('%b %d, %Y'),
            })

        data = {
            'restaurant_name': restaurant.business_name,
            'last_inspection_date': restaurant.inspection_date.strftime('%b %d, %Y'),
            'hygiene_score': float(restaurant.hygiene_score),
            'total_reviews': total_reviews,
            'review_trend': _trend_label(total_reviews, prev_month_reviews),
            'average_rating': round(float(avg_rating), 1),
            'monthly_visitors': monthly_visitors,
            'visitor_trend': _trend_label(monthly_visitors, prev_month_visitors),
            'hygiene_trend': _build_hygiene_history(restaurant),
            'recent_activities': recent_activities,
        }

        return Response(data, status=status.HTTP_200_OK)


class OwnerReviewsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        reviews = RestaurantReview.objects.filter(restaurant=restaurant).select_related('user').order_by('-created_at')
        results = []
        for review in reviews:
            owner_response = None
            if hasattr(review, 'owner_response'):
                owner_response = {
                    'text': review.owner_response.text,
                    'date': review.owner_response.created_at.strftime('%b %d, %Y'),
                }
            
            nlp_data = _predict_sentiment(review.comment)
            sentiment_label = nlp_data['label']

            helpful_count = review.owner_flags.filter(flag_type='helpful').count()
            is_helpful = review.owner_flags.filter(owner=request.user, flag_type='helpful').exists()
            is_reported = review.owner_flags.filter(owner=request.user, flag_type='report').exists()

            results.append({
                'id': str(review.id),
                'user_name': review.user.username,
                'rating': int(review.rating or 0),
                'date': review.created_at.strftime('%b %d, %Y'),
                'review_text': (review.comment or '').strip(),
                'sentiment': sentiment_label,
                'helpful_count': helpful_count,
                'is_helpful': is_helpful,
                'is_reported': is_reported,
                'owner_response': owner_response,
            })

        return Response({'results': results}, status=status.HTTP_200_OK)


class OwnerReviewFlagView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, review_id):
        flag_type = request.data.get('flag_type')
        if flag_type not in ['helpful', 'report']:
            return Response({'detail': 'Invalid flag type.'}, status=status.HTTP_400_BAD_REQUEST)

        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        review = RestaurantReview.objects.filter(id=review_id, restaurant=restaurant).first()
        if review is None:
            return Response({'detail': 'Review not found.'}, status=status.HTTP_404_NOT_FOUND)

        flag, created = OwnerReviewFlag.objects.get_or_create(
            review=review,
            owner=request.user,
            flag_type=flag_type,
        )

        return Response(
            {
                'detail': f'Review marked as {flag_type}.',
                'helpful_count': review.owner_flags.filter(flag_type='helpful').count(),
                'is_helpful': review.owner_flags.filter(owner=request.user, flag_type='helpful').exists(),
                'is_reported': review.owner_flags.filter(owner=request.user, flag_type='report').exists(),
            },
            status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED,
        )


class OwnerReviewResponseView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, review_id):
        text = (request.data.get('text') or '').strip()
        if not text:
            return Response({'detail': 'Response text is required.'}, status=status.HTTP_400_BAD_REQUEST)

        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        review = RestaurantReview.objects.filter(id=review_id, restaurant=restaurant).first()
        if review is None:
            return Response({'detail': 'Review not found.'}, status=status.HTTP_404_NOT_FOUND)

        response_obj, _created = OwnerReviewResponse.objects.update_or_create(
            review=review,
            defaults={'text': text},
        )

        return Response(
            {
                'text': response_obj.text,
                'date': response_obj.created_at.strftime('%b %d, %Y'),
            },
            status=status.HTTP_200_OK,
        )


class OwnerHygieneReportsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        reports = HygieneIssueReport.objects.filter(restaurant=restaurant).order_by('-created_at')
        results = []
        for report in reports:
            owner_response = None
            if hasattr(report, 'owner_response'):
                owner_response = {
                    'text': report.owner_response.text,
                    'date': report.owner_response.created_at.strftime('%b %d, %Y'),
                    'evidence_url': request.build_absolute_uri(report.owner_response.evidence.url) if report.owner_response.evidence else None,
                    'evidence_image_url': request.build_absolute_uri(report.owner_response.evidence_image.url) if report.owner_response.evidence_image else None,
                }
            results.append({
                'id': str(report.id),
                'report_id': f"#RPT-{report.created_at.year}-{report.id:03d}",
                'date_submitted': report.created_at.strftime('%b %d, %Y'),
                'created_at': report.created_at.isoformat(),
                'issue_type': report.get_category_display(),
                'priority': _admin_report_priority(report.category).title(),
                'description': report.description,
                'image_proof_url': request.build_absolute_uri(report.image_proof.url) if report.image_proof else None,
                'status': _map_owner_report_status(report.status),
                'owner_response': owner_response,
            })

        return Response({'results': results}, status=status.HTTP_200_OK)


class OwnerHygieneReportResponseView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request, report_id):
        text = (request.data.get('text') or '').strip()
        if not text:
            return Response({'detail': 'Response text is required.'}, status=status.HTTP_400_BAD_REQUEST)

        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        report = HygieneIssueReport.objects.filter(id=report_id, restaurant=restaurant).first()
        if report is None:
            return Response({'detail': 'Report not found.'}, status=status.HTTP_404_NOT_FOUND)

        evidence_file = request.FILES.get('evidence')
        evidence_image_file = request.FILES.get('evidence_image')
        
        defaults = {'text': text}
        if evidence_file:
            defaults['evidence'] = evidence_file
        if evidence_image_file:
            defaults['evidence_image'] = evidence_image_file

        response_obj, _created = OwnerReportResponse.objects.update_or_create(
            report=report,
            defaults=defaults,
        )

        if report.status == HygieneIssueReport.STATUS_SUBMITTED:
            report.status = HygieneIssueReport.STATUS_REVIEWED
            report.save(update_fields=['status'])

        evidence_url = None
        if response_obj.evidence:
            evidence_url = request.build_absolute_uri(response_obj.evidence.url)

        evidence_image_url = None
        if response_obj.evidence_image:
            evidence_image_url = request.build_absolute_uri(response_obj.evidence_image.url)

        return Response(
            {
                'text': response_obj.text,
                'date': response_obj.created_at.strftime('%b %d, %Y'),
                'evidence_url': evidence_url,
                'evidence_image_url': evidence_image_url,
            },
            status=status.HTTP_200_OK,
        )



class OwnerAnalyticsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        period = request.query_params.get('period', '30d')
        days_lookup = {'7d': 7, '30d': 30, '90d': 90, '12m': 365}
        days = days_lookup.get(period, 30)
        end_date = timezone.now()
        start_date = end_date - timedelta(days=days)

        reviews = RestaurantReview.objects.filter(restaurant=restaurant)
        scoped_reviews = reviews.filter(created_at__gte=start_date)
        total_reviews = scoped_reviews.count()
        avg_rating = scoped_reviews.aggregate(avg=Avg('rating')).get('avg') or 0.0

        pos = scoped_reviews.filter(rating__gte=4).count()
        neutral = scoped_reviews.filter(rating=3).count()
        neg = scoped_reviews.filter(rating__lte=2).count()
        mixed = max(0, total_reviews - (pos + neutral + neg))

        def percent(value, total):
            if total == 0:
                return 0
            return round((value / total) * 100)

        buckets = 4
        bucket_size = max(1, days // buckets)
        reviews_over_time = []
        for idx in range(buckets):
            bucket_start = start_date + timedelta(days=idx * bucket_size)
            bucket_end = bucket_start + timedelta(days=bucket_size)
            count = scoped_reviews.filter(created_at__gte=bucket_start, created_at__lt=bucket_end).count()
            reviews_over_time.append({'x': idx, 'y': float(count)})

        inspection_history = [
            {
                'id': 0,
                'date': restaurant.inspection_date.strftime('%b %d, %Y'),
                'inspector': 'Official Inspector',
                'score': round(float(restaurant.hygiene_score), 1),
                'status': 'Passed' if float(restaurant.hygiene_score) >= 70 else 'Failed',
                'color': _inspection_color(float(restaurant.hygiene_score)),
                'notes': f"Official routine inspection conducted on {restaurant.inspection_date.strftime('%B %d, %Y')}. The establishment received a score of {round(float(restaurant.hygiene_score), 1)}% based on sanitary standards.",
            }
        ]

        latest_request = restaurant.inspection_requests.first()
        if latest_request is not None:
            req_color = 'amber'
            if latest_request.status == latest_request.STATUS_APPROVED:
                req_color = 'green'
            elif latest_request.status == latest_request.STATUS_DENIED:
                req_color = 'red'

            inspection_history.insert(0, {
                'id': latest_request.id,
                'date': latest_request.created_at.strftime('%b %d, %Y'),
                'inspector': 'Requested',
                'score': None,
                'status': latest_request.get_status_display(),
                'color': req_color,
                'notes': latest_request.notes or 'No notes provided by owner.',
            })


        data = {
            'period': period,
            'key_metrics': {
                'reviews_received': total_reviews,
                'avg_hygiene_score': float(restaurant.hygiene_score),
                'customer_satisfaction': round(float(avg_rating) * 20, 1),
                'reports_filed': HygieneIssueReport.objects.filter(restaurant=restaurant).count(),
            },
            'hygiene_breakdown': [
                {'category': 'Food Safety', 'score': float(restaurant.hygiene_score)},
                {'category': 'Cleanliness', 'score': float(restaurant.hygiene_score)},
                {'category': 'Staff Hygiene', 'score': float(restaurant.hygiene_score)},
                {'category': 'Kitchen Conditions', 'score': float(restaurant.hygiene_score)},
                {'category': 'Pest Control', 'score': float(restaurant.hygiene_score)},
                {'category': 'Storage', 'score': float(restaurant.hygiene_score)},
            ],
            'sentiment': [
                {'name': 'Positive', 'value': float(pos), 'percentage': percent(pos, total_reviews)},
                {'name': 'Neutral', 'value': float(neutral), 'percentage': percent(neutral, total_reviews)},
                {'name': 'Negative', 'value': float(neg), 'percentage': percent(neg, total_reviews)},
                {'name': 'Mixed', 'value': float(mixed), 'percentage': percent(mixed, total_reviews)},
            ],
            'reviews_over_time': reviews_over_time,
            'top_keywords': [],
            'inspection_history': inspection_history,
        }

        return Response(data, status=status.HTTP_200_OK)


class OwnerInspectionRequestView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        pending = InspectionRequest.objects.filter(
            restaurant=restaurant,
            status=InspectionRequest.STATUS_PENDING,
        ).first()
        if pending is not None:
            return Response(
                {'detail': 'An inspection request is already pending.'},
                status=status.HTTP_200_OK,
            )

        notes = (request.data.get('notes') or '').strip()
        req = InspectionRequest.objects.create(
            restaurant=restaurant,
            requested_by=request.user,
            notes=notes,
        )

        return Response(
            {
                'detail': 'Inspection request submitted.',
                'id': req.id,
                'status': req.status,
                'created_at': req.created_at,
            },
            status=status.HTTP_201_CREATED,
        )


class OwnerRestaurantProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        data = {
            'id': restaurant.id,
            'name': restaurant.business_name,
            'cuisine': restaurant.business_type,
            'street': restaurant.address,
            'city': restaurant.province,
            'state': '',
            'zip': restaurant.post_code,
            'description': restaurant.description,
            'phone': restaurant.phone,
            'email': restaurant.email,
            'price_range': restaurant.price_range,
        }

        return Response(data, status=status.HTTP_200_OK)

    def patch(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        restaurant.business_name = request.data.get('name', restaurant.business_name)
        restaurant.business_type = request.data.get('cuisine', restaurant.business_type)
        restaurant.address = request.data.get('street', restaurant.address)
        restaurant.province = request.data.get('city', restaurant.province)
        restaurant.post_code = request.data.get('zip', restaurant.post_code)
        restaurant.description = request.data.get('description', restaurant.description)
        restaurant.phone = request.data.get('phone', restaurant.phone)
        restaurant.email = request.data.get('email', restaurant.email)
        restaurant.price_range = request.data.get('price_range', restaurant.price_range)
        restaurant.save()

        return Response({'detail': 'Restaurant updated.'}, status=status.HTTP_200_OK)


class OwnerRestaurantMenuView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        items = RestaurantMenuItem.objects.filter(restaurant=restaurant)
        serializer = RestaurantMenuItemSerializer(items, many=True)
        return Response({'results': serializer.data}, status=status.HTTP_200_OK)

    def post(self, request):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        item = RestaurantMenuItem.objects.create(
            restaurant=restaurant,
            name=request.data.get('name', ''),
            category=request.data.get('category', 'Other'),
            description=request.data.get('description', ''),
            price=request.data.get('price', 0),
            rating=request.data.get('rating', 0) or 0,
            order_count=request.data.get('order_count', 0) or 0,
            is_available=bool(request.data.get('is_available', True)),
        )
        serializer = RestaurantMenuItemSerializer(item)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class OwnerRestaurantMenuItemView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, item_id):
        restaurant = _get_owner_restaurant(request)
        if restaurant is None:
            return Response({'detail': 'Owner restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        item = RestaurantMenuItem.objects.filter(id=item_id, restaurant=restaurant).first()
        if item is None:
            return Response({'detail': 'Menu item not found.'}, status=status.HTTP_404_NOT_FOUND)

        item.delete()
        return Response({'detail': 'Menu item deleted.'}, status=status.HTTP_200_OK)


class AdminOverviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        total_restaurants = Restaurant.objects.count()
        total_users = User.objects.count()
        avg_hygiene = Restaurant.objects.aggregate(avg=Avg('hygiene_score')).get('avg') or 0.0

        pending_reports = HygieneIssueReport.objects.filter(
            status=HygieneIssueReport.STATUS_SUBMITTED,
        ).count()

        flagged_reviews = 0
        for review in RestaurantReview.objects.all():
            nlp_data = _analyze_review_nlp(review.comment)
            flag_meta = _review_flag_metadata(review, nlp_data)
            if flag_meta['flagged']:
                flagged_reviews += 1

        top_stats = [
            {
                'key': 'total_restaurants',
                'label': 'Total Restaurants',
                'value': total_restaurants,
                'trend': _trend_label(total_restaurants, 0),
            },
            {
                'key': 'total_users',
                'label': 'Total Users',
                'value': total_users,
                'trend': _trend_label(total_users, 0),
            },
            {
                'key': 'avg_hygiene',
                'label': 'Avg Hygiene Score',
                'value': round(float(avg_hygiene), 1),
                'trend': _trend_label(avg_hygiene, 0),
            },
            {
                'key': 'pending_reports',
                'label': 'Pending Reports',
                'value': pending_reports,
                'trend': _trend_label(pending_reports, 0),
            },
            {
                'key': 'flagged_reviews',
                'label': 'Flagged Reviews',
                'value': flagged_reviews,
                'trend': _trend_label(flagged_reviews, 0),
            },
        ]

        buckets = [
            {'min': 0, 'max': 20, 'label': '0-20'},
            {'min': 21, 'max': 40, 'label': '21-40'},
            {'min': 41, 'max': 60, 'label': '41-60'},
            {'min': 61, 'max': 80, 'label': '61-80'},
            {'min': 81, 'max': 100, 'label': '81-100'},
        ]
        distribution = []
        for bucket in buckets:
            count = Restaurant.objects.filter(
                hygiene_score__gte=bucket['min'],
                hygiene_score__lte=bucket['max'],
            ).count()
            distribution.append({'range': bucket['label'], 'count': count})

        now = timezone.now()
        reports_trend = []
        for offset in range(5, -1, -1):
            month_start = (now.replace(day=1) - timedelta(days=offset * 31)).replace(day=1)
            next_month = (month_start + timedelta(days=32)).replace(day=1)
            total = HygieneIssueReport.objects.filter(
                created_at__gte=month_start,
                created_at__lt=next_month,
            ).count()
            resolved = HygieneIssueReport.objects.filter(
                created_at__gte=month_start,
                created_at__lt=next_month,
                status=HygieneIssueReport.STATUS_RESOLVED,
            ).count()
            reports_trend.append({
                'month': month_start.strftime('%b'),
                'total': float(total),
                'resolved': float(resolved),
            })

        activities = []
        recent_reviews = RestaurantReview.objects.select_related('restaurant', 'user').order_by('-created_at')[:5]
        for review in recent_reviews:
            activities.append({
                'type': 'review',
                'text': f"New review for {review.restaurant.business_name}",
                'time': review.created_at.isoformat(),
            })

        recent_reports = HygieneIssueReport.objects.select_related('restaurant', 'user').order_by('-created_at')[:5]
        for report in recent_reports:
            activities.append({
                'type': 'report',
                'text': f"New report for {report.restaurant.business_name}",
                'time': report.created_at.isoformat(),
            })

        recent_requests = InspectionRequest.objects.select_related('restaurant', 'requested_by').order_by('-created_at')[:5]
        for req in recent_requests:
            activities.append({
                'type': 'inspection_request',
                'text': f"Inspection requested for {req.restaurant.business_name}",
                'time': req.created_at.isoformat(),
            })

        recent_flags = OwnerReviewFlag.objects.select_related('review', 'owner', 'review__restaurant').order_by('-created_at')[:10]
        for flag in recent_flags:
            activities.append({
                'type': 'report' if flag.flag_type == 'report' else 'inspection_request',
                'text': f"Owner flagged Review #{flag.review.id} as {flag.flag_type.upper()} for {flag.review.restaurant.business_name}",
                'time': flag.created_at.isoformat(),
            })

        activities.sort(key=lambda item: item['time'], reverse=True)
        activities = activities[:10]

        return Response(
            {
                'top_stats': top_stats,
                'score_distribution': distribution,
                'reports_trend': reports_trend,
                'recent_activity': activities,
            },
            status=status.HTTP_200_OK,
        )


class AdminRestaurantsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        restaurants = Restaurant.objects.select_related('owner').all()
        results = []
        thirty_days_ago = timezone.now() - timedelta(days=30)
        for restaurant in restaurants:
            reviews_count = RestaurantReview.objects.filter(restaurant=restaurant).count()
            recent_reports = HygieneIssueReport.objects.filter(
                restaurant=restaurant,
                created_at__gte=thirty_days_ago,
            ).count()
            owner_name = restaurant.owner.get_full_name() if restaurant.owner else ''
            if not owner_name and restaurant.owner:
                owner_name = restaurant.owner.username

            status_value = restaurant.status
            if not status_value:
                status_value = _restaurant_status(float(restaurant.hygiene_score or 0.0))

            results.append({
                'id': str(restaurant.id),
                'name': restaurant.business_name,
                'cuisine': restaurant.business_type,
                'hygiene_score': int(round(float(restaurant.hygiene_score or 0))),
                'reviews_count': reviews_count,
                'status': status_value.replace('_', ' ').title(),
                'last_inspection': restaurant.inspection_date.strftime('%Y-%m-%d'),
                'location': f"{restaurant.address}, {restaurant.province}",
                'phone': restaurant.phone,
                'owner': owner_name,
                'recent_reports': recent_reports,
            })

        return Response({'results': results}, status=status.HTTP_200_OK)

    def post(self, request):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        name = (request.data.get('name') or '').strip()
        cuisine = (request.data.get('cuisine') or '').strip()
        location = (request.data.get('location') or '').strip()
        phone = (request.data.get('phone') or '').strip()

        if not name:
            return Response({'detail': 'Restaurant name is required.'}, status=status.HTTP_400_BAD_REQUEST)

        restaurant = Restaurant.objects.create(
            business_name=name,
            business_type=cuisine or 'Other',
            rating_value='',
            inspection_date=timezone.now().date(),
            address=location or '',
            post_code='',
            province='',
            user_rating=0,
            hygiene_score=0,
            phone=phone,
            status=Restaurant.STATUS_ACTIVE,
        )

        return Response({'id': restaurant.id}, status=status.HTTP_201_CREATED)


class AdminReportsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        reports = HygieneIssueReport.objects.select_related('restaurant', 'user').order_by('-created_at')
        results = []
        for report in reports:
            owner_response = None
            if hasattr(report, 'owner_response'):
                owner_response = {
                    'text': report.owner_response.text,
                    'date': report.owner_response.created_at.strftime('%Y-%m-%d'),
                    'evidence_url': request.build_absolute_uri(report.owner_response.evidence.url) if report.owner_response.evidence else None,
                    'evidence_image_url': request.build_absolute_uri(report.owner_response.evidence_image.url) if report.owner_response.evidence_image else None,
                }
            results.append({
                'id': str(report.id),
                'report_id': f"RPT-{report.created_at.year}-{report.id:03d}",
                'submitted_date': report.created_at.strftime('%Y-%m-%d'),
                'reporter': {
                    'name': report.user.get_full_name() or report.user.username,
                    'is_anonymous': False,
                    'email': report.user.email,
                    'phone': '',
                },
                'restaurant': {
                    'name': report.restaurant.business_name,
                    'id': str(report.restaurant.id),
                    'current_score': int(round(float(report.restaurant.hygiene_score or 0))),
                },
                'issue_type': _admin_issue_type(report.category),
                'priority': _admin_report_priority(report.category),
                'status': _admin_report_status(report.status),
                'description': report.description,
                'photos': [request.build_absolute_uri(report.image_proof.url)] if report.image_proof else [],
                'nlp_analysis': _analyze_report_nlp(report.description),
                'owner_response': owner_response,
                'timeline': [
                    {
                        'status': 'Report Submitted',
                        'timestamp': report.created_at.strftime('%Y-%m-%d'),
                        'admin': 'System',
                    }
                ],
            })

        return Response({'results': results}, status=status.HTTP_200_OK)


class AdminReviewsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        reviews = RestaurantReview.objects.select_related('restaurant', 'user').order_by('-created_at')
        results = []
        for review in reviews:
            if review.moderation_status != RestaurantReview.MODERATION_PENDING:
                continue
            nlp_data = _analyze_review_nlp(review.comment)
            flag_meta = _review_flag_metadata(review, nlp_data)
            
            owner_flags = list(review.owner_flags.all())
            has_owner_flags = len(owner_flags) > 0
            
            if not flag_meta['flagged'] and not has_owner_flags:
                continue
                
            reviewer_age_days = (timezone.now().date() - review.user.date_joined.date()).days
            
            flag_reason_type = flag_meta['flag_reason_type']
            flag_reason_source = flag_meta['flag_reason_source']
            flag_category = flag_meta['flag_category']
            flag_reason_note = None
            
            if has_owner_flags:
                flag_reason_type = 'manual'
                flag_category = 'user-reported'
                flag_reasons = [f"Owner {f.flag_type.upper()}" for f in owner_flags]
                if flag_meta['flagged']:
                    flag_reason_source = f"{flag_reason_source}, {', '.join(flag_reasons)}"
                else:
                    flag_reason_source = ', '.join(flag_reasons)
                flag_reason_note = f"Owner flagged this review: {', '.join([f.flag_type for f in owner_flags])}"

            results.append({
                'id': str(review.id),
                'review_text': review.comment,
                'rating': int(review.rating or 0),
                'reviewer_name': review.user.get_full_name() or review.user.username,
                'reviewer_account_age': f"{reviewer_age_days} days",
                'reviewer_total_reviews': RestaurantReview.objects.filter(user=review.user).count(),
                'restaurant_name': review.restaurant.business_name,
                'restaurant_id': str(review.restaurant.id),
                'flag_reason_type': flag_reason_type,
                'flag_reason_source': flag_reason_source,
                'flag_reason_note': flag_reason_note,
                'nlp_sentiment_score': nlp_data['sentiment_score'],
                'nlp_sentiment_label': nlp_data['sentiment_label'],
                'nlp_detected_issues': nlp_data['detected_issues'],
                'nlp_confidence_score': nlp_data['confidence_score'],
                'nlp_key_phrases': nlp_data['key_phrases'],
                'nlp_toxicity_score': nlp_data['toxicity_score'],
                'nlp_problematic_words': nlp_data['problematic_words'],
                'submitted_date': review.created_at.strftime('%Y-%m-%d'),
                'flag_category': flag_category,
                'admin_note': review.admin_note,
            })

        return Response({'flagged_reviews': results, 'moderation_history': []}, status=status.HTTP_200_OK)


class AdminRestaurantDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, restaurant_id):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        restaurant = Restaurant.objects.select_related('owner').filter(id=restaurant_id).first()
        if restaurant is None:
            return Response({'detail': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        owner_name = restaurant.owner.get_full_name() if restaurant.owner else ''
        if not owner_name and restaurant.owner:
            owner_name = restaurant.owner.username

        status_value = restaurant.status
        if not status_value:
            status_value = _restaurant_status(float(restaurant.hygiene_score or 0.0))

        payload = {
            'id': str(restaurant.id),
            'name': restaurant.business_name,
            'cuisine': restaurant.business_type,
            'hygiene_score': float(restaurant.hygiene_score or 0.0),
            'status': status_value.replace('_', ' ').title(),
            'last_inspection': restaurant.inspection_date.strftime('%Y-%m-%d') if restaurant.inspection_date else '',
            'location': f"{restaurant.address}, {restaurant.province}",
            'phone': restaurant.phone,
            'owner': owner_name,
            'admin_notes': restaurant.admin_notes or '',
            'hygiene_history': _build_hygiene_history(restaurant),
        }
        return Response(payload, status=status.HTTP_200_OK)

    def patch(self, request, restaurant_id):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        restaurant = Restaurant.objects.filter(id=restaurant_id).first()
        if restaurant is None:
            return Response({'detail': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        status_value = request.data.get('status')
        if status_value:
            normalized = status_value.strip().lower().replace(' ', '_')
            if normalized in [Restaurant.STATUS_ACTIVE, Restaurant.STATUS_SUSPENDED, Restaurant.STATUS_UNDER_REVIEW]:
                restaurant.status = normalized

        if 'hygiene_score' in request.data:
            inspected_rating = float(request.data.get('hygiene_score') or 0.0)
            restaurant.rating_value = str(int(inspected_rating))
            
            user_rating = float(restaurant.user_rating or 0.0)
            prev_score = restaurant.hygiene_score
            new_score = 0.7 * inspected_rating + 0.3 * (user_rating * 20.0)
            restaurant.hygiene_score = max(0.0, min(100.0, new_score))
            
            if not HygieneScoreHistory.objects.filter(restaurant=restaurant).exists():
                HygieneScoreHistory.objects.create(
                    restaurant=restaurant,
                    score=prev_score,
                    previous_score=None,
                    source='initial',
                )
            HygieneScoreHistory.objects.create(
                restaurant=restaurant,
                score=restaurant.hygiene_score,
                previous_score=prev_score,
                source='admin_update'
            )

        if 'admin_notes' in request.data:
            restaurant.admin_notes = request.data.get('admin_notes') or ''

        restaurant.save()
        return Response({'detail': 'Restaurant updated.'}, status=status.HTTP_200_OK)

    def delete(self, request, restaurant_id):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        deleted, _ = Restaurant.objects.filter(id=restaurant_id).delete()
        if deleted == 0:
            return Response({'detail': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response({'detail': 'Restaurant deleted.'}, status=status.HTTP_200_OK)


class AdminRestaurantActionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, restaurant_id):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        restaurant = Restaurant.objects.select_related('owner').filter(id=restaurant_id).first()
        if restaurant is None:
            return Response({'detail': 'Restaurant not found.'}, status=status.HTTP_404_NOT_FOUND)

        action = (request.data.get('action') or '').strip().lower()

        if action == 'schedule_inspection':
            notes = (request.data.get('notes') or '').strip()
            inspection_date = (request.data.get('inspection_date') or '').strip()

            if inspection_date:
                try:
                    restaurant.inspection_date = date.fromisoformat(inspection_date)
                except ValueError:
                    return Response({'detail': 'Invalid inspection_date.'}, status=status.HTTP_400_BAD_REQUEST)
                restaurant.save(update_fields=['inspection_date'])

            InspectionRequest.objects.create(
                restaurant=restaurant,
                requested_by=request.user,
                notes=notes,
            )
            return Response({'detail': 'Inspection scheduled.'}, status=status.HTTP_200_OK)

        if action == 'send_warning':
            message = (request.data.get('message') or '').strip() or 'Inspection warning issued.'
            if restaurant.owner:
                HygieneAlert.objects.create(
                    user=restaurant.owner,
                    restaurant=restaurant,
                    alert_type=HygieneAlert.TYPE_INSPECTION_WARNING,
                    message=message,
                    score_snapshot=int(round(float(restaurant.hygiene_score or 0.0))),
                )
            return Response({'detail': 'Warning sent.'}, status=status.HTTP_200_OK)

        return Response({'detail': 'Invalid action.'}, status=status.HTTP_400_BAD_REQUEST)


class AdminReportStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, report_id):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        report = HygieneIssueReport.objects.filter(id=report_id).first()
        if report is None:
            return Response({'detail': 'Report not found.'}, status=status.HTTP_404_NOT_FOUND)

        status_value = (request.data.get('status') or '').strip().lower()
        mapping = {
            'pending': HygieneIssueReport.STATUS_SUBMITTED,
            'investigating': HygieneIssueReport.STATUS_REVIEWED,
            'resolved': HygieneIssueReport.STATUS_RESOLVED,
            'dismissed': HygieneIssueReport.STATUS_RESOLVED,
        }
        if status_value in mapping:
            report.status = mapping[status_value]
            report.save(update_fields=['status'])

        return Response({'detail': 'Report status updated.'}, status=status.HTTP_200_OK)


class AdminReviewActionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, review_id):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        review = RestaurantReview.objects.select_related('user').filter(id=review_id).first()
        if review is None:
            return Response({'detail': 'Review not found.'}, status=status.HTTP_404_NOT_FOUND)

        action = (request.data.get('action') or '').strip().lower()
        edited_text = (request.data.get('edited_text') or '').strip()
        admin_note = request.data.get('admin_note')

        if action == 'approve':
            review.moderation_status = RestaurantReview.MODERATION_APPROVED
        elif action == 'remove':
            review.moderation_status = RestaurantReview.MODERATION_REMOVED
        elif action == 'dismiss':
            review.moderation_status = RestaurantReview.MODERATION_DISMISSED
        elif action == 'edit':
            if edited_text:
                review.comment = edited_text
            review.moderation_status = RestaurantReview.MODERATION_APPROVED
        elif action == 'ban':
            review.user.is_active = False
            review.user.save(update_fields=['is_active'])
            review.moderation_status = RestaurantReview.MODERATION_REMOVED
        else:
            return Response({'detail': 'Invalid action.'}, status=status.HTTP_400_BAD_REQUEST)

        if admin_note is not None:
            review.admin_note = admin_note

        review.save(update_fields=['comment', 'moderation_status', 'admin_note'])
        _update_hygiene_from_reviews(review.restaurant)
        return Response({'detail': 'Review updated.'}, status=status.HTTP_200_OK)


class AdminNLPPredictView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        text = request.data.get('text', '').strip()
        if not text:
            return Response({'detail': 'Text is required.'}, status=status.HTTP_400_BAD_REQUEST)

        nlp_data = _analyze_review_nlp(text)
        return Response(nlp_data, status=status.HTTP_200_OK)


class AdminNLPSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        if not _is_admin_user(request.user):
            return Response({'detail': 'Admin access required.'}, status=status.HTTP_403_FORBIDDEN)

        total_reviews = RestaurantReview.objects.count()
        positive_count = 0
        negative_count = 0
        neutral_count = 0

        all_reviews = RestaurantReview.objects.all()
        for review in all_reviews:
            pred = _predict_sentiment(review.comment)
            if pred['label'] == 'Positive':
                positive_count += 1
            elif pred['label'] == 'Negative':
                negative_count += 1
            else:
                neutral_count += 1

        sentiment_dist = {
            'positive': positive_count,
            'negative': negative_count,
            'neutral': neutral_count
        }

        pos_keywords = {}
        neg_keywords = {}
        for review in all_reviews:
            pred = _predict_sentiment(review.comment)
            words = _clean_review_text(review.comment).split()
            target_dict = pos_keywords if pred['label'] == 'Positive' else (neg_keywords if pred['label'] == 'Negative' else None)
            if target_dict is not None:
                for w in words:
                    if len(w) > 3:
                        target_dict[w] = target_dict.get(w, 0) + 1

        top_pos = [{'word': k.capitalize(), 'count': v} for k, v in sorted(pos_keywords.items(), key=lambda item: item[1], reverse=True)[:5]]
        top_neg = [{'word': k.capitalize(), 'count': v} for k, v in sorted(neg_keywords.items(), key=lambda item: item[1], reverse=True)[:5]]

        return Response({
            'model_name': 'Logistic Regression / TF-IDF',
            'model_accuracy': 75.0,
            'total_reviews_analyzed': total_reviews,
            'sentiment_distribution': sentiment_dist,
            'top_positive_words': top_pos,
            'top_negative_words': top_neg,
            'model_status': 'Active',
            'last_trained': '2026-05-23'
        }, status=status.HTTP_200_OK)
