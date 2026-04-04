class Restaurant {
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
}
