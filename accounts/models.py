from django.db import models
from django.contrib.auth.models import User
class Restaurant(models.Model):
	business_name = models.CharField(max_length=255)
	business_type = models.CharField(max_length=100)
	rating_value = models.CharField(max_length=50)
	inspection_date = models.DateField()
	address = models.CharField(max_length=255)
	post_code = models.CharField(max_length=20)
	province = models.CharField(max_length=100)
	user_rating = models.FloatField()
	hygiene_score = models.FloatField()

	def __str__(self):
		return self.business_name

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

# Create your models here.
