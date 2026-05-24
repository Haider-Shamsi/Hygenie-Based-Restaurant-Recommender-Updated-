import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/restaurant.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  double _averageRating = 0;
  int _recentReportsCount = 0;
  List<_ReviewItem> _reviews = [];
  List<_HygieneMetric> _hygieneBreakdown = [];
  List<_HistoryPoint> _hygieneHistory = [];
  List<_MenuItem> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetailData();
  }

  // --- MODAL TRIGGERS ---

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchDetailData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.46:8000/api/accounts/restaurants/${widget.restaurant.id}/detail/'),
      );
      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Could not load restaurant details.';
        });
        return;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> reviewsJson = body['reviews'] as List<dynamic>? ?? <dynamic>[];
      final List<dynamic> breakdownJson = body['hygiene_breakdown'] as List<dynamic>? ?? <dynamic>[];
      final List<dynamic> historyJson = body['hygiene_history'] as List<dynamic>? ?? <dynamic>[];
      final List<dynamic> menuJson = body['menu_items'] as List<dynamic>? ?? <dynamic>[];

      if (!mounted) return;
      setState(() {
        _averageRating = (body['average_rating'] as num?)?.toDouble() ?? 0;
        _recentReportsCount = (body['recent_reports_count'] as num?)?.toInt() ?? 0;
        _reviews = reviewsJson.map((e) => _ReviewItem.fromJson(e as Map<String, dynamic>)).toList(growable: false);
        _hygieneBreakdown = breakdownJson.map((e) => _HygieneMetric.fromJson(e as Map<String, dynamic>)).toList(growable: false);
        _hygieneHistory = historyJson.map((e) => _HistoryPoint.fromJson(e as Map<String, dynamic>)).toList(growable: false);
        _menuItems = menuJson.map((e) => _MenuItem.fromJson(e as Map<String, dynamic>)).toList(growable: false);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load details right now.';
      });
    }
  }

  Future<void> _showWriteReviewModal() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WriteReviewSheet(
        restaurantName: widget.restaurant.businessName,
        onSubmit: _submitReview,
      ),
    );
    if (submitted == true) {
      _fetchDetailData();
    }
  }

  Future<void> _showReportIssueModal() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportIssueSheet(
        restaurantName: widget.restaurant.businessName,
        onSubmit: _submitIssueReport,
      ),
    );
    if (submitted == true) {
      _fetchDetailData();
    }
  }

  Future<bool> _submitReview({required int rating, required String comment}) async {
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to post a review.')),
      );
      return false;
    }

    final response = await http.post(
      Uri.parse('http://192.168.1.46:8000/api/accounts/restaurants/${widget.restaurant.id}/reviews/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({'rating': rating, 'comment': comment}),
    );

    if (response.statusCode == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted.')),
        );
      }
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review (${response.statusCode}).')),
      );
    }
    return false;
  }

  Future<bool> _submitIssueReport({required String category, required String description}) async {
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to report hygiene issues.')),
      );
      return false;
    }

    final response = await http.post(
      Uri.parse('http://192.168.1.46:8000/api/accounts/restaurants/${widget.restaurant.id}/reports/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({'category': category, 'description': description}),
    );

    if (response.statusCode == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue report submitted.')),
        );
      }
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report (${response.statusCode}).')),
      );
    }
    return false;
  }

  Future<void> _openMenuScreen() async {
    if (_menuItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No menu uploaded yet for this restaurant.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _MenuScreen(restaurantName: widget.restaurant.businessName, items: _menuItems),
      ),
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
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
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
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _fetchDetailData, child: const Text('Retry')),
                          ],
                        ),
                      )
                    else
                      ...[
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
                            const SizedBox(height: 4),
                            Text(
                              _averageRating > 0
                                  ? 'Avg rating ${_averageRating.toStringAsFixed(1)}  $_recentReportsCount reports'
                                  : 'No ratings yet  $_recentReportsCount reports',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
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
                      onPressed: _openMenuScreen,
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
        if (_reviews.isEmpty)
          const Text('No reviews yet. Be the first to write one.', style: TextStyle(color: Colors.grey))
        else
          ..._reviews.map((review) => _buildReviewCard(review.reviewerName, review.comment, review.rating, review.timeSince)),
      ],
    );
  }
  

  Widget _buildReviewCard(String user, String comment, int rating, String timeSince) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(user, style: const TextStyle(fontWeight: FontWeight.bold))),
              Text('$rating/5  $timeSince', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text(comment, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHygieneTab() {
    if (_hygieneBreakdown.isEmpty) {
      return const Center(child: Text('No hygiene breakdown available.'));
    }

    return Column(
      children: _hygieneBreakdown.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label),
                  Text("${item.score.toInt()}/100", 
                      style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: item.score / 100.0,
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
    if (_hygieneHistory.isEmpty) {
      return const Center(child: Text('No hygiene history available.'));
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < _hygieneHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), _hygieneHistory[i].score));
    }

    return Column(
      children: [
        const Text("6-Month Hygiene Trend", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _hygieneHistory.length) return const SizedBox.shrink();
                      return Text(_hygieneHistory[idx].month, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
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
  final Future<bool> Function({required int rating, required String comment}) onSubmit;

  const _WriteReviewSheet({required this.restaurantName, required this.onSubmit});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

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
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final comment = _reviewController.text.trim();
                      if (_rating < 1 || comment.length < 5) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Please add rating and a valid review.')),
                        );
                        return;
                      }

                      setState(() {
                        _isSubmitting = true;
                      });
                      final ok = await widget.onSubmit(rating: _rating, comment: comment);
                      if (!mounted) return;
                      setState(() {
                        _isSubmitting = false;
                      });
                      if (ok) {
                        navigator.pop(true);
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Post Review", style: TextStyle(color: Colors.white)),
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
  final Future<bool> Function({required String category, required String description}) onSubmit;

  const _ReportIssueSheet({required this.restaurantName, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final descriptionController = TextEditingController();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String selectedCategory = 'food_handling';
    bool isSubmitting = false;

    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Report Hygiene Issue", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              Text("Reporting: $restaurantName", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              const Text("Issue Category", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'food_handling', child: Text('Food Handling')),
                  DropdownMenuItem(value: 'cleanliness', child: Text('Cleanliness')),
                  DropdownMenuItem(value: 'pest_control', child: Text('Pest Control')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  setSheetState(() {
                    selectedCategory = val;
                  });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Describe the issue in detail...",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 50)),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final description = descriptionController.text.trim();
                        if (description.length < 8) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Please add a valid issue description.')),
                          );
                          return;
                        }

                        setSheetState(() {
                          isSubmitting = true;
                        });
                        final ok = await onSubmit(category: selectedCategory, description: description);
                        if (!navigator.mounted) return;
                        setSheetState(() {
                          isSubmitting = false;
                        });
                        if (ok) {
                          navigator.pop(true);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Submit Report", style: TextStyle(color: Colors.white)),
              ),
            ],
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

  const _ReviewItem({
    required this.reviewerName,
    required this.comment,
    required this.rating,
    required this.timeSince,
  });

  factory _ReviewItem.fromJson(Map<String, dynamic> json) {
    return _ReviewItem(
      reviewerName: (json['reviewer_name'] as String?) ?? 'User',
      comment: (json['comment'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      timeSince: (json['time_since'] as String?) ?? 'recently',
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

  const _MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.orderCount,
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
    );
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
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: const Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
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
          ),
        ],
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
