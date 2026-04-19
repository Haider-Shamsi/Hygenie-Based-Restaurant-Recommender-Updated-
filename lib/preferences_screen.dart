import 'package:flutter/material.dart';

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
        child: Column(
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
                          color: _brandTeal.withOpacity(0.1),
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
                    activeColor: _brandTeal,
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
                  // Logic to save preferences
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text(
                  "Save Preferences",
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
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
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