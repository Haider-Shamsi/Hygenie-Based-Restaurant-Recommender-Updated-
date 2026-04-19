class Restaurant {
<<<<<<< HEAD
  final String id;
  final String name;
  final String category;
  final String distance;
  final String price;
  final int rating;
  final String imageUrl;
  final String address;
  final String description;
  
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      distance: json['distance'],
      price: json['price'],
      rating: json['rating'],
      imageUrl: json['imageUrl'],
      address: json['address'] ?? '123 Main Street, Lahore',
      description: json['description'] ?? 'A fine dining experience with exceptional hygiene standards.',
    );
  }
  
  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.distance,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.address = '123 Main Street, Lahore',
    this.description = 'A fine dining experience with exceptional hygiene standards.',
  });
=======
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
>>>>>>> b6ab235 (Initial project commit)
}
