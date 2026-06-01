class DishRecommendation {
  final int id;
  final String name;
  final String category;
  final String description;
  final String price;
  final double rating;
  final int restaurantId;
  final String restaurantName;
  final String restaurantType;
  final String restaurantAddress;
  final String restaurantProvince;
  final double restaurantHygieneScore;

  DishRecommendation({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantType,
    required this.restaurantAddress,
    required this.restaurantProvince,
    required this.restaurantHygieneScore,
  });

  factory DishRecommendation.fromJson(Map<String, dynamic> json) {
    final restaurant = (json['restaurant'] as Map<String, dynamic>? ?? <String, dynamic>{});
    return DishRecommendation(
      id: (json['id'] as num).toInt(),
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      restaurantId: (restaurant['id'] as num?)?.toInt() ?? 0,
      restaurantName: restaurant['business_name'] ?? '',
      restaurantType: restaurant['business_type'] ?? '',
      restaurantAddress: restaurant['address'] ?? '',
      restaurantProvince: restaurant['province'] ?? '',
      restaurantHygieneScore: (restaurant['hygiene_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
