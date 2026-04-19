from django.urls import path
from . import views
from .views import UserInteractionCreateView, UserInteractionListView, RecommendedRestaurantsView

urlpatterns = [
    path('signup/', views.SignUpView.as_view(), name='signup'),
    path('login/', views.LoginView.as_view(), name='login'),
    path('logout/', views.LogoutView.as_view(), name='logout'),
    path('verify-otp/', views.verify_otp, name='verify_otp'),
    path('recommendations/top/', views.top_restaurants, name='top_restaurants'),
    path('recommendations/hygiene/', views.restaurants_by_hygiene, name='restaurants_by_hygiene'),
    path('recommendations/city/', views.restaurants_by_city, name='restaurants_by_city'),
    path('google-signin/', views.GoogleSignInView.as_view(), name='google_signin'),
    path('user-interactions/', UserInteractionCreateView.as_view(), name='user-interaction-create'),
    path('user-interactions/history/', UserInteractionListView.as_view(), name='user-interaction-list'),
    path('recommendations/item-based/', RecommendedRestaurantsView.as_view(), name='item-based-recommendations'),
]
