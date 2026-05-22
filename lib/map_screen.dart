import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'home_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _userLocation;
  bool _showFilterPanel = false;
  final TextEditingController _hygieneController = TextEditingController(
    text: "70",
  );
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initLocationAndMarkers();
  }

  Future<void> _initLocationAndMarkers() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      _loadNearbyRestaurants();
    } catch (e) {
      // Fallback to Lahore if location fails
      setState(() {
        _userLocation = LatLng(31.5204, 74.3587);
      });
      _loadNearbyRestaurants();
    }
  }

  void _loadNearbyRestaurants() {
    // Mock data: 3 restaurants near user
    final base = _userLocation ?? LatLng(31.5204, 74.3587);
    final List<Map<String, dynamic>> mockRestaurants = [
      {
        'id': '1',
        'name': 'Safe Place',
        'lat': base.latitude + 0.002,
        'lng': base.longitude + 0.002,
        'hygiene': 95,
      },
      {
        'id': '2',
        'name': 'Caution Area',
        'lat': base.latitude - 0.003,
        'lng': base.longitude - 0.001,
        'hygiene': 72,
      },
      {
        'id': '3',
        'name': 'Low Hygiene',
        'lat': base.latitude + 0.001,
        'lng': base.longitude - 0.002,
        'hygiene': 60,
      },
    ];
    List<Marker> markers = [
      Marker(
        point: base,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.person_pin_circle,
          color: Colors.blue,
          size: 36,
        ),
      ),
      ...mockRestaurants.map(
        (r) => Marker(
          point: LatLng(r['lat'], r['lng']),
          width: 40,
          height: 40,
          child: Icon(
            Icons.location_on,
            color: r['hygiene'] >= 85
                ? Colors.green
                : r['hygiene'] >= 70
                ? Colors.orange
                : Colors.red,
            size: 36,
          ),
        ),
      ),
    ];
    setState(() {
      _markers = markers;
    });
  }

  @override
  void dispose() {
    _hygieneController.dispose();
    _cuisineController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  // No _onMapCreated needed for flutter_map

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Map Layer (flutter_map)
          FlutterMap(
            options: MapOptions(
              initialCenter: _userLocation ?? LatLng(31.5204, 74.3587),
              initialZoom: 14.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // 2. Top UI Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBackButton(),
                      const SizedBox(width: 10),
                      Expanded(child: _buildFloatingBar("Lahore, Pakistan")),
                      const SizedBox(width: 10),
                      _buildFilterButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Legend Layer
          _buildLegend(),

          // 4. Filter Overlay Layer (The requested modification)
          if (_showFilterPanel) _buildFilterOverlay(),
        ],
      ),
    );
  }

  Widget _buildFilterOverlay() {
    return Positioned(
      top: 100, // Positioned below the top bar
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filters",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _showFilterPanel = false),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Hygiene Input
            _buildInputLabel("Minimum Hygiene Score"),
            _buildTextField(_hygieneController, "e.g. 70", isNumeric: true),

            const SizedBox(height: 15),

            // Cuisine Input
            _buildInputLabel("Cuisine Type"),
            _buildTextField(_cuisineController, "e.g. Italian, Fast Food"),

            const SizedBox(height: 15),

            // Radius Input
            _buildInputLabel("Distance Radius (km)"),
            _buildTextField(_radiusController, "e.g. 5"),

            const SizedBox(height: 25),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Placeholder for real filter logic
                  debugPrint("--- Applying Filters ---");
                  debugPrint("Min Hygiene: ${_hygieneController.text}");
                  debugPrint("Cuisine: ${_cuisineController.text}");
                  debugPrint("Radius: ${_radiusController.text}");

                  setState(() => _showFilterPanel = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C48C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5568),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumeric = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () {
        // This ensures the navigation stack is cleared and you return
        // specifically to the RestaurantListScreen (Home)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
      ),
    );
  }

  Widget _buildFloatingBar(String location) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Color(0xFF00C48C), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              location,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      top: 100,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(const Color(0xFF00C48C), "Safe (85+)"),
            _legendItem(Colors.orange, "Caution (70-84)"),
            _legendItem(Colors.red, "Low (<70)"),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 5),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _showFilterPanel = !_showFilterPanel;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: const Icon(Icons.tune),
      ),
    );
  }
}
