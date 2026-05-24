import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic> _summary = {'total': 0, 'submitted': 0, 'reviewed': 0, 'resolved': 0};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _reports = [];
          _error = 'Sign in to view your reports.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.46:8000/api/accounts/profile/reports/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _reports = [];
          _error = 'Failed to load reports (${response.statusCode}).';
        });
        return;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> results = (body['results'] as List<dynamic>? ?? <dynamic>[]);
      setState(() {
        _reports = results.map((e) => e as Map<String, dynamic>).toList(growable: false);
        _summary = (body['summary'] as Map<String, dynamic>? ?? {'total': 0, 'submitted': 0, 'reviewed': 0, 'resolved': 0});
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _reports = [];
        _error = 'Unable to load your reports right now.';
      });
    }
  }

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
          children: [
            Text("My Reports",
                style: TextStyle(
                    color: Color(0xFF323F4B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text("${_summary['total'] ?? 0} hygiene reports",
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Status Summary Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatusChip(label: "Total", count: (_summary['total'] as num?)?.toInt() ?? 0, color: Colors.grey),
                  _StatusChip(label: "Submitted", count: (_summary['submitted'] as num?)?.toInt() ?? 0, color: Colors.orange, bgColor: const Color(0xFFFFF7ED)),
                  _StatusChip(label: "Reviewed", count: (_summary['reviewed'] as num?)?.toInt() ?? 0, color: Colors.blue, bgColor: const Color(0xFFEFF6FF)),
                  _StatusChip(label: "Resolved", count: (_summary['resolved'] as num?)?.toInt() ?? 0, color: const Color(0xFF10B981), bgColor: const Color(0xFFECFDF5)),
                ],
              ),
            ),
          ),

          // 2. Reports List
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _fetchReports, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_reports.isEmpty) {
      return const Center(child: Text('No reports submitted yet.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          final status = (report['status'] as String?) ?? 'submitted';
          final statusData = _statusView(status);
          final category = (report['category_display'] as String?) ?? 'Issue';
          final time = (report['time_since'] as String?) ?? 'recently';
          final restaurant = (report['restaurant_name'] as String?) ?? 'Restaurant';
          final description = (report['description'] as String?) ?? '';
          final statusLabel = (report['status_display'] as String?) ?? status;

          return ReportCard(
            restaurant: restaurant,
            category: category,
            time: time,
            description: description,
            status: statusLabel,
            statusColor: statusData.color,
            dotColor: statusData.dotColor,
            icon: statusData.icon,
            resolutionText: status == 'resolved'
                ? 'This issue has been marked as resolved. Thank you for reporting hygiene concerns.'
                : null,
          );
        },
      ),
    );
  }

  _StatusViewData _statusView(String status) {
    switch (status) {
      case 'resolved':
        return const _StatusViewData(icon: Icons.check_circle_outline, color: Color(0xFF10B981), dotColor: Colors.green);
      case 'reviewed':
        return const _StatusViewData(icon: Icons.visibility_outlined, color: Colors.blue, dotColor: Colors.blue);
      default:
        return const _StatusViewData(icon: Icons.access_time, color: Colors.orange, dotColor: Colors.orange);
    }
  }
}

class _StatusViewData {
  final IconData icon;
  final Color color;
  final Color dotColor;

  const _StatusViewData({required this.icon, required this.color, required this.dotColor});
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
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
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
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
