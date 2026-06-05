from django.conf import settings
from rest_framework.authentication import TokenAuthentication
from rest_framework.authtoken.models import Token
from rest_framework import exceptions


class DevelopmentTokenAuthentication(TokenAuthentication):
    """
    Development helper authentication class.

    Behavior:
    - First attempts the standard TokenAuthentication (Authorization header).
    - If that fails and Django DEBUG is True, attempts to find a token in
      `auth_token` query parameter or `auth_token` cookie and authenticate.

    This is intended for local development convenience only. Do NOT enable
    in production.
    """

    def authenticate(self, request):
        # Try standard header-based token auth first
        result = super().authenticate(request)
        if result is not None:
            return result

        # Fallbacks only allowed in DEBUG mode
        if not getattr(settings, 'DEBUG', False):
            return None

        token_key = None
        # Check query param first (e.g. ?auth_token=...)
        try:
            token_key = request.query_params.get('auth_token')
        except Exception:
            token_key = request.GET.get('auth_token') if hasattr(request, 'GET') else None

        # Then check cookie
        if not token_key:
            token_key = request.COOKIES.get('auth_token')

        if not token_key:
            return None

        try:
            token = Token.objects.select_related('user').get(key=token_key)
        except Token.DoesNotExist:
            raise exceptions.AuthenticationFailed('Invalid token.')

        return (token.user, token)
