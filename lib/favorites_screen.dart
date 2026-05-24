import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/restaurant.dart';
import 'widgets/restaurant_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Restaurant> _savedRestaurants = [];
  final Set<int> _deletingIds = <int>{};
  bool _isLoading = true;
  String? _error;

  Future<void> refreshFavorites() => _fetchFavorites();

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _savedRestaurants = [];
          _error = 'Sign in to view your favorites.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.46:8000/api/accounts/favorites/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> results = (body['results'] as List<dynamic>? ?? <dynamic>[]);
        setState(() {
          _savedRestaurants = results
              .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
              .toList(growable: false);
          _isLoading = false;
        });
      } else {
        setState(() {
          _savedRestaurants = [];
          _isLoading = false;
          _error = 'Failed to load favorites (${response.statusCode}).';
        });
      }
    } catch (_) {
      setState(() {
        _savedRestaurants = [];
        _isLoading = false;
        _error = 'Unable to load favorites right now.';
      });
    }
  }

  Future<void> _removeFavorite(Restaurant restaurant) async {
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to update favorites.')),
      );
      return;
    }

    setState(() {
      _deletingIds.add(restaurant.id);
    });

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.1.46:8000/api/accounts/favorites/${restaurant.id}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 204) {
        setState(() {
          _savedRestaurants = _savedRestaurants.where((r) => r.id != restaurant.id).toList(growable: false);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove favorite (${response.statusCode}).')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove favorite. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(restaurant.id);
        });
      }
    }
  }

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
          'Favorites',
          style: TextStyle(color: Color(0xFF323F4B), fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_savedRestaurants.length} saved',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF323F4B)),
                ),
                const Text(
                  'restaurants',
                  style: TextStyle(fontSize: 16, color: Color(0xFF323F4B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchFavorites,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_savedRestaurants.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No favorites yet. Save restaurants from the home feed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7A869A)),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _savedRestaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _savedRestaurants[index];
          final isDeleting = _deletingIds.contains(restaurant.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Stack(
              children: [
                RestaurantCard(
                  restaurant: restaurant,
                  onTap: () {},
                ),
                Positioned(
                  bottom: 15,
                  right: 15,
                  child: InkWell(
                    onTap: isDeleting ? null : () => _removeFavorite(restaurant),
                    child: isDeleting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
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
    );
  }
}
