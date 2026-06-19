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
<<<<<<< Updated upstream
        ),
        const SizedBox(height: 16),
        _buildReviewCard("Sarah Johnson", "Absolutely fantastic experience! Kitchen was spotless."),
        _buildReviewCard("Ahmed Khan", "Best restaurant in the area for hygiene standards."),
      ],
=======
          const SizedBox(height: 10),
          if (widget.restaurant.latitude != null && widget.restaurant.longitude != null)
            TextButton.icon(
              onPressed: () async {
                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.restaurant.latitude},${widget.restaurant.longitude}');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Could not launch URL: $e');
                }
              },
              icon: const Icon(Icons.map_outlined, color: Color(0xFF10B981), size: 18),
              label: const Text("Open in Google Maps", style: TextStyle(color: Color(0xFF10B981))),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                alignment: Alignment.centerLeft,
              ),
            ),
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
          if (_reviews.isEmpty)
            const Text('No reviews yet. Be the first to write one.', style: TextStyle(color: Colors.grey))
          else
            ..._reviews.map((review) => _buildReviewCard(review.reviewerName, review.comment, review.rating, review.timeSince, isGoogleReview: review.isGoogleReview)),
        ],
      ),
>>>>>>> Stashed changes
    );
  }
  

<<<<<<< Updated upstream
  Widget _buildReviewCard(String user, String comment) {
=======
  Widget _buildReviewCard(String user, String comment, int rating, String timeSince, {bool isGoogleReview = false}) {
>>>>>>> Stashed changes
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< Updated upstream
          Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
=======
          Row(
            children: [
              if (isGoogleReview) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.blue, size: 10),
                      const SizedBox(width: 3),
                      const Text(
                        "Google",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(child: Text(user, style: const TextStyle(fontWeight: FontWeight.bold))),
              Text('$rating/5  $timeSince', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
            const SizedBox(height: 20),
            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(maxLines: 3, decoration: InputDecoration(hintText: "Describe the issue in detail...", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
              onPressed: () => Navigator.pop(context),
              child: const Text("Submit Report", style: TextStyle(color: Colors.white)),
=======
          ),
        ),
      ),
    );
  }
}

class _ReviewItem {
  final String reviewerName;
  final String comment;
  final int rating;
  final String timeSince;
  final bool isGoogleReview;

  const _ReviewItem({
    required this.reviewerName,
    required this.comment,
    required this.rating,
    required this.timeSince,
    required this.isGoogleReview,
  });

  factory _ReviewItem.fromJson(Map<String, dynamic> json) {
    return _ReviewItem(
      reviewerName: (json['reviewer_name'] as String?) ?? 'User',
      comment: (json['comment'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      timeSince: (json['time_since'] as String?) ?? 'recently',
      isGoogleReview: (json['is_google_review'] as bool?) ?? false,
    );
  }
}

class _HygieneMetric {
  final String label;
  final double score;

  const _HygieneMetric({required this.label, required this.score});

  factory _HygieneMetric.fromJson(Map<String, dynamic> json) {
    return _HygieneMetric(
      label: (json['label'] as String?) ?? 'Metric',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class _HistoryPoint {
  final String month;
  final double score;

  const _HistoryPoint({required this.month, required this.score});

  factory _HistoryPoint.fromJson(Map<String, dynamic> json) {
    return _HistoryPoint(
      month: (json['month'] as String?) ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}

class _MenuItem {
  final String name;
  final String description;
  final double price;
  final double rating;
  final int orderCount;
  final String category;

  const _MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.orderCount,
    required this.category,
  });

  factory _MenuItem.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    return _MenuItem(
      name: (json['name'] as String?) ?? 'Menu item',
      description: (json['description'] as String?) ?? '',
      price: parsedPrice,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      category: (json['category'] as String?) ?? '',
    );
  }

  String get imageUrl {
    final lowerName = name.toLowerCase();
    final lowerCat = category.toLowerCase();

    // 1. Pizza
    if (lowerName.contains('pizza')) {
      return 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=500&q=80';
    }
    // 2. Burger & Wings
    if (lowerName.contains('burger') || lowerName.contains('wings')) {
      return 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=500&q=80';
    }
    // 3. Fries / Potato
    if (lowerName.contains('fries') || lowerName.contains('chips') || lowerName.contains('potato')) {
      return 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=500&q=80';
    }
    // 4. Pasta / Lasagne / Penne
    if (lowerName.contains('pasta') || lowerName.contains('lasagne') || lowerName.contains('penne') || lowerName.contains('carbonara') || lowerName.contains('arrabbiata')) {
      return 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=500&q=80';
    }
    // 5. Biryani & Rice
    if (lowerName.contains('biryani') || lowerName.contains('rice') || lowerName.contains('pulao')) {
      return 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?auto=format&fit=crop&w=500&q=80';
    }
    // 6. Indian/South Asian Curries & Bread & Kebab (Tikka, Paneer, Naan, Kebab, Samosa, Bhaji, Dal)
    if (lowerName.contains('tikka') || lowerName.contains('paneer') || lowerName.contains('naan') || 
        lowerName.contains('kebab') || lowerName.contains('samosa') || lowerName.contains('bhaji') || 
        lowerName.contains('dal') || lowerName.contains('curry') || lowerCat.contains('south asian')) {
      return 'https://images.unsplash.com/photo-1585938338392-50a5d22beb18?auto=format&fit=crop&w=500&q=80';
    }
    // 7. Salads & Veggie dips (Tzatziki, Hummus, Tabbouleh, Salad)
    if (lowerName.contains('salad') || lowerName.contains('tzatziki') || lowerName.contains('hummus') || 
        lowerName.contains('tabbouleh') || lowerName.contains('leaves') || lowerName.contains('pita') || lowerName.contains('greek salad')) {
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=500&q=80';
    }
    // 8. Tacos & Mexican Wraps (Tacos, Quesadilla, Burrito, Wrap, Shawarma, Nachos, Enchiladas, Fajita, Guacamole, Pico)
    if (lowerName.contains('taco') || lowerName.contains('quesadilla') || lowerName.contains('burrito') || 
        lowerName.contains('wrap') || lowerName.contains('shawarma') || lowerName.contains('nachos') || 
        lowerName.contains('enchiladas') || lowerName.contains('fajita') || lowerName.contains('guacamole') || 
        lowerName.contains('pico') || lowerCat.contains('mexican') || lowerCat.contains('mediterranean')) {
      return 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=500&q=80';
    }
    // 9. Soups
    if (lowerName.contains('soup')) {
      return 'https://images.unsplash.com/photo-1547592165-e1d17fed6005?auto=format&fit=crop&w=500&q=80';
    }
    // 10. Pies & Baked (Pie, Wellington, Pasty, Pudding)
    if (lowerName.contains('pie') || lowerName.contains('wellington') || lowerName.contains('pasty') || lowerName.contains('pudding')) {
      return 'https://images.unsplash.com/photo-1519869325930-281384150729?auto=format&fit=crop&w=500&q=80';
    }
    // 11. Drinks (Coffee, Cappuccino, Lassi, Smoothie, Milkshake, Drink, Tea, Beverage)
    if (lowerName.contains('coffee') || lowerName.contains('cappuccino') || lowerName.contains('lassi') || 
        lowerName.contains('smoothie') || lowerName.contains('milkshake') || lowerName.contains('drink') || 
        lowerName.contains('tea') || lowerName.contains('beverage')) {
      return 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=500&q=80';
    }
    // 12. Desserts (Cake, Tiramisu, Baklava, Churros, Flan, Sponge, Muffin, Croissant, Scone, Donut, Dessert, Cannoli, Gulab Jamun)
    if (lowerName.contains('cake') || lowerName.contains('tiramisu') || lowerName.contains('baklava') || 
        lowerName.contains('churros') || lowerName.contains('flan') || lowerName.contains('sponge') || 
        lowerName.contains('muffin') || lowerName.contains('croissant') || lowerName.contains('scone') || 
        lowerName.contains('donut') || lowerName.contains('dessert') || lowerName.contains('cannoli') || 
        lowerName.contains('gulab jamun')) {
      return 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=500&q=80';
    }
    // 13. Eggs / Breakfast (Toast, Eggs, Benedict, Croissant)
    if (lowerName.contains('eggs') || lowerName.contains('toast') || lowerName.contains('benedict') || lowerName.contains('breakfast')) {
      return 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=500&q=80';
    }
    // 14. Chinese items
    if (lowerCat.contains('chinese') || lowerName.contains('dumpling') || lowerName.contains('wonton') || lowerName.contains('mein') || lowerName.contains('duck') || lowerName.contains('rolls')) {
      return 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&w=500&q=80';
    }
    
    // Default food fallback
    return 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=500&q=80';
  }
}

class _MenuScreen extends StatelessWidget {
  final String restaurantName;
  final List<_MenuItem> items;

  const _MenuScreen({required this.restaurantName, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text('$restaurantName Menu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _MenuCard(item: item);
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  item.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Text(
                    item.rating.toStringAsFixed(1),
                    style: const TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('PKR ${item.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description.isEmpty ? 'No description available.' : item.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text('Rating ${item.rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
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