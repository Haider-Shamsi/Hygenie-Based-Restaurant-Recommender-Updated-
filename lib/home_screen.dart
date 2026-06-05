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
import 'config.dart';
import 'models/dish_recommendation.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  int _selectedIndex = 0;
  final GlobalKey _homeTabKey = GlobalKey();
  final GlobalKey _favoritesScreenKey = GlobalKey();

  void _refreshFavoritesTab() {
    final state = _favoritesScreenKey.currentState;
    if (state != null) {
      (state as dynamic).refreshFavorites();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      final state = _homeTabKey.currentState;
      if (state != null) {
        (state as dynamic).refreshUserPreferences();
      }
    }
    if (index == 3) {
      _refreshFavoritesTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeTabContent(
        key: _homeTabKey,
        onNavigate: _onItemTapped,
        onFavoritesChanged: _refreshFavoritesTab,
      ),
      const MapScreen(),
      const AlertsScreen(),
      FavoritesScreen(key: _favoritesScreenKey),
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
  final VoidCallback? onFavoritesChanged;

  const HomeTabContent({
    super.key,
    required this.onNavigate,
    this.onFavoritesChanged,
  });

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
      // String? _userCity;
      // bool _isDetectingCity = true;

  String _selectedFilter = 'Restaurant Recommendations';
  final TextEditingController _searchController = TextEditingController();
  // Filter dialog controllers
  double? _minHygieneScore;
  String? _cuisineType;
  double? _distanceKm;
  bool _filtersApplied = false;
  final List<String> _filters = [
    'Restaurant Recommendations',
    'Dish Recommendations',
    'Highest Hygiene',
    'Nearby',
    'Trending',
    'Top Rated',
  ];

  List<Restaurant> _restaurants = [];
  List<Restaurant> _recommendedRestaurants = [];
  List<DishRecommendation> _recommendedDishes = [];
  List<Restaurant> _nearbyRestaurants = [];
  List<Restaurant> _trendingRestaurants = [];
  List<Restaurant> _topRatedRestaurants = [];
  final Set<int> _favoriteIds = <int>{};
  final Set<int> _favoriteBusyIds = <int>{};
  bool _isLoading = true;
  bool _isLoadingRecommended = false;
  bool _isLoadingDishes = false;
  bool _isLoadingNearby = false;
  bool _isLoadingTrending = false;
  bool _isLoadingTopRated = false;
  String? _error;
  String? _recommendedError;
  String? _recommendedDishesError;
  String? _nearbyError;
  String? _trendingError;
  String? _topRatedError;
  String? _userCity;


  @override
  void initState() {
    super.initState();
    _fetchUserPreferences();
    _fetchRestaurants();
    _fetchRecommendedRestaurants();
    _fetchRecommendedDishes();
    _fetchTopRatedRestaurants();
    _fetchFavoriteIds();
  }

  Future<void> refreshUserPreferences() => _fetchUserPreferences();

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchRecommendedRestaurants() async {
    if (!mounted) return;
    setState(() {
      _isLoadingRecommended = true;
      _recommendedError = null;
    });
    try {
      final token = await _getAuthToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        if (!mounted) return;
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
        Uri.parse('${Config.baseUrl}/api/accounts/recommendations/user-based/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _recommendedRestaurants = data.map((json) => Restaurant.fromJson(json)).toList();
          _isLoadingRecommended = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        if (!mounted) return;
        setState(() {
          _recommendedRestaurants = [];
          _recommendedError = 'Session expired. Please sign in again.';
          _isLoadingRecommended = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _recommendedError = 'Failed to load recommendations';
          _isLoadingRecommended = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recommendedError = 'Error: $e';
        _isLoadingRecommended = false;
      });
    }
  }

  Future<void> _fetchRecommendedDishes() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDishes = true;
      _recommendedDishesError = null;
    });
    try {
      final token = await _getAuthToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _recommendedDishes = [];
          _recommendedDishesError = 'Sign in to see dish recommendations.';
          _isLoadingDishes = false;
        });
        return;
      }

      final headers = <String, String>{
        'Authorization': 'Token $token',
      };
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/recommendations/dishes/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _recommendedDishes = data.map((json) => DishRecommendation.fromJson(json)).toList();
          _isLoadingDishes = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        if (!mounted) return;
        setState(() {
          _recommendedDishes = [];
          _recommendedDishesError = 'Session expired. Please sign in again.';
          _isLoadingDishes = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _recommendedDishesError = 'Failed to load dish recommendations';
          _isLoadingDishes = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recommendedDishesError = 'Error: $e';
        _isLoadingDishes = false;
      });
    }
  }

  Future<void> _fetchUserPreferences() async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/profile/preferences/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode != 200 || !mounted) return;

      final body = json.decode(response.body) as Map<String, dynamic>;
      final cuisinePrefs = (body['cuisine_preferences'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);

      setState(() {
        _minHygieneScore = (body['min_hygiene_score'] as num?)?.toDouble();
        _distanceKm = (body['distance_radius_km'] as num?)?.toDouble();
        _cuisineType = cuisinePrefs.isEmpty ? null : cuisinePrefs.join(', ');
      });
    } catch (_) {
      // Ignore preferences fetch failures.
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

  Future<Position?> _getCurrentPosition() async {
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

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
  }

  double? _distanceKmBetween(Restaurant restaurant, Position position) {
    final lat = restaurant.latitude;
    final lon = restaurant.longitude;
    if (lat == null || lon == null) return null;

    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      lat,
      lon,
    );
    return meters / 1000.0;
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
      final position = await _getCurrentPosition();
      if (position == null) {
        setState(() {
          _nearbyRestaurants = [];
          _nearbyError = 'Unable to detect your location. Please allow location access.';
          _isLoadingNearby = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/recommendations/hygiene/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final radiusKm = _distanceKm ?? 5.0;
        final restaurants = data.map((json) => Restaurant.fromJson(json)).toList();
        final candidates = restaurants
            .where((restaurant) => restaurant.latitude != null && restaurant.longitude != null)
            .toList();

        final nearby = <Restaurant>[];
        for (final restaurant in candidates) {
          final distanceKm = _distanceKmBetween(restaurant, position);
          if (distanceKm == null) continue;
          if (distanceKm <= radiusKm) {
            nearby.add(restaurant);
          }
        }

        nearby.sort((a, b) {
          final distA = _distanceKmBetween(a, position) ?? double.infinity;
          final distB = _distanceKmBetween(b, position) ?? double.infinity;
          return distA.compareTo(distB);
        });

        if (nearby.isEmpty && candidates.isNotEmpty) {
          candidates.sort((a, b) {
            final distA = _distanceKmBetween(a, position) ?? double.infinity;
            final distB = _distanceKmBetween(b, position) ?? double.infinity;
            return distA.compareTo(distB);
          });
        }

        setState(() {
          _nearbyRestaurants = nearby.isNotEmpty ? nearby : candidates;
          _nearbyError = candidates.isEmpty ? 'No restaurants with coordinates found.' : null;
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

  Future<void> _fetchTrendingRestaurants() async {
    setState(() {
      _isLoadingTrending = true;
      _trendingError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/recommendations/trending/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _trendingRestaurants = data.map((json) => Restaurant.fromJson(json)).toList();
          _isLoadingTrending = false;
        });
      } else {
        setState(() {
          _trendingRestaurants = [];
          _trendingError = 'Failed to load trending restaurants';
          _isLoadingTrending = false;
        });
      }
    } catch (_) {
      setState(() {
        _trendingRestaurants = [];
        _trendingError = 'Unable to load trending restaurants.';
        _isLoadingTrending = false;
      });
    }
  }

  Future<void> _fetchTopRatedRestaurants() async {
    setState(() {
      _isLoadingTopRated = true;
      _topRatedError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/recommendations/top-rated/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _topRatedRestaurants = data.map((json) => Restaurant.fromJson(json)).toList();
          _isLoadingTopRated = false;
        });
      } else {
        setState(() {
          _topRatedRestaurants = [];
          _topRatedError = 'Failed to load top rated restaurants';
          _isLoadingTopRated = false;
        });
      }
    } catch (_) {
      setState(() {
        _topRatedRestaurants = [];
        _topRatedError = 'Unable to load top rated restaurants.';
        _isLoadingTopRated = false;
      });
    }
  }

  Future<void> _recordInteraction(int restaurantId, String interactionType) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) return;

      await http.post(
        Uri.parse('${Config.baseUrl}/api/accounts/user-interactions/'),
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

  Future<void> _fetchFavoriteIds() async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _favoriteIds.clear();
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/favorites/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode != 200 || !mounted) return;

      final Map<String, dynamic> body = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> results = (body['results'] as List<dynamic>? ?? <dynamic>[]);

      setState(() {
        _favoriteIds
          ..clear()
          ..addAll(
            results
                .map((item) => (item as Map<String, dynamic>)['id'])
                .whereType<num>()
                .map((id) => id.toInt()),
          );
      });
    } catch (_) {
      // Ignore favorite prefetch failures.
    }
  }

  Future<void> _toggleFavorite(Restaurant restaurant) async {
    if (_favoriteBusyIds.contains(restaurant.id)) return;

    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to update favorites.')),
      );
      return;
    }

    setState(() {
      _favoriteBusyIds.add(restaurant.id);
    });

    try {
      final isFavorite = _favoriteIds.contains(restaurant.id);
      late http.Response response;

      if (isFavorite) {
        response = await http.delete(
          Uri.parse('${Config.baseUrl}/api/accounts/favorites/${restaurant.id}/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );

        if ((response.statusCode == 204 || response.statusCode == 404) && mounted) {
          setState(() {
            _favoriteIds.remove(restaurant.id);
          });
          widget.onFavoritesChanged?.call();
          return;
        }
      } else {
        response = await http.post(
          Uri.parse('${Config.baseUrl}/api/accounts/favorites/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: json.encode({'restaurant_id': restaurant.id}),
        );

        if ((response.statusCode == 200 || response.statusCode == 201) && mounted) {
          setState(() {
            _favoriteIds.add(restaurant.id);
          });
          widget.onFavoritesChanged?.call();
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite (${response.statusCode}).')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update favorite. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _favoriteBusyIds.remove(restaurant.id);
        });
      }
    }
  }


  // City detection removed for web compatibility

  Future<void> _fetchRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('${Config.baseUrl}/api/accounts/recommendations/hygiene/'));
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

  /// Applies the search-text-only filter to a restaurant list.
  List<Restaurant> _applySearchFilter(List<Restaurant> input) {
    final searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isEmpty) return input;
    return input
        .where((r) => r.businessName.toLowerCase().contains(searchText))
        .toList();
  }

  /// Applies hygiene/cuisine advanced filters (set via filter dialog) to a restaurant list.
  List<Restaurant> _applyAdvancedFilters(List<Restaurant> input) {
    var output = List<Restaurant>.from(input);

    if (_minHygieneScore != null) {
      output = output.where((r) => r.hygieneScore >= _minHygieneScore!).toList();
    }

    if (_cuisineType != null && _cuisineType!.trim().isNotEmpty) {
      final cuisineList = _cuisineType!
          .toLowerCase()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (cuisineList.isNotEmpty) {
        output = output.where((r) {
          final cat = ((r.category ?? r.businessType)).toLowerCase();
          return cuisineList.any((c) => cat.contains(c));
        }).toList();
      }
    }

    return output;
  }

  /// Applies ALL active filters (search + advanced) to a restaurant list.
  List<Restaurant> _applyActiveFilters(List<Restaurant> input) {
    return _applyAdvancedFilters(_applySearchFilter(input));
  }

  /// Applies the search-text-only filter to a dish list.
  List<DishRecommendation> _applyDishSearchFilter(List<DishRecommendation> input) {
    final searchText = _searchController.text.trim().toLowerCase();
    if (searchText.isEmpty) return input;
    return input.where((d) {
      final haystack =
          '${d.name} ${d.category} ${d.restaurantName} ${d.restaurantType}'
              .toLowerCase();
      return haystack.contains(searchText);
    }).toList();
  }

  /// Applies hygiene/cuisine advanced filters (set via filter dialog) to a dish list.
  List<DishRecommendation> _applyDishAdvancedFilters(List<DishRecommendation> input) {
    var output = List<DishRecommendation>.from(input);

    if (_minHygieneScore != null) {
      output = output.where((d) => d.restaurantHygieneScore >= _minHygieneScore!).toList();
    }

    if (_cuisineType != null && _cuisineType!.trim().isNotEmpty) {
      final cuisineList = _cuisineType!
          .toLowerCase()
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (cuisineList.isNotEmpty) {
        output = output.where((d) {
          final cat = '${d.category} ${d.restaurantType}'.toLowerCase();
          return cuisineList.any((c) => cat.contains(c));
        }).toList();
      }
    }

    return output;
  }

  /// Applies ALL active filters (search + advanced) to a dish list.
  List<DishRecommendation> _applyDishFilters(List<DishRecommendation> input) {
    return _applyDishAdvancedFilters(_applyDishSearchFilter(input));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Filtering and Sorting Logic ---
    // Search text is ALWAYS applied; advanced filters (hygiene/cuisine/distance)
    // are only applied when the user has explicitly set them via the filter dialog.
    final baseRestaurants = _filtersApplied
        ? _applyActiveFilters(_restaurants)
        : _applySearchFilter(_restaurants);
    final baseRecommended = _filtersApplied
        ? _applyActiveFilters(_recommendedRestaurants)
        : _applySearchFilter(_recommendedRestaurants);
    // Dishes: always apply search filter; additionally apply advanced filters when set.
    final baseDishRecommended = _filtersApplied
        ? _applyDishFilters(_recommendedDishes)
        : _applyDishSearchFilter(_recommendedDishes);
    final baseTrending = _filtersApplied
        ? _applyActiveFilters(_trendingRestaurants)
        : _applySearchFilter(_trendingRestaurants);
    final baseNearby = _filtersApplied
        ? _applyActiveFilters(_nearbyRestaurants)
        : _applySearchFilter(_nearbyRestaurants);
    final baseTopRated = _filtersApplied
        ? _applyActiveFilters(_topRatedRestaurants)
        : _applySearchFilter(_topRatedRestaurants);
    List<Restaurant> filteredRecommended = baseRecommended;
    List<Restaurant> filteredNearby = baseNearby;
    List<Restaurant> filteredTrending = baseTrending;
    List<Restaurant> filteredTopRated = baseTopRated;
    // Distance filter is a placeholder (requires coordinates)

    // Apply selected filter
    if (_selectedFilter == 'Highest Hygiene') {
      // Highest hygiene list is already sorted by the backend.
    } else if (_selectedFilter == 'Nearby') {
      // Nearby is handled via _nearbyRestaurants fetched from backend.
    } else if (_selectedFilter == 'Trending') {
      // Trending uses interaction counts from the backend.
    } else if (_selectedFilter == 'Top Rated') {
      // Top rated list is already sorted by the backend.
    }

    // Defensive: avoid nulls and empty
    final mainList = baseRestaurants.take(5).toList();

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
                          : _selectedFilter == 'Restaurant Recommendations'
                          ? (_isLoadingRecommended
                              ? const Center(child: CircularProgressIndicator())
                              : (_recommendedError != null)
                                  ? Center(child: Text(_recommendedError!))
                                  : (filteredRecommended.isEmpty)
                                      ? const Center(child: Text('No restaurant recommendations yet.'))
                                      : ListView(
                                          padding: const EdgeInsets.all(20),
                                          children: [
                                            ...filteredRecommended.map((restaurant) => RestaurantCard(
                                                  restaurant: restaurant,
                                                  isFavorite: _favoriteIds.contains(restaurant.id),
                                                  isFavoriteLoading: _favoriteBusyIds.contains(restaurant.id),
                                                  onFavoriteTap: () => _toggleFavorite(restaurant),
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
                          : _selectedFilter == 'Dish Recommendations'
                              ? (_isLoadingDishes
                                  ? const Center(child: CircularProgressIndicator())
                                  : (_recommendedDishesError != null)
                                      ? Center(child: Text(_recommendedDishesError!))
                                      : baseDishRecommended.isEmpty
                                          ? const Center(child: Text('No dish recommendations yet.'))
                                          : ListView(
                                              padding: const EdgeInsets.all(20),
                                              children: [
                                                ...baseDishRecommended.map(_buildDishCard),
                                              ],
                                            ))
                            : _selectedFilter == 'Nearby'
                              ? (_isLoadingNearby
                                  ? const Center(child: CircularProgressIndicator())
                                  : _nearbyError != null
                                      ? Center(child: Text(_nearbyError!))
                                      : filteredNearby.isEmpty
                                          ? const Center(child: Text('No nearby restaurants found.'))
                                          : ListView(
                                              padding: const EdgeInsets.all(20),
                                              children: [
                                          ...filteredNearby.map((restaurant) => RestaurantCard(
                                                      restaurant: restaurant,
                                                  isFavorite: _favoriteIds.contains(restaurant.id),
                                                  isFavoriteLoading: _favoriteBusyIds.contains(restaurant.id),
                                                  onFavoriteTap: () => _toggleFavorite(restaurant),
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
                              : _selectedFilter == 'Trending'
                                  ? (_isLoadingTrending
                                      ? const Center(child: CircularProgressIndicator())
                                      : _trendingError != null
                                          ? Center(child: Text(_trendingError!))
                                          : filteredTrending.isEmpty
                                              ? const Center(child: Text('No trending restaurants found.'))
                                              : ListView(
                                                  padding: const EdgeInsets.all(20),
                                                  children: [
                                                    ...filteredTrending.map((restaurant) => RestaurantCard(
                                                          restaurant: restaurant,
                                                          isFavorite: _favoriteIds.contains(restaurant.id),
                                                          isFavoriteLoading: _favoriteBusyIds.contains(restaurant.id),
                                                          onFavoriteTap: () => _toggleFavorite(restaurant),
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
                              : _selectedFilter == 'Highest Hygiene'
                                  ? (baseRestaurants.isEmpty
                                      ? const Center(child: Text('No restaurants found.'))
                                      : ListView(
                                          padding: const EdgeInsets.all(20),
                                          children: [
                                            ...baseRestaurants.map((restaurant) => RestaurantCard(
                                                  restaurant: restaurant,
                                                  isFavorite: _favoriteIds.contains(restaurant.id),
                                                  isFavoriteLoading: _favoriteBusyIds.contains(restaurant.id),
                                                  onFavoriteTap: () => _toggleFavorite(restaurant),
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
                              : _selectedFilter == 'Top Rated'
                                  ? (_isLoadingTopRated
                                      ? const Center(child: CircularProgressIndicator())
                                      : _topRatedError != null
                                          ? Center(child: Text(_topRatedError!))
                                          : filteredTopRated.isEmpty
                                              ? const Center(child: Text('No top rated restaurants found.'))
                                              : ListView(
                                                  padding: const EdgeInsets.all(20),
                                                  children: [
                                                    ...filteredTopRated.map((restaurant) => RestaurantCard(
                                                          restaurant: restaurant,
                                                          isFavorite: _favoriteIds.contains(restaurant.id),
                                                          isFavoriteLoading: _favoriteBusyIds.contains(restaurant.id),
                                                          onFavoriteTap: () => _toggleFavorite(restaurant),
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
                                              isFavorite: _favoriteIds.contains(restaurant.id),
                                              isFavoriteLoading: _favoriteBusyIds.contains(restaurant.id),
                                              onFavoriteTap: () => _toggleFavorite(restaurant),
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
                  _userCity == null ? 'Detecting location…' : '${_userCity!}, Pakistan',
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
                    decoration: InputDecoration(
                      hintText: _selectedFilter == 'Dish Recommendations'
                          ? 'Search dishes, categories, restaurants…'
                          : 'Search restaurants…',
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: Colors.grey),
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
                  _filtersApplied = true;
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
              if (filterName == 'Restaurant Recommendations') {
                _fetchRecommendedRestaurants();
              } else if (filterName == 'Dish Recommendations') {
                _fetchRecommendedDishes();
              } else if (filterName == 'Trending') {
                _fetchTrendingRestaurants();
              } else if (filterName == 'Top Rated') {
                _fetchTopRatedRestaurants();
              } else if (filterName == 'Nearby') {
                _fetchNearbyRestaurants();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDishCard(DishRecommendation dish) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu, color: Color(0xFF00C48C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dish.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Text(
                      dish.price,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dish.restaurantName,
                  style: const TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  dish.category.isNotEmpty ? dish.category : dish.restaurantType,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(dish.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.shield_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      dish.restaurantHygieneScore.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
