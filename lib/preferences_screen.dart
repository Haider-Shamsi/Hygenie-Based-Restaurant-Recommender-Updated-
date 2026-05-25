import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  // State Variables
  double _minHygieneScore = 75;
  bool _excludeFlagged = true;
  double _distanceRadius = 5;
  final List<String> _selectedCuisines = ['Italian', 'Japanese'];

  final List<String> _allCuisines = [
    'Italian', 'Japanese', 'Chinese', 'Indian',
    'Mexican', 'Thai', 'Mediterranean', 'American',
  ];

  final Color _brandTeal = const Color(0xFF10B981);
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Sign in to manage preferences.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/profile/preferences/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load preferences (${response.statusCode}).';
        });
        return;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final cuisines = (body['cuisine_preferences'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(growable: false);

      setState(() {
        _minHygieneScore = (body['min_hygiene_score'] as num?)?.toDouble() ?? 75;
        _excludeFlagged = (body['exclude_flagged'] as bool?) ?? true;
        _distanceRadius = (body['distance_radius_km'] as num?)?.toDouble() ?? 5;
        _selectedCuisines
          ..clear()
          ..addAll(cuisines);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to load preferences right now.';
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_isSaving) return;

    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save preferences.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('${Config.baseUrl}/api/accounts/profile/preferences/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'min_hygiene_score': _minHygieneScore.round(),
          'exclude_flagged': _excludeFlagged,
          'distance_radius_km': _distanceRadius.round(),
          'cuisine_preferences': _selectedCuisines,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences (${response.statusCode}).')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save preferences. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
          "Preferences",
          style: TextStyle(color: Color(0xFF323F4B), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 120),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _fetchPreferences, child: const Text('Retry')),
                      ],
                    ),
                  )
                : Column(
          children: [
            // 1. Hygiene Score Card
            _buildPreferenceCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _brandTeal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.settings_outlined, color: _brandTeal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Minimum Hygiene Score", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("Only show restaurants above this score", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSliderLabel("Score Threshold", "${_minHygieneScore.toInt()}/100"),
                  Slider(
                    value: _minHygieneScore,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: _brandTeal,
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (val) => setState(() => _minHygieneScore = val),
                  ),
                  const _MinMaxLabel(min: "0", mid: "50", max: "100"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Exclude Flagged Switch
            _buildPreferenceCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Exclude Flagged Restaurants", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Hide restaurants with hygiene violations", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _excludeFlagged,
                    activeThumbColor: _brandTeal,
                    onChanged: (val) => setState(() => _excludeFlagged = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Search Radius Card
            _buildPreferenceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Search Radius", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  _buildSliderLabel("Maximum Distance", "${_distanceRadius.toInt()} km"),
                  Slider(
                    value: _distanceRadius,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    activeColor: _brandTeal,
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (val) => setState(() => _distanceRadius = val),
                  ),
                  const _MinMaxLabel(min: "1 km", mid: "10 km", max: "20 km"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Cuisine Selection
            _buildPreferenceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cuisine Preferences", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text("Select your favorite cuisines", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allCuisines.map((cuisine) {
                      final isSelected = _selectedCuisines.contains(cuisine);
                      return ChoiceChip(
                        label: Text(cuisine),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selected ? _selectedCuisines.add(cuisine) : _selectedCuisines.remove(cuisine);
                          });
                        },
                        selectedColor: _brandTeal,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isSelected ? _brandTeal : Colors.grey.shade300),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 5. Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  _savePreferences();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: Text(
                  _isSaving ? 'Saving...' : "Save Preferences",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper UI methods
  Widget _buildPreferenceCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSliderLabel(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: TextStyle(color: _brandTeal, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _MinMaxLabel extends StatelessWidget {
  final String min, mid, max;
  const _MinMaxLabel({required this.min, required this.mid, required this.max});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(min, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(mid, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(max, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
