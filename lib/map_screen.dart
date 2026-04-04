import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_screen.dart';
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(31.5204, 74.3587);

  // Filter State
  bool _showFilterPanel = false;
  final TextEditingController _hygieneController = TextEditingController(text: "70");
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('marker_1'),
      position: LatLng(31.5204, 74.3587),
      infoWindow: InfoWindow(title: 'Safe Place', snippet: 'Hygiene Score: 95'),
    ),
    const Marker(
      markerId: MarkerId('marker_2'),
      position: LatLng(31.5100, 74.3400),
      infoWindow: InfoWindow(title: 'Caution Area', snippet: 'Hygiene Score: 72'),
    ),
  };

  @override
  void dispose() {
    _hygieneController.dispose();
    _cuisineController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ResizeToAvoidBottomInset ensures the keyboard doesn't break the layout 
      // when typing in the overlay fields
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Map Layer
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 14.0),
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
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
            )
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  "Apply Filters",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A5568), fontSize: 14),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            child: Text(location, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
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