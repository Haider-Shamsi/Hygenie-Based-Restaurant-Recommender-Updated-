from rest_framework import serializers
from django.contrib.auth.models import User

class GoogleSignInSerializer(serializers.Serializer):
    token = serializers.CharField()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']
