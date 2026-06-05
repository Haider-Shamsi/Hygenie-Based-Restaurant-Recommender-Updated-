import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

// --- DATA MODELS ---

class FlaggedReview {
  final String id;
  final String reviewText;
  final int rating;
  final String reviewerName;
  final String reviewerAccountAge;
  final int reviewerTotalReviews;
  final String restaurantName;
  final String restaurantId;
  final String flagReasonType; // 'auto' or 'manual'
  final String flagReasonSource;
  final String? flagReasonNote;
  final double nlpSentimentScore;
  final String nlpSentimentLabel;
  final List<String> nlpDetectedIssues;
  final int nlpConfidenceScore;
  final List<String> nlpKeyPhrases;
  final int nlpToxicityScore;
  final List<String> nlpProblematicWords;
  final String submittedDate;
  final String flagCategory; // 'nlp-auto', 'user-reported', 'spam', 'inappropriate'
  final String adminNote;

  FlaggedReview({
    required this.id,
    required this.reviewText,
    required this.rating,
    required this.reviewerName,
    required this.reviewerAccountAge,
    required this.reviewerTotalReviews,
    required this.restaurantName,
    required this.restaurantId,
    required this.flagReasonType,
    required this.flagReasonSource,
    this.flagReasonNote,
    required this.nlpSentimentScore,
    required this.nlpSentimentLabel,
    required this.nlpDetectedIssues,
    required this.nlpConfidenceScore,
    required this.nlpKeyPhrases,
    required this.nlpToxicityScore,
    required this.nlpProblematicWords,
    required this.submittedDate,
    required this.flagCategory,
    required this.adminNote,
  });
}

class ModerationHistory {
  final String id;
  final String reviewId;
  final String action;
  final String admin;
  final String notes;
  final String date;

  ModerationHistory({
    required this.id,
    required this.reviewId,
    required this.action,
    required this.admin,
    required this.notes,
    required this.date,
  });
}

// --- WIDGET ---

class AdminReviewModerationPanel extends StatefulWidget {
  const AdminReviewModerationPanel({super.key});

  @override
  State<AdminReviewModerationPanel> createState() => _AdminReviewModerationPanelState();
}

class _AdminReviewModerationPanelState extends State<AdminReviewModerationPanel> {
  // Theme Colors
  final Color _brandTeal = const Color(0xFF10B981);
  //final Color _brandRed = const Color(0xFFEF4444);
  final Color _brandPurple = const Color(0xFF8B5CF6);
  final Color _brandAmber = const Color(0xFFF59E0B);
  final Color _brandBlue = const Color(0xFF3B82F6);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGray = const Color(0xFF6B7280);

  // State Variables
  String _activeFilter = 'all';
  Set<String> _expandedNLP = {};
  Set<String> _selectedReviews = {};
  Map<String, String> _adminNotes = {};
  final Map<String, TextEditingController> _noteControllers = {};
  bool _showHistory = false;
  String? _editingReview;
  String _editedText = '';

  // Mock Data
  late List<FlaggedReview> _flaggedReviews;
  late List<ModerationHistory> _moderationHistory;

  @override
  void initState() {
    super.initState();
    _flaggedReviews = [];
    _moderationHistory = [];
    _fetchFlaggedReviews();
  }

  @override
  void dispose() {
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchFlaggedReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      // DEBUG: log token to browser/console to help diagnose 401 issues
      print('DEBUG: AdminReviewModerationPanel._fetchFlaggedReviews token => $token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/admin/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['flagged_reviews'] as List<dynamic>? ?? [];
        final history = data['moderation_history'] as List<dynamic>? ?? [];
        setState(() {
          _flaggedReviews = items.map((item) {
            final map = item as Map<String, dynamic>;
            return FlaggedReview(
              id: map['id']?.toString() ?? '',
              reviewText: map['review_text'] ?? '',
              rating: map['rating'] ?? 0,
              reviewerName: map['reviewer_name'] ?? '',
              reviewerAccountAge: map['reviewer_account_age'] ?? '',
              reviewerTotalReviews: map['reviewer_total_reviews'] ?? 0,
              restaurantName: map['restaurant_name'] ?? '',
              restaurantId: map['restaurant_id']?.toString() ?? '',
              flagReasonType: map['flag_reason_type'] ?? 'auto',
              flagReasonSource: map['flag_reason_source'] ?? '',
              flagReasonNote: map['flag_reason_note'],
              nlpSentimentScore: (map['nlp_sentiment_score'] ?? 0).toDouble(),
              nlpSentimentLabel: map['nlp_sentiment_label'] ?? 'Neutral',
              nlpDetectedIssues: (map['nlp_detected_issues'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
              nlpConfidenceScore: map['nlp_confidence_score'] ?? 0,
              nlpKeyPhrases: (map['nlp_key_phrases'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
              nlpToxicityScore: map['nlp_toxicity_score'] ?? 0,
              nlpProblematicWords: (map['nlp_problematic_words'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
              submittedDate: map['submitted_date'] ?? '',
              flagCategory: map['flag_category'] ?? 'nlp-auto',
              adminNote: map['admin_note'] ?? '',
            );
          }).toList();

          _moderationHistory = history.map((item) {
            final map = item as Map<String, dynamic>;
            return ModerationHistory(
              id: map['id']?.toString() ?? '',
              reviewId: map['review_id'] ?? '',
              action: map['action'] ?? '',
              admin: map['admin'] ?? '',
              notes: map['notes'] ?? '',
              date: map['date'] ?? '',
            );
          }).toList();
        });
      }
    } catch (_) {
      // Keep empty state if backend is unreachable.
    }
  }

  // --- LOGIC ---

  List<FlaggedReview> get _filteredReviews {
    if (_activeFilter == 'all') return _flaggedReviews;
    return _flaggedReviews.where((r) => r.flagCategory == _activeFilter).toList();
  }

  void _toggleNLPExpanded(String id) {
    setState(() {
      if (_expandedNLP.contains(id)) _expandedNLP.remove(id);
      else _expandedNLP.add(id);
    });
  }

  void _toggleSelectReview(String id) {
    setState(() {
      if (_selectedReviews.contains(id)) _selectedReviews.remove(id);
      else _selectedReviews.add(id);
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedReviews.length == _filteredReviews.length) {
        _selectedReviews.clear();
      } else {
        _selectedReviews = _filteredReviews.map((r) => r.id).toSet();
      }
    });
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendReviewAction(String id, String action, {String? editedText}) async {
    final note = _adminNotes[id];
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
    // DEBUG: log token before sending moderation action
    print('DEBUG: AdminReviewModerationPanel._sendReviewAction token => $token');

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/accounts/admin/reviews/$id/action/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: json.encode({
          'action': action,
          if (editedText != null) 'edited_text': editedText,
          if (note != null && note.isNotEmpty) 'admin_note': note,
        }),
      );

      if (response.statusCode == 200) {
        await _fetchFlaggedReviews();
      }
    } catch (_) {
      // Keep UI state unchanged on error.
    }
  }

  void _handleApprove(String id) {
    _sendReviewAction(id, 'approve');
    _showToast('Review approved');
    setState(() => _selectedReviews.remove(id));
  }

  void _handleRemove(String id) {
    _sendReviewAction(id, 'remove');
    _showToast('Review removed', isError: true);
    setState(() => _selectedReviews.remove(id));
  }

  void _handleEditAndApprove(String id) {
    setState(() {
      _editingReview = id;
      _editedText = _flaggedReviews.firstWhere((r) => r.id == id).reviewText;
    });
  }

  void _handleSaveEdit(String id) {
    _sendReviewAction(id, 'edit', editedText: _editedText);
    _showToast('Review edited and approved');
    setState(() {
      _editingReview = null;
      _editedText = '';
    });
  }

  void _handleBanUser(String id) {
    showDialog(
      context: context,
      builder: (context) {
        final review = _flaggedReviews.firstWhere((r) => r.id == id);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle), child: const Icon(Icons.block, color: Colors.red)),
              const SizedBox(width: 12),
              const Text("Ban User?", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Are you sure you want to ban ${review.reviewerName}? They will no longer be able to submit reviews or reports."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _sendReviewAction(id, 'ban');
                _showToast('User has been banned', isError: true);
              },
              child: const Text("Yes, Ban User", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderStats(),
        const SizedBox(height: 16),
        _buildFilterTabs(),
        const SizedBox(height: 16),
        if (_selectedReviews.isNotEmpty) _buildBatchActionsBar(),
        _buildFlaggedReviewsList(),
        const SizedBox(height: 24),
        _buildModerationHistory(),
      ],
    );
  }

  Widget _buildHeaderStats() {
    int totalFlagged = _flaggedReviews.length;
    int nlpAutoFlagged = _flaggedReviews.where((r) => r.flagCategory == 'nlp-auto').length;
    int manuallyReported = _flaggedReviews.where((r) => r.flagCategory == 'user-reported').length;

    return Row(
      children: [
        _statCard(Icons.flag_outlined, totalFlagged.toString(), "Total Flagged", Colors.red),
        const SizedBox(width: 12),
        _statCard(Icons.psychology_outlined, nlpAutoFlagged.toString(), "NLP Auto-Flagged", Colors.purple),
        const SizedBox(width: 12),
        _statCard(Icons.warning_amber_rounded, manuallyReported.toString(), "User Reported", Colors.amber),
        const SizedBox(width: 12),
        _statCard(Icons.access_time, "N/A", "Avg Process Time", Colors.blue),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.shade600, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.shade900)),
            Text(label, style: TextStyle(fontSize: 11, color: color.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    int totalFlagged = _flaggedReviews.length;
    final tabs = [
      {'id': 'all', 'label': 'All Flagged', 'count': totalFlagged},
      {'id': 'nlp-auto', 'label': 'NLP Auto-Flagged', 'count': _flaggedReviews.where((r) => r.flagCategory == 'nlp-auto').length},
      {'id': 'user-reported', 'label': 'User Reported', 'count': _flaggedReviews.where((r) => r.flagCategory == 'user-reported').length},
      {'id': 'spam', 'label': 'Spam Detected', 'count': _flaggedReviews.where((r) => r.flagCategory == 'spam').length},
      {'id': 'inappropriate', 'label': 'Inappropriate', 'count': _flaggedReviews.where((r) => r.flagCategory == 'inappropriate').length},
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? _brandTeal.withOpacity(0.05) : Colors.transparent,
                  border: Border(bottom: BorderSide(color: isActive ? _brandTeal : Colors.transparent, width: 2)),
                ),
                child: Row(
                  children: [
                    Text(tab['label'] as String, style: TextStyle(color: isActive ? _brandTeal : _textGray, fontSize: 12, fontWeight: FontWeight.w600)),
                    if ((tab['count'] as int) > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: isActive ? _brandTeal : Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                        child: Text("${tab['count']}", style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildBatchActionsBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: _brandTeal.withOpacity(0.1), border: Border.all(color: _brandTeal.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Checkbox(
                value: _selectedReviews.length == _filteredReviews.length,
                onChanged: (_) => _toggleSelectAll(),
                activeColor: _brandTeal,
              ),
              Text("${_selectedReviews.length} review(s) selected", style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  for (final id in _selectedReviews.toList()) {
                    await _sendReviewAction(id, 'approve');
                  }
                  _showToast("${_selectedReviews.length} reviews approved");
                  setState(() => _selectedReviews.clear());
                },
                icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                label: const Text("Batch Approve", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  for (final id in _selectedReviews.toList()) {
                    await _sendReviewAction(id, 'remove');
                  }
                  _showToast("${_selectedReviews.length} reviews removed", isError: true);
                  setState(() => _selectedReviews.clear());
                },
                icon: const Icon(Icons.delete, size: 16),
                label: const Text("Batch Remove"),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: Colors.red.shade200)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFlaggedReviewsList() {
    if (_filteredReviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text("No flagged reviews", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
            Text("You're all caught up.", style: TextStyle(color: _textGray, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      children: _filteredReviews.map((review) {
        final controller = _noteControllers.putIfAbsent(
          review.id,
          () => TextEditingController(text: review.adminNote),
        );
        if (_adminNotes[review.id] == null) {
          _adminNotes[review.id] = review.adminNote;
        }
        bool isNLPExpanded = _expandedNLP.contains(review.id);
        bool isEditing = _editingReview == review.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(value: _selectedReviews.contains(review.id), onChanged: (_) => _toggleSelectReview(review.id), activeColor: _brandTeal),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(review.reviewerName, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 14)),
                            Text(review.submittedDate, style: TextStyle(color: _textGray, fontSize: 12)),
                          ],
                        ),
                        Text("Account age: ${review.reviewerAccountAge} • ${review.reviewerTotalReviews} reviews", style: TextStyle(color: _textGray, fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(review.restaurantName, style: TextStyle(color: _brandTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                            Row(children: List.generate(5, (index) => Icon(index < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 14))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Review Text
              if (isEditing)
                TextField(
                  controller: TextEditingController(text: _editedText)..selection = TextSelection.collapsed(offset: _editedText.length),
                  onChanged: (val) => _editedText = val,
                  maxLines: 4,
                  decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                )
              else
                RichText(
                  text: TextSpan(children: _buildHighlightedText(review.reviewText, review.nlpProblematicWords)),
                ),
              const SizedBox(height: 16),

              // Flag Reason Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: review.flagReasonType == 'auto' ? _brandPurple.withOpacity(0.05) : _brandAmber.withOpacity(0.05),
                  border: Border.all(color: review.flagReasonType == 'auto' ? _brandPurple.withOpacity(0.2) : _brandAmber.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(review.flagReasonType == 'auto' ? Icons.psychology : Icons.flag, size: 16, color: review.flagReasonType == 'auto' ? _brandPurple : _brandAmber),
                        const SizedBox(width: 8),
                        Text(
                          "${review.flagReasonType == 'auto' ? 'Auto-Flagged by' : 'Manually Reported by'} ${review.flagReasonSource}",
                          style: TextStyle(color: review.flagReasonType == 'auto' ? Colors.purple.shade700 : Colors.amber.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    if (review.flagReasonNote != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(review.flagReasonNote!, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      )
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // NLP Accordion
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _toggleNLPExpanded(review.id),
                      borderRadius: isNLPExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [_brandPurple.withOpacity(0.05), _brandBlue.withOpacity(0.05)]),
                          borderRadius: isNLPExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.psychology, size: 18, color: _brandPurple),
                                const SizedBox(width: 8),
                                const Text("NLP Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: _brandPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Text("${review.nlpConfidenceScore}% confidence", style: TextStyle(color: _brandPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                            Icon(isNLPExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    if (isNLPExpanded)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sentiment Score Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Sentiment Score", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(
                                  review.nlpSentimentScore.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: review.nlpSentimentScore.abs() < 0.15
                                        ? _textGray
                                        : (review.nlpSentimentScore > 0 ? _brandTeal : Colors.red),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildSentimentGradientBar(review.nlpSentimentScore),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("-1.0 (Negative)", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                Text("0.0", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                Text("+1.0 (Positive)", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            const Text("Sentiment Label", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: review.nlpSentimentLabel == 'Negative' ? Colors.red.shade50 : (review.nlpSentimentLabel == 'Positive' ? Colors.green.shade50 : Colors.amber.shade50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                review.nlpSentimentLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: review.nlpSentimentLabel == 'Negative'
                                      ? Colors.red
                                      : (review.nlpSentimentLabel == 'Positive' ? _brandTeal : Colors.amber.shade700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (review.nlpDetectedIssues.isNotEmpty) ...[
                              const Text("Detected Issues", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: review.nlpDetectedIssues.map((issue) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                                      const SizedBox(width: 4),
                                      Text(issue, style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Confidence Score", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text("${review.nlpConfidenceScore}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: review.nlpConfidenceScore / 100, backgroundColor: Colors.grey.shade200, color: _brandTeal, minHeight: 8),
                            ),
                            const SizedBox(height: 16),

                            if (review.nlpKeyPhrases.isNotEmpty) ...[
                              const Text("Key Phrases Extracted", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: review.nlpKeyPhrases.map((phrase) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(12)),
                                  child: Text(phrase, style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                                )).toList(),
                              ),
                              const SizedBox(height: 16),
                            ],

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Toxicity Score", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text("${review.nlpToxicityScore}/100", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: review.nlpToxicityScore >= 70 ? Colors.red : (review.nlpToxicityScore >= 40 ? Colors.amber : _brandTeal))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: review.nlpToxicityScore / 100, 
                                backgroundColor: Colors.grey.shade200, 
                                color: review.nlpToxicityScore >= 70 ? Colors.red : (review.nlpToxicityScore >= 40 ? Colors.amber : _brandTeal), 
                                minHeight: 8
                              ),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Admin Notes
              const Text("Admin Notes (Internal)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                onChanged: (val) => _adminNotes[review.id] = val,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Add internal notes about this review...",
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              if (isEditing)
                Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(onPressed: () => _handleSaveEdit(review.id), icon: const Icon(Icons.check_circle, size: 16, color: Colors.white), label: const Text("Save & Approve", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => _editingReview = null), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text("Cancel"))),
                  ],
                )
              else
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    ElevatedButton.icon(onPressed: () => _handleApprove(review.id), icon: const Icon(Icons.check_circle, size: 16, color: Colors.white), label: const Text("Approve", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                    OutlinedButton.icon(onPressed: () => _handleRemove(review.id), icon: const Icon(Icons.delete, size: 16), label: const Text("Remove"), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                    OutlinedButton.icon(onPressed: () => _handleEditAndApprove(review.id), icon: const Icon(Icons.edit, size: 16), label: const Text("Edit"), style: OutlinedButton.styleFrom(foregroundColor: Colors.amber.shade700, side: BorderSide(color: Colors.amber.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                    OutlinedButton.icon(onPressed: () => _handleBanUser(review.id), icon: const Icon(Icons.block, size: 16), label: const Text("Ban User"), style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade500), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                    OutlinedButton.icon(onPressed: () { _sendReviewAction(review.id, 'dismiss'); _showToast("Flag dismissed"); }, icon: const Icon(Icons.shield_outlined, size: 16), label: const Text("Dismiss Flag"), style: OutlinedButton.styleFrom(foregroundColor: _textDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
                  ],
                )
            ],
          ),
        );
      }).toList(),
    );
  }

  // Parses review text to apply highlight styles to problematic words
  List<TextSpan> _buildHighlightedText(String text, List<String> badWords) {
    TextStyle defaultStyle = TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5);
    TextStyle highlightStyle = TextStyle(
      backgroundColor: Colors.red.shade100,
      color: Colors.red.shade700,
      decoration: TextDecoration.underline,
      decorationColor: Colors.red.shade500,
      fontSize: 13,
      height: 1.5,
    );

    if (badWords.isEmpty) return [TextSpan(text: text, style: defaultStyle)];

    String pattern = badWords.map((w) => RegExp.escape(w)).join('|');
    RegExp regex = RegExp('($pattern)', caseSensitive: false);
    List<TextSpan> spans = [];

    text.splitMapJoin(regex,
      onMatch: (m) {
        spans.add(TextSpan(text: m.group(0), style: highlightStyle));
        return '';
      },
      onNonMatch: (n) {
        spans.add(TextSpan(text: n, style: defaultStyle));
        return '';
      }
    );
    return spans;
  }

  Widget _buildSentimentGradientBar(double score) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double percent = (score + 1) / 2; // Map -1.0 -> 1.0 to 0.0 -> 1.0
        return Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: const LinearGradient(colors: [Colors.red, Colors.grey, Colors.green]),
          ),
          child: Stack(
            children: [
              Positioned(
                left: (constraints.maxWidth * percent) - 2, // -2 to center the 4px wide marker
                top: 0, bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 1), borderRadius: BorderRadius.circular(2)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildModerationHistory() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showHistory = !_showHistory),
            borderRadius: _showHistory ? const BorderRadius.vertical(top: Radius.circular(20)) : BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline, color: _textGray, size: 20),
                      const SizedBox(width: 8),
                      Text("Moderation History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
                        child: Text("${_moderationHistory.length}", style: TextStyle(fontSize: 11, color: _textDark, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  Icon(_showHistory ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: _textGray),
                ],
              ),
            ),
          ),
          if (_showHistory && _moderationHistory.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Text("No moderation history yet", style: TextStyle(color: _textGray, fontSize: 12)),
            )
          else if (_showHistory)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                  dataRowMaxHeight: 60,
                  columns: const [
                    DataColumn(label: Text("Date", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    DataColumn(label: Text("Rev iew ID", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    DataColumn(label: Text("Action", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    DataColumn(label: Text("Admin", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    DataColumn(label: Text("Notes", style: TextStyle(fontSize: 12, color: Colors.grey))),
                  ],
                  rows: _moderationHistory.map((h) {
                    Color actionBg, actionText;
                    if (h.action == 'Approved') { actionBg = Colors.green.shade50; actionText = _brandTeal; }
                    else if (h.action == 'Removed' || h.action == 'User Banned') { actionBg = Colors.red.shade50; actionText = Colors.red.shade700; }
                    else { actionBg = Colors.grey.shade100; actionText = _textGray; }

                    return DataRow(cells: [
                      DataCell(Text(h.date, style: TextStyle(fontSize: 12, color: _textDark))),
                      DataCell(Text(h.reviewId, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: actionBg, borderRadius: BorderRadius.circular(8)),
                        child: Text(h.action, style: TextStyle(fontSize: 11, color: actionText, fontWeight: FontWeight.bold)),
                      )),
                      DataCell(Text(h.admin, style: TextStyle(fontSize: 12, color: _textDark))),
                      DataCell(SizedBox(width: 150, child: Text(h.notes, style: TextStyle(fontSize: 12, color: _textGray), maxLines: 2, overflow: TextOverflow.ellipsis))),
                    ]);
                  }).toList(),
                ),
              ),
            )
        ],
      ),
    );
  }
}