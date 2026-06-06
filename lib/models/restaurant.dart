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
  final double? latitude;
  final double? longitude;

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
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.category,
    this.price,
    this.distance,
    this.description,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final int restaurantId = json['id'];
    return Restaurant(
      id: restaurantId,
      businessName: json['business_name'],
      businessType: json['business_type'],
      address: json['address'],
      postCode: json['post_code'],
      province: json['province'],
      userRating: (json['user_rating'] as num).toDouble(),
      hygieneScore: (json['hygiene_score'] as num).toDouble(),
      inspectionDate: json['inspection_date'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      // UI fields: try to get from backend, else use a high quality stock fallback
      imageUrl: json['imageUrl'] ?? _getDummyImage(restaurantId),
      category: json['category'] ?? json['business_type'],
      price: json['price'],
      distance: json['distance'],
      description: json['description'],
    );
  }

  static String _getDummyImage(int id) {
    final images = [
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=600&q=80', // Bistro interior
      'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=600&q=80', // Elegant plating
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80', // Kitchen bar
      'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=600&q=80', // Cosy restaurant
      'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=600&q=80', // Platter spread
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=600&q=80', // Fine dining
      'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=600&q=80', // Korean dining
      'https://images.unsplash.com/photo-1521017432531-fbd92d768814?auto=format&fit=crop&w=600&q=80', // Cafe table
      'https://images.unsplash.com/photo-1502301197179-65228ab57f78?auto=format&fit=crop&w=600&q=80', // Dinner hall
      'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=600&q=80', // Terrace seating
      'https://images.unsplash.com/photo-1560624052-449f5ddf0c31?auto=format&fit=crop&w=600&q=80', // Front facade
      'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?auto=format&fit=crop&w=600&q=80', // Salad bowl
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=600&q=80', // Steak platter
      'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=600&q=80', // Pasta dish
      'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?auto=format&fit=crop&w=600&q=80', // Burger combo
      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?auto=format&fit=crop&w=600&q=80', // Pizza
      'https://images.unsplash.com/photo-1565958011703-44f9829ba187?auto=format&fit=crop&w=600&q=80', // Cake slice
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=600&q=80', // Fresh salad
      'https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=600&q=80', // Desserts case
      'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=600&q=80', // Pizza close up
      'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=600&q=80', // Burger
      'https://loremflickr.com/600/400/restaurant,food?random=100', // Food layout
      'https://loremflickr.com/600/400/restaurant,food?random=101', // Fish dish
      'https://loremflickr.com/600/400/restaurant,food?random=102', // Sandwich
      'https://images.unsplash.com/photo-1543362906-acfc16c67564?auto=format&fit=crop&w=600&q=80', // Dim sum
      'https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=600&q=80', // Sushi
      'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=600&q=80', // Pancakes
      'https://loremflickr.com/600/400/restaurant,food?random=103', // Salad
      'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?auto=format&fit=crop&w=600&q=80', // Tacos
      'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?auto=format&fit=crop&w=600&q=80', // Coffee shop
      'https://images.unsplash.com/photo-1554679665-f5537f187268?auto=format&fit=crop&w=600&q=80', // Cafe facade
      'https://images.unsplash.com/photo-1551632436-cbf8dd35adfa?auto=format&fit=crop&w=600&q=80', // Fast food
      'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=600&q=80', // Bowl
      'https://images.unsplash.com/photo-1481931098730-318b6f776db0?auto=format&fit=crop&w=600&q=80', // Dinner party
      'https://loremflickr.com/600/400/restaurant,food?random=104', // Pasta
      'https://images.unsplash.com/photo-1564834724105-918b73d1b9e0?auto=format&fit=crop&w=600&q=80', // Toast
      'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=600&q=80', // Pizza slice
      'https://images.unsplash.com/photo-1457460866886-40ef8d4b42a0?auto=format&fit=crop&w=600&q=80', // Pastries
      'https://loremflickr.com/600/400/restaurant,food?random=105', // Cafe inside
      'https://loremflickr.com/600/400/restaurant,food?random=106', // Table setting
      'https://loremflickr.com/600/400/restaurant,food?random=107', // Meat dish
      'https://loremflickr.com/600/400/restaurant,food?random=108', // Coffee cup
      'https://loremflickr.com/600/400/restaurant,food?random=109', // Breakfast
      'https://images.unsplash.com/photo-1520201163981-8cc95007dd2a?auto=format&fit=crop&w=600&q=80', // Noodles
      'https://loremflickr.com/600/400/restaurant,food?random=110', // Dessert
      'https://loremflickr.com/600/400/restaurant,food?random=111', // Cafe exterior
      'https://loremflickr.com/600/400/restaurant,food?random=112', // Fancy dish
      'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?auto=format&fit=crop&w=600&q=80', // Burger and fries
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?auto=format&fit=crop&w=600&q=80', // Indian food
      'https://loremflickr.com/600/400/restaurant,food?random=113', // Sushi roll
    ];
    return images[id % images.length];
  }
}

