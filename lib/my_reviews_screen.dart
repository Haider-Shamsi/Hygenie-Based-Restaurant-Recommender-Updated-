import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _myReviews = [];
  final Set<int> _deletingIds = <int>{};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyReviews();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchMyReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _myReviews = [];
          _error = 'Sign in to view your reviews.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/profile/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _myReviews = [];
          _error = 'Failed to load reviews (${response.statusCode}).';
        });
        return;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> results = (body['results'] as List<dynamic>? ?? <dynamic>[]);
      setState(() {
        _myReviews = results.map((e) => e as Map<String, dynamic>).toList(growable: false);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _myReviews = [];
        _error = 'Unable to load your reviews right now.';
      });
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    if (_deletingIds.contains(reviewId)) return;

    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to delete reviews.')),
      );
      return;
    }

    setState(() {
      _deletingIds.add(reviewId);
    });

    try {
      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/api/accounts/profile/reviews/$reviewId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 204) {
        setState(() {
          _myReviews = _myReviews.where((r) => (r['id'] as num?)?.toInt() != reviewId).toList(growable: false);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete review (${response.statusCode}).')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete review. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(reviewId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF323F4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Reviews",
                style: TextStyle(color: Color(0xFF323F4B), fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${_myReviews.length} reviews",
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: _myReviews.isEmpty
          ? (_isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: _fetchMyReviews, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _buildEmptyState()))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _myReviews.length,
              itemBuilder: (context, index) {
                return _ReviewCard(
                  review: _myReviews[index],
                  isDeleting: _deletingIds.contains((_myReviews[index]['id'] as num?)?.toInt() ?? -1),
                  onDelete: () {
                    final id = (_myReviews[index]['id'] as num?)?.toInt();
                    if (id == null) return;
                    _showDeleteDialog(id);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No Reviews Yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Start reviewing to help others!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _ReviewCard({required this.review, required this.isDeleting, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    //bool isPublished = review['status'] == "Published";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['restaurant_name'] ?? 'Restaurant',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF323F4B))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(review['time_since'] ?? 'recently', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge('Published'),
            ],
          ),
          const SizedBox(height: 16),

          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < ((review['rating'] as num?)?.toInt() ?? 0) ? Icons.star : Icons.star_border,
                color: index < ((review['rating'] as num?)?.toInt() ?? 0) ? const Color(0xFFFBBF24) : Colors.grey[300],
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 12),

          // Comment
          Text(
            (review['comment'] as String?) ?? '',
            style: const TextStyle(color: Color(0xFF4A5568), height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text("Edit"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4A5568),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isDeleting ? null : onDelete,
                  icon: isDeleting
                      ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_outline, size: 16),
                  label: Text(isDeleting ? 'Deleting' : 'Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Color(0xFFFEE2E2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isPublished = status == "Published";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isPublished ? const Color(0xFF059669) : const Color(0xFFD97706),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

}

extension on _MyReviewsScreenState {
  void _showDeleteDialog(int reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Delete Review?"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(reviewId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
