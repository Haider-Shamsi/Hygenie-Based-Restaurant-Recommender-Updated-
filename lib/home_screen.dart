import 'package:flutter/material.dart';
import 'models/restaurant.dart';
import 'widgets/restaurant_card.dart';
import 'widgets/custom_filter_chip.dart';
import 'restaurant_detail_screen.dart';
import 'map_screen.dart'; 
import 'alert_screen.dart'; 
import 'favorites_screen.dart';
import 'profile_screen.dart'; 

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  int _selectedIndex = 0;

  // Handles navigation switching
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We pass _onItemTapped to HomeTabContent so it can trigger tab switches
    final List<Widget> _screens = [
      HomeTabContent(onNavigate: _onItemTapped), 
      const MapScreen(),
      const AlertsScreen(),
      const FavoritesScreen(),
      const ProfileScreen(userRole: 'customer'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF00C48C),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: "Alerts"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

class HomeTabContent extends StatefulWidget {
  final Function(int) onNavigate; // Callback to switch tabs
  const HomeTabContent({super.key, required this.onNavigate});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  String _selectedFilter = 'Highest Hygiene';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _filters = ['Highest Hygiene', 'Nearby', 'Trending', 'Top Rated'];

  final List<Restaurant> _restaurants = [
    const Restaurant(
      id: '1',
      name: "The Green Table",
      category: "Modern European",
      distance: "1.2 km",
      price: "\$\$",
      rating: 95,
      imageUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&q=80",
    ),
    const Restaurant(
      id: '2',
      name: "Sakura Sushi Bar",
      category: "Japanese",
      distance: "2.5 km",
      price: "\$\$\$",
      rating: 92,
      imageUrl: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=500&q=80",
    ),
    const Restaurant(
      id: '3',
      name: "Bella Italia",
      category: "Italian",
      distance: "0.8 km",
      price: "\$\$",
      rating: 89,
      imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80",
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchSection(),
            const SizedBox(height: 15),
            _buildFilterChips(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Main Restaurant List
                  ..._restaurants.map((restaurant) => RestaurantCard(
                    restaurant: restaurant,
                    onTap: () {
                      // Navigate to Detail Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant)),
                      );
                    },
                  )),
                  
                  const SizedBox(height: 10),
                  const Text("Recommended for You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // Reusing the list for recommendation section
                  ..._restaurants.reversed.map((restaurant) => RestaurantCard(
                    restaurant: restaurant,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant)),
                      );
                    },
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. CLICKABLE LOCATION -> Switches to Map Tab (Index 1)
          InkWell(
            onTap: () => widget.onNavigate(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.location_on_outlined, color: Color(0xFF00C48C), size: 18),
                    SizedBox(width: 4),
                    Text("Location", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Text(
                  "Lahore, Pakistan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          // 2. CLICKABLE PROFILE -> Switches to Profile Tab (Index 4)
          InkWell(
            onTap: () => widget.onNavigate(4),
            borderRadius: BorderRadius.circular(20),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFD1FAE5),
              child: Icon(Icons.person, color: Color(0xFF00C48C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Find the Cleanest Restaurants Near You",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search",
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildFilterIconButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterIconButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.tune, color: Colors.grey),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filterName = _filters[index];
          return CustomFilterChip(
            label: filterName,
            isSelected: _selectedFilter == filterName,
            onTap: () => setState(() => _selectedFilter = filterName),
          );
        },
      ),
    );
  }
}