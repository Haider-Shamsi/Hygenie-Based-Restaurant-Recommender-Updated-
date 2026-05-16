import 'package:flutter/material.dart';

// --- DATA MODELS ---

class OwnerReview {
  final String id;
  final String userName;
  final int rating;
  final String date;
  final String reviewText;
  final String sentiment;
  final int helpfulCount;
  Map<String, String>? ownerResponse;

  OwnerReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.date,
    required this.reviewText,
    required this.sentiment,
    required this.helpfulCount,
    this.ownerResponse,
  });
}

// --- SCREEN WIDGET ---

class OwnerReviewsManagementScreen extends StatefulWidget {
  final VoidCallback onBack;
  const OwnerReviewsManagementScreen({super.key, required this.onBack});

  @override
  State<OwnerReviewsManagementScreen> createState() => _OwnerReviewsManagementScreenState();
}

class _OwnerReviewsManagementScreenState extends State<OwnerReviewsManagementScreen> {
  // Theme Colors
  final Color _brandTeal = const Color(0xFF10B981);
  final Color _bgGray = const Color(0xFFF9FBFB);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGray = const Color(0xFF6B7280);

  // State Variables
  String _activeFilter = 'all'; // 'all', 'needs-response', 'responded', 'negative'
  Set<String> _expandedReviews = {};
  String? _respondingToId;
  final TextEditingController _responseController = TextEditingController();

  // Mock Data
  late List<OwnerReview> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = [
      OwnerReview(
        id: '1',
        userName: 'Sarah Mitchell',
        rating: 5,
        date: 'Dec 10, 2025',
        reviewText: 'Absolutely fantastic experience! The food was fresh, delicious, and beautifully presented. The staff was incredibly attentive and friendly. Will definitely be coming back!',
        sentiment: 'Positive',
        helpfulCount: 12,
        ownerResponse: {
          'text': "Thank you so much for your kind words, Sarah! We're thrilled you enjoyed your experience with us. We look forward to serving you again soon!",
          'date': 'Dec 11, 2025',
        },
      ),
      OwnerReview(
        id: '2',
        userName: 'Michael Chen',
        rating: 4,
        date: 'Dec 8, 2025',
        reviewText: 'Great food and atmosphere. The hygiene standards are clearly excellent. Only minor issue was the wait time, but the quality made up for it.',
        sentiment: 'Positive',
        helpfulCount: 8,
      ),
      OwnerReview(
        id: '3',
        userName: 'Emma Rodriguez',
        rating: 2,
        date: 'Dec 5, 2025',
        reviewText: 'Disappointed with the service. Food was okay but took too long to arrive. The restaurant seemed understaffed during our visit.',
        sentiment: 'Negative',
        helpfulCount: 3,
      ),
      OwnerReview(
        id: '4',
        userName: 'David Park',
        rating: 5,
        date: 'Dec 3, 2025',
        reviewText: 'Outstanding! Every dish exceeded expectations. The attention to cleanliness and hygiene is impressive. Highly recommend the salmon!',
        sentiment: 'Positive',
        helpfulCount: 15,
        ownerResponse: {
          'text': "We're so happy you loved the salmon, David! Our chef takes great pride in sourcing the freshest ingredients. Thank you for the recommendation!",
          'date': 'Dec 4, 2025',
        },
      ),
      OwnerReview(
        id: '5',
        userName: 'Lisa Thompson',
        rating: 3,
        date: 'Dec 1, 2025',
        reviewText: 'Mixed feelings about this place. The food quality is good and the place is clean, but prices are a bit high for the portion sizes. Service was friendly though.',
        sentiment: 'Mixed',
        helpfulCount: 5,
      ),
      OwnerReview(
        id: '6',
        userName: 'James Wilson',
        rating: 5,
        date: 'Nov 28, 2025',
        reviewText: 'Best restaurant in the area! Consistently excellent food, impeccable cleanliness, and wonderful staff. Been coming here for months and it never disappoints.',
        sentiment: 'Positive',
        helpfulCount: 20,
      ),
    ];
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  // --- ACTIONS & LOGIC ---

  List<OwnerReview> get _filteredReviews {
    if (_activeFilter == 'needs-response') return _reviews.where((r) => r.ownerResponse == null).toList();
    if (_activeFilter == 'responded') return _reviews.where((r) => r.ownerResponse != null).toList();
    if (_activeFilter == 'negative') return _reviews.where((r) => r.rating <= 2).toList();
    return _reviews;
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedReviews.contains(id)) {
        _expandedReviews.remove(id);
      } else {
        _expandedReviews.add(id);
      }
    });
  }

  void _submitResponse(String id) {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a response'), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      final reviewIndex = _reviews.indexWhere((r) => r.id == id);
      if (reviewIndex != -1) {
        _reviews[reviewIndex].ownerResponse = {
          'text': _responseController.text.trim(),
          'date': 'Just now',
        };
      }
      _respondingToId = null;
      _responseController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Response submitted successfully!'), backgroundColor: Colors.green));
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)), onPressed: widget.onBack),
        title: const Text("Reviews Management", style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: Colors.grey.shade200, height: 1.0)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 16),
            _buildFilterTabs(),
            const SizedBox(height: 16),
            _buildReviewsList(),
            const SizedBox(height: 24),
            if (_filteredReviews.isNotEmpty) _buildPagination(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    int total = _reviews.length;
    double avgRating = total > 0 ? _reviews.fold(0, (sum, r) => sum + r.rating) / total : 0.0;
    int respondedCount = _reviews.where((r) => r.ownerResponse != null).length;
    int responseRate = total > 0 ? ((respondedCount / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(avgRating.toStringAsFixed(1), style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(width: 8),
                      Row(children: List.generate(5, (index) => Icon(index < avgRating.round() ? Icons.star : Icons.star_border, color: Colors.amber, size: 20))),
                    ],
                  ),
                  Text("$total total reviews", style: TextStyle(color: _textGray, fontSize: 13)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$responseRate%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _brandTeal)),
                  Text("Response Rate", style: TextStyle(color: _textGray, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(5, (index) {
            int stars = 5 - index;
            int count = _reviews.where((r) => r.rating == stars).length;
            double percentage = total > 0 ? count / total : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Row(children: [Text("$stars", style: TextStyle(color: _textDark, fontWeight: FontWeight.w500)), const SizedBox(width: 4), const Icon(Icons.star, color: Colors.amber, size: 12)])),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: percentage, backgroundColor: Colors.grey.shade100, color: _brandTeal, minHeight: 10),
                    ),
                  ),
                  SizedBox(width: 30, child: Text("$count", textAlign: TextAlign.right, style: TextStyle(color: _textGray, fontSize: 12))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = [
      {'id': 'all', 'label': 'All Reviews', 'count': _reviews.length},
      {'id': 'needs-response', 'label': 'Needs Response', 'count': _reviews.where((r) => r.ownerResponse == null).length},
      {'id': 'responded', 'label': 'Responded', 'count': _reviews.where((r) => r.ownerResponse != null).length},
      {'id': 'negative', 'label': 'Negative', 'count': _reviews.where((r) => r.rating <= 2).length},
    ];

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            bool isActive = _activeFilter == tab['id'];
            return InkWell(
              onTap: () => setState(() => _activeFilter = tab['id'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? _brandTeal : Colors.transparent, width: 2))),
                child: Row(
                  children: [
                    Text(tab['label'] as String, style: TextStyle(color: isActive ? _brandTeal : _textGray, fontWeight: FontWeight.w600, fontSize: 13)),
                    if ((tab['count'] as int) > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: isActive ? _brandTeal.withOpacity(0.1) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                        child: Text("${tab['count']}", style: TextStyle(color: isActive ? _brandTeal : _textGray, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_filteredReviews.isEmpty) return _buildEmptyState();

    return Column(
      children: _filteredReviews.map((review) {
        bool isExpanded = _expandedReviews.contains(review.id);
        bool shouldTruncate = review.reviewText.length > 150;
        String displayText = (isExpanded || !shouldTruncate) ? review.reviewText : '${review.reviewText.substring(0, 150)}...';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF34D399), Color(0xFF14B8A6)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    child: Center(child: Text(_getInitials(review.userName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(review.userName, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 14)),
                            Text(review.date, style: TextStyle(color: _textGray, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(children: List.generate(5, (index) => Icon(index < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Review Text
              Text(displayText, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5)),
              if (shouldTruncate)
                InkWell(
                  onTap: () => _toggleExpand(review.id),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(isExpanded ? "Show less" : "Read more", style: TextStyle(color: _brandTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 12),

              // Sentiment Badge
              _buildSentimentBadge(review.sentiment),
              const SizedBox(height: 16),

              // Owner Response Section
              if (review.ownerResponse != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _brandTeal.withOpacity(0.05), borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12), bottomLeft: Radius.circular(12)), border: Border(left: BorderSide(color: _brandTeal.withOpacity(0.3), width: 3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Owner Response", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(review.ownerResponse!['date']!, style: TextStyle(color: _textGray, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(review.ownerResponse!['text']!, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5)),
                    ],
                  ),
                )
              else if (_respondingToId == review.id)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      TextField(
                        controller: _responseController,
                        maxLines: 4,
                        decoration: InputDecoration(hintText: "Write your response...", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(onPressed: () => _submitResponse(review.id), icon: const Icon(Icons.send, size: 14, color: Colors.white), label: const Text("Submit", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton(onPressed: () => setState(() => _respondingToId = null), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Cancel", style: TextStyle(color: Colors.grey)))),
                        ],
                      )
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() { _respondingToId = review.id; _responseController.clear(); }),
                    style: OutlinedButton.styleFrom(foregroundColor: _brandTeal, side: BorderSide(color: _brandTeal.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("Write Response"),
                  ),
                ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Icon(Icons.thumb_up_alt_outlined, size: 14, color: _textGray), const SizedBox(width: 6), Text("Helpful (${review.helpfulCount})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textGray))]),
                  Row(children: [Icon(Icons.flag_outlined, size: 14, color: _textGray), const SizedBox(width: 6), Text("Report", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _textGray))]),
                ],
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSentimentBadge(String sentiment) {
    Color bg, text, border;
    if (sentiment == 'Positive') {
      bg = Colors.green.shade50; text = Colors.green.shade700; border = Colors.green.shade200;
    } else if (sentiment == 'Negative') {
      bg = Colors.red.shade50; text = Colors.red.shade700; border = Colors.red.shade200;
    } else {
      bg = Colors.orange.shade50; text = Colors.orange.shade700; border = Colors.orange.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(20)),
      child: Text(sentiment, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _brandTeal.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_activeFilter == 'needs-response' ? Icons.check_circle : Icons.celebration, color: _brandTeal, size: 40),
          ),
          const SizedBox(height: 16),
          Text(_activeFilter == 'needs-response' ? "All Caught Up!" : "No Negative Reviews!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 8),
          Text(
            _activeFilter == 'needs-response' ? "You've responded to all reviews that need attention." : "Great job! You don't have any negative reviews.",
            textAlign: TextAlign.center, style: TextStyle(color: _textGray, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(onPressed: null, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Previous")),
        const SizedBox(width: 8),
        _pageBox("1", true),
        const SizedBox(width: 4),
        _pageBox("2", false),
        const SizedBox(width: 4),
        _pageBox("3", false),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Next")),
      ],
    );
  }

  Widget _pageBox(String num, bool isActive) {
    return Container(
      width: 32, height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: isActive ? _brandTeal : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: Text(num, style: TextStyle(color: isActive ? Colors.white : _textDark, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}