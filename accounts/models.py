from django.contrib.auth.models import User
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Restaurant(models.Model):
    STATUS_ACTIVE = 'active'
    STATUS_SUSPENDED = 'suspended'
    STATUS_UNDER_REVIEW = 'under_review'
    STATUS_CHOICES = [
        (STATUS_ACTIVE, 'Active'),
        (STATUS_SUSPENDED, 'Suspended'),
        (STATUS_UNDER_REVIEW, 'Under Review'),
    ]

    owner = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL, related_name='owned_restaurants')
    business_name = models.CharField(max_length=255)
    business_type = models.CharField(max_length=100)
    rating_value = models.CharField(max_length=50)
    inspection_date = models.DateField()
    address = models.CharField(max_length=255)
    post_code = models.CharField(max_length=20)
    province = models.CharField(max_length=100)
    user_rating = models.FloatField()
    hygiene_score = models.FloatField()
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    description = models.TextField(blank=True)
    phone = models.CharField(max_length=50, blank=True)
    email = models.EmailField(blank=True)
    price_range = models.CharField(max_length=20, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_ACTIVE)
    admin_notes = models.TextField(blank=True)

    def __str__(self):
        return self.business_name


class HygieneScoreHistory(models.Model):
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='hygiene_score_history')
    score = models.FloatField()
    previous_score = models.FloatField(null=True, blank=True)
    source = models.CharField(max_length=40, default='nlp_update')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"HygieneScoreHistory<{self.restaurant_id}:{self.score}>"

class UserInteraction(models.Model):
    INTERACTION_CHOICES = [
        ('view', 'View'),
        ('like', 'Like'),
        ('favorite', 'Favorite'),
        ('rate', 'Rate'),
    ]
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE)
    interaction_type = models.CharField(max_length=20, choices=INTERACTION_CHOICES)
    rating = models.FloatField(null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} {self.interaction_type} {self.restaurant}"


class UserProfile(models.Model):
    ROLE_CUSTOMER = 'customer'
    ROLE_OWNER = 'owner'
    ROLE_ADMIN = 'admin'
    ROLE_CHOICES = [
        (ROLE_CUSTOMER, 'Customer'),
        (ROLE_OWNER, 'Owner'),
        (ROLE_ADMIN, 'Admin'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    full_name = models.CharField(max_length=255, blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ROLE_CUSTOMER)
    reports_submitted = models.PositiveIntegerField(default=0)
    reviews_written = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Profile<{self.user.username}>"


class UserPreference(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='preferences')
    min_hygiene_score = models.PositiveSmallIntegerField(
        default=75,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
    )
    exclude_flagged = models.BooleanField(default=True)
    distance_radius_km = models.PositiveSmallIntegerField(
        default=5,
        validators=[MinValueValidator(1), MaxValueValidator(100)],
    )
    cuisine_preferences = models.JSONField(default=list, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Preferences<{self.user.username}>"


class NotificationSetting(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='notification_settings')
    hygiene_alerts_enabled = models.BooleanField(default=True)
    inspection_warnings_enabled = models.BooleanField(default=True)
    push_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=False)
    quiet_hours_enabled = models.BooleanField(default=False)
    quiet_hours_start = models.TimeField(null=True, blank=True)
    quiet_hours_end = models.TimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Notifications<{self.user.username}>"


class FavoriteRestaurant(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorite_restaurants')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['user', 'restaurant'], name='unique_user_favorite_restaurant'),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"Favorite<{self.user.username}:{self.restaurant_id}>"


class HygieneAlert(models.Model):
    TYPE_LOW_SCORE = 'low_score'
    TYPE_INSPECTION_WARNING = 'inspection_warning'
    TYPE_THRESHOLD_DROP = 'threshold_drop'
    TYPE_TEMP_ISSUE = 'temperature_issue'
    ALERT_TYPE_CHOICES = [
        (TYPE_LOW_SCORE, 'Low Hygiene Score'),
        (TYPE_INSPECTION_WARNING, 'Inspection Warning'),
        (TYPE_THRESHOLD_DROP, 'Threshold Drop'),
        (TYPE_TEMP_ISSUE, 'Temperature Issue'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='hygiene_alerts')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='hygiene_alerts')
    alert_type = models.CharField(max_length=40, choices=ALERT_TYPE_CHOICES, default=TYPE_LOW_SCORE)
    message = models.CharField(max_length=255)
    distance_km = models.FloatField(default=0.0)
    score_snapshot = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(0), MaxValueValidator(100)],
    )
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Alert<{self.user.username}:{self.restaurant_id}:{self.alert_type}>"


class RestaurantMenuItem(models.Model):
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='menu_items')
    name = models.CharField(max_length=120)
    category = models.CharField(max_length=80, default='Other')
    description = models.CharField(max_length=255, blank=True)
    price = models.DecimalField(max_digits=8, decimal_places=2)
    rating = models.FloatField(default=0.0, validators=[MinValueValidator(0), MaxValueValidator(5)])
    order_count = models.PositiveIntegerField(default=0)
    is_available = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"MenuItem<{self.restaurant_id}:{self.name}>"


class RestaurantReview(models.Model):
    MODERATION_PENDING = 'pending'
    MODERATION_APPROVED = 'approved'
    MODERATION_REMOVED = 'removed'
    MODERATION_DISMISSED = 'dismissed'
    MODERATION_CHOICES = [
        (MODERATION_PENDING, 'Pending'),
        (MODERATION_APPROVED, 'Approved'),
        (MODERATION_REMOVED, 'Removed'),
        (MODERATION_DISMISSED, 'Dismissed'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='restaurant_reviews')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='reviews')
    rating = models.PositiveSmallIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.CharField(max_length=600)
    created_at = models.DateTimeField(auto_now_add=True)
    moderation_status = models.CharField(max_length=20, choices=MODERATION_CHOICES, default=MODERATION_PENDING)
    admin_note = models.TextField(blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Review<{self.user.username}:{self.restaurant_id}:{self.rating}>"


class HygieneIssueReport(models.Model):
    CATEGORY_FOOD_HANDLING = 'food_handling'
    CATEGORY_CLEANLINESS = 'cleanliness'
    CATEGORY_PEST_CONTROL = 'pest_control'
    CATEGORY_OTHER = 'other'
    CATEGORY_CHOICES = [
        (CATEGORY_FOOD_HANDLING, 'Food Handling'),
        (CATEGORY_CLEANLINESS, 'Cleanliness'),
        (CATEGORY_PEST_CONTROL, 'Pest Control'),
        (CATEGORY_OTHER, 'Other'),
    ]

    STATUS_SUBMITTED = 'submitted'
    STATUS_REVIEWED = 'reviewed'
    STATUS_RESOLVED = 'resolved'
    STATUS_CHOICES = [
        (STATUS_SUBMITTED, 'Submitted'),
        (STATUS_REVIEWED, 'Reviewed'),
        (STATUS_RESOLVED, 'Resolved'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='hygiene_issue_reports')
    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='issue_reports')
    category = models.CharField(max_length=40, choices=CATEGORY_CHOICES)
    description = models.CharField(max_length=800)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_SUBMITTED)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"IssueReport<{self.user.username}:{self.restaurant_id}:{self.category}>"


class OwnerReviewResponse(models.Model):
    review = models.OneToOneField(RestaurantReview, on_delete=models.CASCADE, related_name='owner_response')
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"OwnerReviewResponse<{self.review_id}>"


class OwnerReportResponse(models.Model):
    report = models.OneToOneField(HygieneIssueReport, on_delete=models.CASCADE, related_name='owner_response')
    text = models.TextField()
    evidence = models.FileField(upload_to='evidence_documents/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"OwnerReportResponse<{self.report_id}>"



class OwnerReviewFlag(models.Model):
    FLAG_HELPFUL = 'helpful'
    FLAG_REPORT = 'report'
    FLAG_CHOICES = [
        (FLAG_HELPFUL, 'Helpful'),
        (FLAG_REPORT, 'Report'),
    ]

    review = models.ForeignKey(RestaurantReview, on_delete=models.CASCADE, related_name='owner_flags')
    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    flag_type = models.CharField(max_length=20, choices=FLAG_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        constraints = [
            models.UniqueConstraint(fields=['review', 'owner', 'flag_type'], name='unique_owner_review_flag'),
        ]

    def __str__(self):
        return f"OwnerReviewFlag<{self.review_id}:{self.flag_type}>"


class InspectionRequest(models.Model):
    STATUS_PENDING = 'pending'
    STATUS_APPROVED = 'approved'
    STATUS_DENIED = 'denied'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Pending'),
        (STATUS_APPROVED, 'Approved'),
        (STATUS_DENIED, 'Denied'),
    ]

    restaurant = models.ForeignKey(Restaurant, on_delete=models.CASCADE, related_name='inspection_requests')
    requested_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='inspection_requests')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"InspectionRequest<{self.restaurant_id}:{self.status}>"

# Create your models here.
