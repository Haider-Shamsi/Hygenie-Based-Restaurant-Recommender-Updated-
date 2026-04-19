import 'package:flutter/material.dart';
import 'models/restaurant.dart';
import 'widgets/restaurant_card.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({super.key});

  // Mock data for saved restaurants (updated for new model)
  final List<Restaurant> _savedRestaurants = [
    Restaurant(
      id: 1,
      businessName: "The Green Table",
      businessType: "Modern European",
      address: "123 Main Street, Lahore",
      postCode: "54000",
      province: "Lahore",
      userRating: 4.8,
      hygieneScore: 95.0,
      inspectionDate: "2024-01-01",
      imageUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&q=80",
      category: "Modern European",
      distance: "1.2 km",
      price: "\$\$",
      description: "A fine dining experience with exceptional hygiene standards.",
    ),
    Restaurant(
      id: 2,
      businessName: "Sakura Sushi Bar",
      businessType: "Japanese",
      address: "456 Sushi Ave, Lahore",
      postCode: "54001",
      province: "Lahore",
      userRating: 4.6,
      hygieneScore: 92.0,
      inspectionDate: "2024-01-02",
      imageUrl: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=500&q=80",
      category: "Japanese",
      distance: "2.5 km",
      price: "\$\$\$",
      description: "Fresh sushi and a clean environment.",
    ),
    Restaurant(
      id: 3,
      businessName: "Bella Italia",
      businessType: "Italian",
      address: "789 Pasta Rd, Lahore",
      postCode: "54002",
      province: "Lahore",
      userRating: 4.3,
      hygieneScore: 88.0,
      inspectionDate: "2024-01-03",
      imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80",
      category: "Italian",
      distance: "0.8 km",
      price: "\$\$",
      description: "Authentic Italian cuisine with top hygiene.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF323F4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Favorites",
          style: TextStyle(color: Color(0xFF323F4B), fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Saved Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_savedRestaurants.length} saved",
                  style: const TextStyle(fontSize: 16, color: Color(0xFF323F4B)),
                ),
                const Text(
                  "restaurants",
                  style: TextStyle(fontSize: 16, color: Color(0xFF323F4B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Scrollable List of Favorites
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _savedRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = _savedRestaurants[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Stack(
                    children: [
                      // Reusing your existing RestaurantCard widget
                      RestaurantCard(
                        restaurant: restaurant,
                        onTap: () {},
                      ),
                      // Trash Icon
                      Positioned(
                        bottom: 15,
                        right: 15,
                        child: InkWell(
                          onTap: () => debugPrint("Remove ${restaurant.businessName}"),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
