class Restaurant {
  // Backend fields
  final int id;
  final String businessName;
  final String businessType;
  final String address;
  final String postCode;
  final String province;
  final double userRating;
  final double hygieneScore;
  final String? inspectionDate;

  // UI fields (optional)
  final String? imageUrl;
  final String? category;
  final String? price;
  final String? distance;
  final String? description;

  Restaurant({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.address,
    required this.postCode,
    required this.province,
    required this.userRating,
    required this.hygieneScore,
    this.inspectionDate,
    this.imageUrl,
    this.category,
    this.price,
    this.distance,
    this.description,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      businessName: json['business_name'],
      businessType: json['business_type'],
      address: json['address'],
      postCode: json['post_code'],
      province: json['province'],
      userRating: (json['user_rating'] as num).toDouble(),
      hygieneScore: (json['hygiene_score'] as num).toDouble(),
      inspectionDate: json['inspection_date'],
      // UI fields: try to get from backend, else null
      imageUrl: json['imageUrl'],
      category: json['category'] ?? json['business_type'],
      price: json['price'],
      distance: json['distance'],
      description: json['description'],
    );
  }
}
