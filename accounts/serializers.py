from rest_framework import serializers
from .models import Restaurant
from .models import UserInteraction
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