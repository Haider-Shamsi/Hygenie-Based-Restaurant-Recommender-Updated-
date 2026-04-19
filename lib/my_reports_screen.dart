import 'package:flutter/material.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("My Reports",
                style: TextStyle(
                    color: Color(0xFF323F4B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text("5 hygiene reports",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Status Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  _StatusChip(label: "Total", count: 5, color: Colors.grey),
                  _StatusChip(label: "Pending", count: 1, color: Colors.orange, bgColor: Color(0xFFFFF7ED)),
                  _StatusChip(label: "Active", count: 1, color: Colors.blue, bgColor: Color(0xFFEFF6FF)),
                  _StatusChip(label: "Resolved", count: 2, color: Color(0xFF10B981), bgColor: Color(0xFFECFDF5)),
                ],
              ),
            ),
          ),

          // 2. Reports List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                ReportCard(
                  restaurant: "Quick Bites",
                  category: "Food Handling",
                  time: "2 hours ago",
                  description: "Staff not wearing gloves while preparing food. Observed multiple instances during lunch rush.",
                  status: "Under Investigation",
                  statusColor: Colors.blue,
                  dotColor: Colors.red,
                  icon: Icons.visibility_outlined,
                ),
                ReportCard(
                  restaurant: "Ocean Breeze Café",
                  category: "Cleanliness",
                  time: "1 day ago",
                  description: "Tables not properly sanitized between customers.",
                  status: "Pending Review",
                  statusColor: Colors.orange,
                  dotColor: Colors.orange,
                  icon: Icons.access_time,
                ),
                ReportCard(
                  restaurant: "Spice Garden",
                  category: "Storage",
                  time: "3 days ago",
                  description: "Food stored at incorrect temperatures in display case.",
                  status: "Resolved",
                  statusColor: Color(0xFF10B981),
                  dotColor: Colors.red,
                  icon: Icons.check_circle_outline,
                  resolutionText: "This issue has been addressed by the restaurant management. Thank you for helping improve food safety!",
                ),
                ReportCard(
                  restaurant: "The Green Table",
                  category: "Pest Control",
                  time: "1 week ago",
                  description: "Noticed flies in the dining area near the kitchen entrance.",
                  status: "Resolved",
                  statusColor: Color(0xFF10B981),
                  dotColor: Colors.orange,
                  icon: Icons.check_circle_outline,
                  resolutionText: "This issue has been addressed by the restaurant management. Thank you for helping improve food safety!",
                ),
                ReportCard(
                  restaurant: "Downtown Diner",
                  category: "Waste Management",
                  time: "2 weeks ago",
                  description: "Overflowing trash bins visible from dining area.",
                  status: "Dismissed",
                  statusColor: Colors.blueGrey,
                  dotColor: Colors.blue,
                  icon: Icons.cancel_outlined,
                  resolutionText: "This report was reviewed and deemed not to violate hygiene standards.",
                  isDismissed: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final String restaurant, category, time, description, status;
  final String? resolutionText;
  final Color statusColor, dotColor;
  final IconData icon;
  final bool isDismissed;

  const ReportCard({
    super.key,
    required this.restaurant,
    required this.category,
    required this.time,
    required this.description,
    required this.status,
    required this.statusColor,
    required this.dotColor,
    required this.icon,
    this.resolutionText,
    this.isDismissed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(restaurant, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF323F4B))),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 4),
          Text("$category  •  $time", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          
          const SizedBox(height: 16),
          Text(description, style: const TextStyle(color: Color(0xFF323F4B), height: 1.4)),
          
          const SizedBox(height: 16),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),

          // Resolution Box
          if (resolutionText != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDismissed ? const Color(0xFFF8FAFC) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDismissed) const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(resolutionText!, 
                        style: TextStyle(
                          color: isDismissed ? const Color(0xFF64748B) : const Color(0xFF065F46), 
                          fontSize: 13, 
                          height: 1.4
                        )),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color? bgColor;

  const _StatusChip({required this.label, required this.count, required this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text("$count", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}