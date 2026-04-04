import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF323F4B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hygiene Alerts",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF323F4B)),
                ),
                SizedBox(height: 8),
                Text(
                  "Restaurants near you with hygiene concerns",
                  style: TextStyle(fontSize: 16, color: Color(0xFF7A869A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Alerts List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                AlertCard(
                  name: "Quick Bites",
                  category: "Fast Food",
                  message: "Low hygiene score detected",
                  distance: "1.5 km",
                  timeAgo: "2 hours ago",
                  score: 45,
                  severityColor: Colors.red,
                ),
                AlertCard(
                  name: "Street Food Corner",
                  category: "Street Food",
                  message: "Recent health inspection warning",
                  distance: "3.2 km",
                  timeAgo: "5 hours ago",
                  score: 52,
                  severityColor: Colors.red,
                ),
                AlertCard(
                  name: "Spice Garden",
                  category: "Indian",
                  message: "Hygiene score dropped below your threshold",
                  distance: "2.1 km",
                  timeAgo: "1 day ago",
                  score: 68,
                  severityColor: Colors.red,
                ),
                AlertCard(
                  name: "Ocean Breeze",
                  category: "Seafood",
                  message: "Temperature control issues reported",
                  distance: "4.5 km",
                  timeAgo: "2 days ago",
                  score: 72,
                  severityColor: Colors.orange,
                ),
              ],
            ),
          ),

          // Bottom Action Button
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Adjust Alert Preferences",
                  style: TextStyle(color: Color(0xFF323F4B), fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final String name, category, message, distance, timeAgo;
  final int score;
  final Color severityColor;

  const AlertCard({
    super.key,
    required this.name,
    required this.category,
    required this.message,
    required this.distance,
    required this.timeAgo,
    required this.score,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severityColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: severityColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF323F4B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(8)),
                      child: Text(score.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(category, style: const TextStyle(color: Color(0xFF7A869A), fontSize: 14)),
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(color: Color(0xFF323F4B), fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF7A869A)),
                    const SizedBox(width: 4),
                    Text("$distance  •  $timeAgo", style: const TextStyle(color: Color(0xFF7A869A), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black26),
        ],
      ),
    );
  }
}