from rest_framework import serializers
from django.contrib.auth.models import User
from django.utils import timezone
from .models import (
    Restaurant,
    UserInteraction,
    UserProfile,
    UserPreference,
    NotificationSetting,
    FavoriteRestaurant,
    HygieneAlert,
    RestaurantMenuItem,
    RestaurantReview,
    HygieneIssueReport,
    OwnerReviewResponse,
    OwnerReportResponse
)

class RestaurantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Restaurant
        fields = '__all__'

class UserInteractionSerializer(serializers.ModelSerializer):
    def validate(self, attrs):
        # Only require `rating` when the interaction represents a user rating.
        if attrs.get('interaction_type') == 'rate' and attrs.get('rating') is None:
            raise serializers.ValidationError({
                'rating': 'This field is required when interaction_type is "rate".'
            })
        return attrs

    class Meta:
        model = UserInteraction
        fields = ['id', 'user', 'restaurant', 'interaction_type', 'rating', 'timestamp']
        read_only_fields = ['id', 'timestamp', 'user']
        extra_kwargs = {
            'rating': {'required': False, 'allow_null': True},
        }


class FavoriteRestaurantCreateSerializer(serializers.Serializer):
    restaurant_id = serializers.IntegerField(required=False)
    restaurant = serializers.IntegerField(required=False)

    def validate(self, attrs):
        restaurant_id = attrs.get('restaurant_id') or attrs.get('restaurant')
        if not restaurant_id:
            raise serializers.ValidationError({'restaurant_id': 'This field is required.'})
        try:
            restaurant = Restaurant.objects.get(pk=restaurant_id)
        except Restaurant.DoesNotExist as exc:
            raise serializers.ValidationError({'restaurant_id': 'Restaurant not found.'}) from exc

        attrs['restaurant_obj'] = restaurant
        return attrs


class FavoriteRestaurantSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(source='restaurant.id', read_only=True)
    business_name = serializers.CharField(source='restaurant.business_name', read_only=True)
    business_type = serializers.CharField(source='restaurant.business_type', read_only=True)
    address = serializers.CharField(source='restaurant.address', read_only=True)
    post_code = serializers.CharField(source='restaurant.post_code', read_only=True)
    province = serializers.CharField(source='restaurant.province', read_only=True)
    user_rating = serializers.FloatField(source='restaurant.user_rating', read_only=True)
    hygiene_score = serializers.FloatField(source='restaurant.hygiene_score', read_only=True)
    inspection_date = serializers.DateField(source='restaurant.inspection_date', read_only=True)
    imageUrl = serializers.SerializerMethodField()
    category = serializers.SerializerMethodField()
    price = serializers.SerializerMethodField()
    distance = serializers.SerializerMethodField()
    description = serializers.SerializerMethodField()
    favorite_id = serializers.IntegerField(source='id', read_only=True)
    saved_at = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = FavoriteRestaurant
        fields = [
            'id',
            'business_name',
            'business_type',
            'address',
            'post_code',
            'province',
            'user_rating',
            'hygiene_score',
            'inspection_date',
            'imageUrl',
            'category',
            'price',
            'distance',
            'description',
            'favorite_id',
            'saved_at',
        ]

    def get_imageUrl(self, obj):
        return None

    def get_category(self, obj):
        return obj.restaurant.business_type

    def get_price(self, obj):
        return '$$'

    def get_distance(self, obj):
        return None

    def get_description(self, obj):
        return f"{obj.restaurant.business_name} hygiene score: {obj.restaurant.hygiene_score:.1f}"


class HygieneAlertSerializer(serializers.ModelSerializer):
    restaurant_id = serializers.IntegerField(source='restaurant.id', read_only=True)
    restaurant_name = serializers.CharField(source='restaurant.business_name', read_only=True)
    category = serializers.CharField(source='restaurant.business_type', read_only=True)
    distance = serializers.SerializerMethodField()
    time_since_alert = serializers.SerializerMethodField()
    score = serializers.SerializerMethodField()

    class Meta:
        model = HygieneAlert
        fields = [
            'id',
            'alert_type',
            'message',
            'restaurant_id',
            'restaurant_name',
            'category',
            'distance_km',
            'distance',
            'time_since_alert',
            'score',
            'is_read',
            'created_at',
        ]

    def get_distance(self, obj):
        return f"{obj.distance_km:.1f} km"

    def get_score(self, obj):
        if obj.score_snapshot is not None:
            return obj.score_snapshot
        return int(round(obj.restaurant.hygiene_score))

    def get_time_since_alert(self, obj):
        delta = timezone.now() - obj.created_at
        seconds = int(delta.total_seconds())
        if seconds < 60:
            return 'just now'
        minutes = seconds // 60
        if minutes < 60:
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        hours = minutes // 60
        if hours < 24:
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        days = hours // 24
        return f"{days} day{'s' if days != 1 else ''} ago"


class UserPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserPreference
        fields = [
            'min_hygiene_score',
            'exclude_flagged',
            'distance_radius_km',
            'cuisine_preferences',
            'updated_at',
        ]
        read_only_fields = ['updated_at']


class NotificationSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationSetting
        fields = [
            'hygiene_alerts_enabled',
            'inspection_warnings_enabled',
            'push_enabled',
            'email_enabled',
            'quiet_hours_enabled',
            'quiet_hours_start',
            'quiet_hours_end',
            'updated_at',
        ]
        read_only_fields = ['updated_at']


class UserProfileSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()
    email = serializers.EmailField(source='user.email', read_only=True)
    metrics = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = ['name', 'email', 'role', 'metrics']

    def get_name(self, obj):
        return obj.full_name or obj.user.get_full_name() or obj.user.username

    def get_metrics(self, obj):
        reviews_written = RestaurantReview.objects.filter(user=obj.user).count()
        reports_submitted = HygieneIssueReport.objects.filter(user=obj.user).count()
        return {
            'reports_submitted': reports_submitted,
            'reviews_written': reviews_written,
        }


class ProfileBundleSerializer(serializers.Serializer):
    profile = UserProfileSerializer(read_only=True)
    preferences = UserPreferenceSerializer(read_only=True)
    notification_settings = NotificationSettingSerializer(read_only=True)


class AccountSettingsSerializer(serializers.Serializer):
    name = serializers.CharField(required=False, allow_blank=True, max_length=255)
    email = serializers.EmailField(required=False)
    current_password = serializers.CharField(required=False, write_only=True)
    new_password = serializers.CharField(required=False, write_only=True, min_length=8)
    role = serializers.ChoiceField(required=False, choices=UserProfile.ROLE_CHOICES)

    def validate(self, attrs):
        user = self.context['request'].user

        if 'new_password' in attrs and not attrs.get('current_password'):
            raise serializers.ValidationError({'current_password': 'Current password is required to set a new password.'})

        if attrs.get('current_password') and not user.check_password(attrs['current_password']):
            raise serializers.ValidationError({'current_password': 'Current password is incorrect.'})

        if 'role' in attrs and not (user.is_staff or user.is_superuser):
            raise serializers.ValidationError({'role': 'Only admin users can change roles.'})

        return attrs

    def update(self, instance, validated_data):
        request_user = self.context['request'].user
        profile = request_user.profile

        if 'email' in validated_data:
            request_user.email = validated_data['email']
            request_user.save(update_fields=['email'])

        if 'name' in validated_data:
            profile.full_name = validated_data['name']

        if 'role' in validated_data:
            profile.role = validated_data['role']

        profile.save(update_fields=['full_name', 'role', 'updated_at'])

        if 'new_password' in validated_data:
            request_user.set_password(validated_data['new_password'])
            request_user.save(update_fields=['password'])

        return request_user


class AccountSettingsReadSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()
    role = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['username', 'email', 'name', 'role']

    def get_name(self, obj):
        if hasattr(obj, 'profile') and obj.profile.full_name:
            return obj.profile.full_name
        return obj.get_full_name() or obj.username

    def get_role(self, obj):
        if hasattr(obj, 'profile'):
            return obj.profile.role
        return UserProfile.ROLE_CUSTOMER


class RestaurantMenuItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = RestaurantMenuItem
        fields = ['id', 'name', 'category', 'description', 'price', 'rating', 'order_count', 'is_available']


class OwnerReviewResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = OwnerReviewResponse
        fields = ['text', 'created_at']


class OwnerReportResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = OwnerReportResponse
        fields = ['text', 'evidence', 'evidence_image', 'created_at']


class RestaurantReviewSerializer(serializers.ModelSerializer):
    reviewer_name = serializers.SerializerMethodField()
    time_since = serializers.SerializerMethodField()

    class Meta:
        model = RestaurantReview
        fields = ['id', 'rating', 'comment', 'reviewer_name', 'created_at', 'time_since', 'is_google_review']
        read_only_fields = ['id', 'reviewer_name', 'created_at', 'time_since', 'is_google_review']

    def get_reviewer_name(self, obj):
        if getattr(obj, 'is_google_review', False):
            return obj.google_reviewer_name or "Google Reviewer"
        if not obj.user:
            return "Anonymous"
        full_name = obj.user.get_full_name().strip()
        if full_name:
            return full_name
        if hasattr(obj.user, 'profile') and obj.user.profile.full_name:
            return obj.user.profile.full_name
        return obj.user.username

    def get_time_since(self, obj):
        delta = timezone.now() - obj.created_at
        seconds = int(delta.total_seconds())
        if seconds < 60:
            return 'just now'
        minutes = seconds // 60
        if minutes < 60:
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        hours = minutes // 60
        if hours < 24:
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        days = hours // 24
        return f"{days} day{'s' if days != 1 else ''} ago"


class RestaurantReviewCreateSerializer(serializers.Serializer):
    rating = serializers.IntegerField(min_value=1, max_value=5)
    comment = serializers.CharField(min_length=5, max_length=600)


class HygieneIssueReportSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source='get_category_display', read_only=True)

    class Meta:
        model = HygieneIssueReport
        fields = ['id', 'category', 'category_display', 'description', 'image_proof', 'status', 'created_at']
        read_only_fields = ['id', 'status', 'created_at', 'category_display', 'image_proof']


class HygieneIssueReportCreateSerializer(serializers.Serializer):
    category = serializers.ChoiceField(choices=HygieneIssueReport.CATEGORY_CHOICES)
    description = serializers.CharField(min_length=8, max_length=800)
    image_proof = serializers.FileField(required=False, allow_null=True)


class RestaurantDetailSerializer(serializers.Serializer):
    restaurant = RestaurantSerializer(read_only=True)
    reviews = RestaurantReviewSerializer(many=True, read_only=True)
    average_rating = serializers.FloatField(read_only=True)
    hygiene_breakdown = serializers.ListField(read_only=True)
    hygiene_history = serializers.ListField(read_only=True)
    menu_items = RestaurantMenuItemSerializer(many=True, read_only=True)
    recent_reports_count = serializers.IntegerField(read_only=True)


class ProfileReviewSerializer(serializers.ModelSerializer):
    restaurant_id = serializers.IntegerField(source='restaurant.id', read_only=True)
    restaurant_name = serializers.CharField(source='restaurant.business_name', read_only=True)
    restaurant_category = serializers.CharField(source='restaurant.business_type', read_only=True)
    time_since = serializers.SerializerMethodField()

    class Meta:
        model = RestaurantReview
        fields = [
            'id',
            'restaurant_id',
            'restaurant_name',
            'restaurant_category',
            'rating',
            'comment',
            'created_at',
            'time_since',
        ]

    def get_time_since(self, obj):
        delta = timezone.now() - obj.created_at
        seconds = int(delta.total_seconds())
        if seconds < 60:
            return 'just now'
        minutes = seconds // 60
        if minutes < 60:
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        hours = minutes // 60
        if hours < 24:
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        days = hours // 24
        return f"{days} day{'s' if days != 1 else ''} ago"


class ProfileReportSerializer(serializers.ModelSerializer):
    restaurant_id = serializers.IntegerField(source='restaurant.id', read_only=True)
    restaurant_name = serializers.CharField(source='restaurant.business_name', read_only=True)
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    time_since = serializers.SerializerMethodField()

    class Meta:
        model = HygieneIssueReport
        fields = [
            'id',
            'restaurant_id',
            'restaurant_name',
            'category',
            'category_display',
            'description',
            'status',
            'status_display',
            'created_at',
            'time_since',
        ]

    def get_time_since(self, obj):
        delta = timezone.now() - obj.created_at
        seconds = int(delta.total_seconds())
        if seconds < 60:
            return 'just now'
        minutes = seconds // 60
        if minutes < 60:
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        hours = minutes // 60
        if hours < 24:
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        days = hours // 24
        return f"{days} day{'s' if days != 1 else ''} ago"
