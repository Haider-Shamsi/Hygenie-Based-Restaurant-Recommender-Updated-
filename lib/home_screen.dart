import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'models/restaurant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeTabContent(onNavigate: _onItemTapped),
      const MapScreen(),
      const AlertsScreen(),
      FavoritesScreen(), // Removed const
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
      // String? _userCity;
      // bool _isDetectingCity = true;

  String _selectedFilter = 'Recommended for You';
  final TextEditingController _searchController = TextEditingController();
  // Filter dialog controllers
  double? _minHygieneScore;
  String? _cuisineType;
  double? _distanceKm;
  final List<String> _filters = [
    'Recommended for You',
    'Highest Hygiene',
    'Nearby',
    'Trending',
    'Top Rated',
  ];

  List<Restaurant> _restaurants = [];
  List<Restaurant> _recommendedRestaurants = [];
  List<Restaurant> _nearbyRestaurants = [];
  bool _isLoading = true;
  bool _isLoadingRecommended = false;
  bool _isLoadingNearby = false;
  String? _error;
  String? _recommendedError;
  String? _nearbyError;
  String? _userCity;


  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
    _fetchRecommendedRestaurants();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchRecommendedRestaurants() async {
    setState(() {
      _isLoadingRecommended = true;
      _recommendedError = null;
    });
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _recommendedRestaurants = [];
          _recommendedError = 'Sign in to see personalized recommendations.';
          _isLoadingRecommended = false;
        });
        return;
      }

      final headers = <String, String>{
        'Authorization': 'Token $token',
      };
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/accounts/recommendations/item-based/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _recommendedRestaurants = data.map((json) => Restaurant.fromJson(json)).toList();
          _isLoadingRecommended = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() {
          _recommendedRestaurants = [];
          _recommendedError = 'Session expired. Please sign in again.';
          _isLoadingRecommended = false;
        });
      } else {
        setState(() {
          _recommendedError = 'Failed to load recommendations';
          _isLoadingRecommended = false;
        });
      }
    } catch (e) {
      setState(() {
        _recommendedError = 'Error: $e';
        _isLoadingRecommended = false;
      });
    }
  }

  Future<String?> _getCurrentCity() async {
    if (_userCity != null && _userCity!.trim().isNotEmpty) return _userCity;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    final city = kIsWeb
      ? await _reverseGeocodeCityWeb(position.latitude, position.longitude)
      : await _reverseGeocodeCityNative(position.latitude, position.longitude);
    if (city.isEmpty) return null;

    setState(() {
      _userCity = city;
    });
    return city;
  }

  Future<String> _reverseGeocodeCityWeb(double latitude, double longitude) async {
    // geocoding package does not provide a web implementation.
    // Use a simple reverse-geocoding HTTP API (CORS-friendly) to resolve locality.
    final url = Uri.parse(
      'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=en',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) return '';

    final body = json.decode(resp.body);
    if (body is! Map) return '';

    final city = (body['city'] ?? body['locality'] ?? body['principalSubdivision'] ?? '').toString().trim();
    if (city.isEmpty) return '';

    // Normalize e.g. "Lahore District" -> "Lahore" (best-effort).
    return city.split(',').first.trim();
  }

  Future<String> _reverseGeocodeCityNative(double latitude, double longitude) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return '';
    final p = placemarks.first;
    return (p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? '').trim();
  }

  Future<void> _fetchNearbyRestaurants() async {
    setState(() {
      _isLoadingNearby = true;
      _nearbyError = null;
    });

    try {
      final city = await _getCurrentCity();
      if (city == null || city.isEmpty) {
        setState(() {
          _nearbyRestaurants = [];
          _nearbyError = 'Unable to detect your city. Please allow location access.';
          _isLoadingNearby = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/accounts/recommendations/city/?city=${Uri.encodeComponent(city)}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _nearbyRestaurants = data.map((json) => Restaurant.fromJson(json)).toList();
          _isLoadingNearby = false;
        });
      } else {
        setState(() {
          _nearbyRestaurants = [];
          _nearbyError = 'Failed to load nearby restaurants';
          _isLoadingNearby = false;
        });
      }
    } catch (e) {
      setState(() {
        _nearbyRestaurants = [];
        _nearbyError = 'Unable to load nearby restaurants.';
        _isLoadingNearby = false;
      });
    }
  }

  Future<void> _recordInteraction(int restaurantId, String interactionType) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) return;

      await http.post(
        Uri.parse('http://127.0.0.1:8000/api/accounts/user-interactions/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'restaurant': restaurantId,
          'interaction_type': interactionType,
        }),
      );
    } catch (_) {
      // Ignore interaction logging failures.
    }
  }


  // City detection removed for web compatibility

  Future<void> _fetchRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/accounts/recommendations/hygiene/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _restaurants = data.map((json) => Restaurant.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load restaurants';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: \$e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Filtering and Sorting Logic ---
    List<Restaurant> filteredRestaurants = _restaurants;

    // Search by businessName
    final searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isNotEmpty) {
      filteredRestaurants = filteredRestaurants.where((r) => r.businessName.toLowerCase().contains(searchText)).toList();
    }

    // Apply filter dialog values
    if (_minHygieneScore != null) {
      filteredRestaurants = filteredRestaurants.where((r) => r.hygieneScore >= _minHygieneScore!).toList();
    }
    if (_cuisineType != null && _cuisineType!.trim().isNotEmpty) {
      final cuisineList = _cuisineType!.toLowerCase().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (cuisineList.isNotEmpty) {
        filteredRestaurants = filteredRestaurants.where((r) {
          final cat = (r.category ?? '').toLowerCase();
          return cuisineList.any((c) => cat.contains(c));
        }).toList();
      }
    }
    // Distance filter is a placeholder (requires coordinates)

    // Apply selected filter
    if (_selectedFilter == 'Highest Hygiene') {
      filteredRestaurants.sort((a, b) => b.hygieneScore.compareTo(a.hygieneScore));
    } else if (_selectedFilter == 'Nearby') {
      // Nearby is handled via _nearbyRestaurants fetched from backend.
    } else if (_selectedFilter == 'Trending') {
      // Trending logic removed for now
      // You can add trending logic here later
    } else if (_selectedFilter == 'Top Rated') {
      filteredRestaurants.sort((a, b) => b.userRating.compareTo(a.userRating));
    }

    // Defensive: avoid nulls and empty
    final mainList = filteredRestaurants.take(5).toList();

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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _selectedFilter == 'Recommended for You'
                          ? (_isLoadingRecommended
                              ? const Center(child: CircularProgressIndicator())
                              : _recommendedError != null
                                  ? Center(child: Text(_recommendedError!))
                                  : _recommendedRestaurants.isEmpty
                                      ? const Center(child: Text('No recommendations found.'))
                                      : ListView(
                                          padding: const EdgeInsets.all(20),
                                          children: [
                                            ..._recommendedRestaurants.map((restaurant) => RestaurantCard(
                                                  restaurant: restaurant,
                                                  onTap: () {
                                                    _recordInteraction(restaurant.id, 'view');
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant)),
                                                    );
                                                  },
                                                )),
                                          ],
                                        ))
                          : _selectedFilter == 'Nearby'
                              ? (_isLoadingNearby
                                  ? const Center(child: CircularProgressIndicator())
                                  : _nearbyError != null
                                      ? Center(child: Text(_nearbyError!))
                                      : _nearbyRestaurants.isEmpty
                                          ? const Center(child: Text('No nearby restaurants found.'))
                                          : ListView(
                                              padding: const EdgeInsets.all(20),
                                              children: [
                                                ..._nearbyRestaurants.map((restaurant) => RestaurantCard(
                                                      restaurant: restaurant,
                                                      onTap: () {
                                                        _recordInteraction(restaurant.id, 'view');
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant)),
                                                        );
                                                      },
                                                    )),
                                              ],
                                            ))
                              : (mainList.isEmpty
                                  ? const Center(child: Text('No restaurants found.'))
                                  : ListView(
                                      padding: const EdgeInsets.all(20),
                                      children: [
                                        ...mainList.map((restaurant) => RestaurantCard(
                                              restaurant: restaurant,
                                              onTap: () {
                                                _recordInteraction(restaurant.id, 'view');
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => RestaurantDetailScreen(restaurant: restaurant)),
                                                );
                                              },
                                            )),
                                      ],
                                    )),
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
                Text(
                  _userCity == null ? 'Detecting locationâ€¦' : '${_userCity!}, Pakistan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    onChanged: (value) {
                      setState(() {});
                    },
                    onSubmitted: (value) {
                      setState(() {});
                    },
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
    return InkWell(
      onTap: () => _showFilterDialog(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.tune, color: Colors.grey),
      ),
    );
  }

  void _showFilterDialog() {
    final hygieneController = TextEditingController(text: _minHygieneScore?.toString() ?? '');
    final cuisineController = TextEditingController(text: _cuisineType ?? '');
    final distanceController = TextEditingController(text: _distanceKm?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: hygieneController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Hygiene Score',
                    hintText: 'e.g. 70',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cuisineController,
                  decoration: const InputDecoration(
                    labelText: 'Cuisine Type',
                    hintText: 'e.g. Italian, Fast Food',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: distanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Distance Radius (km)',
                    hintText: 'e.g. 5',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final hygiene = double.tryParse(hygieneController.text);
                  _minHygieneScore = (hygiene != null && hygiene >= 0 && hygiene <= 100) ? hygiene : null;
                  final cuisine = cuisineController.text.trim();
                  _cuisineType = cuisine.isNotEmpty ? cuisine : null;
                  final dist = double.tryParse(distanceController.text);
                  _distanceKm = (dist != null && dist > 0) ? dist : null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply Filters'),
            ),
          ],
        );
      },
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
            onTap: () {
              setState(() => _selectedFilter = filterName);
              if (filterName == 'Recommended for You') {
                _fetchRecommendedRestaurants();
              } else if (filterName == 'Nearby') {
                _fetchNearbyRestaurants();
              }
            },
          );
        },
      ),
    );
  }
}
