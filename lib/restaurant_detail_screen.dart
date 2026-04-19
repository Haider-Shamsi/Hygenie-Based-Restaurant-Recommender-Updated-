import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart'; 
import 'models/restaurant.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --- MODAL TRIGGERS ---

  void _showWriteReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WriteReviewSheet(restaurantName: widget.restaurant.businessName),
    );
  }

  void _showReportIssueModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportIssueSheet(restaurantName: widget.restaurant.businessName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Image Section
            Stack(
              children: [
                widget.restaurant.imageUrl != null
                    ? Image.network(widget.restaurant.imageUrl!, height: 260, width: double.infinity, fit: BoxFit.cover)
                    : Container(
                        height: 260,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 80, color: Colors.grey),
                      ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content Overlay
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.restaurant.businessName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text(widget.restaurant.category ?? widget.restaurant.businessType, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text("${widget.restaurant.distance ?? ''} away", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        _buildHygieneGauge(widget.restaurant.hygieneScore),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF10B981),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: const Color(0xFF10B981),
                      tabs: const [Tab(text: "Overview"), Tab(text: "Hygiene"), Tab(text: "History")],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 450, // Height for tab content
                      child: TabBarView(
                        controller: _tabController,
                        children: [_buildOverviewTab(), _buildHygieneTab(), _buildHistoryTab()],
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      child: const Text("View Menu & Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showReportIssueModal, // Trigger Report Modal
                      icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      label: const Text("Report Hygiene Issue", style: TextStyle(color: Colors.redAccent)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("About", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(widget.restaurant.description ?? 'No description available.', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        const Text("Recent Reviews", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        // Write Review Button
        OutlinedButton.icon(
          onPressed: _showWriteReviewModal,
          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF10B981)),
          label: const Text("Write a Review", style: TextStyle(color: Color(0xFF10B981))),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 45),
            side: const BorderSide(color: Color(0xFF10B981)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        _buildReviewCard("Sarah Johnson", "Absolutely fantastic experience! Kitchen was spotless."),
        _buildReviewCard("Ahmed Khan", "Best restaurant in the area for hygiene standards."),
      ],
    );
  }
  

  Widget _buildReviewCard(String user, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(comment, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHygieneTab() {
    final breakdown = [
      {'label': 'Food Handling', 'score': 0.98},
      {'label': 'Kitchen Cleanliness', 'score': 0.95},
      {'label': 'Staff Training', 'score': 0.92},
      {'label': 'Storage Standards', 'score': 0.96},
    ];

    return Column(
      children: breakdown.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['label'] as String),
                  Text("${((item['score'] as double) * 100).toInt()}/100", 
                      style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: item['score'] as double,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF10B981),
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        const Text("6-Month Hygiene Trend", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: true, leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [FlSpot(0, 88), FlSpot(1, 90), FlSpot(2, 91), FlSpot(3, 93), FlSpot(4, 94), FlSpot(5, 95)],
                  isCurved: true,
                  color: const Color(0xFF10B981),
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHygieneGauge(double score) {
    return Column(
      children: [
        SizedBox(
          width: 70, height: 70,
          child: Stack(
            children: [
              Center(child: CustomPaint(size: const Size(70, 70), painter: GaugePainter(score: score))),
              Center(child: Text("${score.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF059669)))),
            ],
          ),
        ),
        const Text("Hygiene Score", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

// --- MODAL: WRITE A REVIEW ---
class _WriteReviewSheet extends StatefulWidget {
  final String restaurantName;
  const _WriteReviewSheet({required this.restaurantName});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Write a Review", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.restaurantName, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Your Rating*", style: TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: List.generate(5, (index) => IconButton(
                icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 32),
                onPressed: () => setState(() => _rating = index + 1),
              )),
            ),
            const SizedBox(height: 15),
            const Text("Your Review*", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Share your experience about food quality...",
                filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Post Review", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MODAL: REPORT HYGIENE ISSUE ---
class _ReportIssueSheet extends StatelessWidget {
  final String restaurantName;
  const _ReportIssueSheet({required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Report Hygiene Issue", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            Text("Reporting: $restaurantName", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const Text("Issue Category", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              items: ["Food Handling", "Cleanliness", "Pest Control"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {},
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(maxLines: 3, decoration: InputDecoration(hintText: "Describe the issue in detail...", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: () => Navigator.pop(context),
              child: const Text("Submit Report", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Gauge
class GaugePainter extends CustomPainter {
  final double score;
  GaugePainter({required this.score});
  @override
  void paint(Canvas canvas, Size size) {
    Paint baseCircle = Paint()..color = Colors.grey[200]!..style = PaintingStyle.stroke..strokeWidth = 6;
    Paint progressCircle = Paint()..color = const Color(0xFF10B981)..strokeCap = StrokeCap.round..style = PaintingStyle.stroke..strokeWidth = 6;
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = math.min(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, baseCircle);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * (score / 100), false, progressCircle);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}