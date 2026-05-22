from django.urls import path
from . import views
from .views import AlertPreferenceView
from .views import FavoriteRestaurantDeleteView
from .views import FavoriteRestaurantListCreateView
from .views import HygieneAlertListView
from .views import HygieneAlertMarkReadView
from .views import HygieneIssueReportListCreateView
from .views import ProfileAccountSettingsView
from .views import ProfileNotificationSettingsView
from .views import ProfilePreferencesView
from .views import ProfileReportListView
from .views import ProfileReviewDeleteView
from .views import ProfileReviewListView
from .views import ProfileView
from .views import RecommendedRestaurantsView
from .views import RestaurantDetailDataView
from .views import RestaurantMenuListView
from .views import RestaurantReviewListCreateView
from .views import UserInteractionCreateView
from .views import UserInteractionListView
from .views import OwnerAnalyticsView
from .views import OwnerDashboardView
from .views import OwnerHygieneReportResponseView
from .views import OwnerHygieneReportsView
from .views import OwnerRestaurantMenuItemView
from .views import OwnerRestaurantMenuView
from .views import OwnerRestaurantProfileView
from .views import OwnerReviewResponseView
from .views import OwnerReviewsView

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
    path('alerts/', HygieneAlertListView.as_view(), name='hygiene-alerts-list'),
    path('alerts/<int:alert_id>/read/', HygieneAlertMarkReadView.as_view(), name='hygiene-alert-read'),
    path('alerts/preferences/', AlertPreferenceView.as_view(), name='hygiene-alert-preferences'),
    path('favorites/', FavoriteRestaurantListCreateView.as_view(), name='favorites-list-create'),
    path('favorites/<int:restaurant_id>/', FavoriteRestaurantDeleteView.as_view(), name='favorites-delete'),
    path('restaurants/<int:restaurant_id>/detail/', RestaurantDetailDataView.as_view(), name='restaurant-detail-data'),
    path('restaurants/<int:restaurant_id>/reviews/', RestaurantReviewListCreateView.as_view(), name='restaurant-reviews'),
    path('restaurants/<int:restaurant_id>/reports/', HygieneIssueReportListCreateView.as_view(), name='restaurant-reports'),
    path('restaurants/<int:restaurant_id>/menu/', RestaurantMenuListView.as_view(), name='restaurant-menu'),
    path('profile/', ProfileView.as_view(), name='profile-detail'),
    path('profile/preferences/', ProfilePreferencesView.as_view(), name='profile-preferences'),
    path('profile/notification-settings/', ProfileNotificationSettingsView.as_view(), name='profile-notification-settings'),
    path('profile/account-settings/', ProfileAccountSettingsView.as_view(), name='profile-account-settings'),
    path('profile/reviews/', ProfileReviewListView.as_view(), name='profile-reviews'),
    path('profile/reviews/<int:review_id>/', ProfileReviewDeleteView.as_view(), name='profile-review-delete'),
    path('profile/reports/', ProfileReportListView.as_view(), name='profile-reports'),
    path('owner/dashboard/', OwnerDashboardView.as_view(), name='owner-dashboard'),
    path('owner/reviews/', OwnerReviewsView.as_view(), name='owner-reviews'),
    path('owner/reviews/<int:review_id>/response/', OwnerReviewResponseView.as_view(), name='owner-review-response'),
    path('owner/reports/', OwnerHygieneReportsView.as_view(), name='owner-reports'),
    path('owner/reports/<int:report_id>/response/', OwnerHygieneReportResponseView.as_view(), name='owner-report-response'),
    path('owner/analytics/', OwnerAnalyticsView.as_view(), name='owner-analytics'),
    path('owner/restaurant/', OwnerRestaurantProfileView.as_view(), name='owner-restaurant'),
    path('owner/menu/', OwnerRestaurantMenuView.as_view(), name='owner-menu'),
    path('owner/menu/<int:item_id>/', OwnerRestaurantMenuItemView.as_view(), name='owner-menu-item'),
]
