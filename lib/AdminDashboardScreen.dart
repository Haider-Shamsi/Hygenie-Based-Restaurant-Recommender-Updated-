import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'AdminRestaurantsPanel.dart';
import 'AdminReviewModerationPanel.dart';
import 'AdminReportsPanel.dart';
import 'sign_in_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AdminDashboardScreen({super.key, required this.onBack});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Theme Colors
  final Color _bgGray = const Color(0xFFF9FBFB);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGray = const Color(0xFF6B7280);
  final Color _brandTeal = const Color(0xFF10B981);
  final Color _brandBlue = const Color(0xFF3B82F6);
  final Color _brandPurple = const Color(0xFF8B5CF6);
  final Color _brandAmber = const Color(0xFFF59E0B);
  final Color _brandRed = const Color(0xFFEF4444);

  // State Variables
  String _activeTab = 'overview'; // 'overview', 'restaurants', 'reports', 'reviews', 'nlp'
  bool _showNLPScreen = false;
  bool _showSentimentDashboard = false;

  // NLP & Sentiment Dashboard State Variables
  Map<String, dynamic>? _nlpSummary;
  bool _isLoadingNLPSummary = false;

  // Real-time prediction sandbox state variables
  final TextEditingController _nlpPredictController = TextEditingController();
  Map<String, dynamic>? _nlpPredictResult;
  bool _isNLPPredicting = false;
  String? _nlpPredictError;

  Future<void> _fetchNLPSummary() async {
    if (mounted) {
      setState(() {
        _isLoadingNLPSummary = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/admin/nlp/summary/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _nlpSummary = data;
          _isLoadingNLPSummary = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingNLPSummary = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingNLPSummary = false;
      });
    }
  }

  Future<void> _runNLPRealtimePredict() async {
    final text = _nlpPredictController.text.trim();
    if (text.isEmpty) return;

    if (mounted) {
      setState(() {
        _isNLPPredicting = true;
        _nlpPredictResult = null;
        _nlpPredictError = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/accounts/admin/nlp/predict/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
        body: json.encode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _nlpPredictResult = data;
          _isNLPPredicting = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _nlpPredictError = 'Failed to analyze text.';
          _isNLPPredicting = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nlpPredictError = 'Unable to reach the server.';
        _isNLPPredicting = false;
      });
    }
  }

  // Bottom Nav index mapping
  int get _bottomNavIndex {
    switch (_activeTab) {
      case 'overview': return 0;
      case 'restaurants': return 1;
      case 'reviews': return 2;
      case 'nlp': return 3;
      default: return 0;
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _showNLPScreen = false;
      _showSentimentDashboard = false;
      switch (index) {
        case 0: _activeTab = 'overview'; break;
        case 1: _activeTab = 'restaurants'; break;
        case 2: _activeTab = 'reviews'; break;
        case 3: 
          _activeTab = 'nlp'; 
          _fetchNLPSummary();
          break;
      }
    });
  }

  // --- DATA (populated via backend integration) ---
  List<Map<String, dynamic>> _topStats = [];
  List<Map<String, dynamic>> _scoreDistribution = [];
  List<Map<String, dynamic>> _reportsTrend = [];
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAdminOverview();
    _fetchNLPSummary();
  }

  Future<void> _fetchAdminOverview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/admin/overview/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _topStats = _buildTopStats(data['top_stats']);
          _scoreDistribution = _buildScoreDistribution(data['score_distribution']);
          _reportsTrend = _buildReportsTrend(data['reports_trend']);
          _recentActivity = _buildRecentActivity(data['recent_activity']);
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to load admin overview.';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to reach the server.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildTopStats(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      final key = (map['key'] ?? '').toString();
      final trend = (map['trend'] ?? '').toString();
      final isPositive = trend.startsWith('+');
      final highlight = key == 'pending_reports' || key == 'flagged_reviews';
      final highlightColor = key == 'pending_reports' ? 'red' : 'amber';

      IconData icon = Icons.insights_rounded;
      if (key == 'total_restaurants') icon = Icons.storage_rounded;
      if (key == 'total_users') icon = Icons.people_outline_rounded;
      if (key == 'avg_hygiene') icon = Icons.star_outline_rounded;
      if (key == 'pending_reports') icon = Icons.warning_amber_rounded;
      if (key == 'flagged_reviews') icon = Icons.chat_bubble_outline_rounded;

      return {
        'icon': icon,
        'label': map['label'] ?? key,
        'value': map['value']?.toString() ?? '0',
        'subtext': trend.isEmpty ? 'No change' : trend,
        'isPositive': isPositive,
        'highlight': highlight,
        'highlightColor': highlight ? highlightColor : null,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildScoreDistribution(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      final range = (map['range'] ?? '').toString();
      return {
        'range': range,
        'count': map['count'] ?? 0,
        'color': _scoreColor(range),
      };
    }).toList();
  }

  Color _scoreColor(String range) {
    switch (range) {
      case '0-20': return const Color(0xFFDC2626);
      case '21-40': return const Color(0xFFF97316);
      case '41-60': return const Color(0xFFF59E0B);
      case '61-80': return const Color(0xFF84CC16);
      case '81-100': return const Color(0xFF10B981);
      default: return _brandTeal;
    }
  }

  List<Map<String, dynamic>> _buildReportsTrend(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      return {
        'month': map['month'] ?? '',
        'total': (map['total'] ?? 0).toDouble(),
        'resolved': (map['resolved'] ?? 0).toDouble(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildRecentActivity(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      final type = (map['type'] ?? '').toString();
      return {
        'icon': _activityIcon(type),
        'text': map['text'] ?? 'Activity update',
        'time': _formatShortDate(map['time']?.toString()),
        'color': _activityColor(type),
      };
    }).toList();
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'report': return Icons.warning_amber_rounded;
      case 'review': return Icons.chat_bubble_outline_rounded;
      case 'inspection_request': return Icons.check_circle_outline_rounded;
      default: return Icons.notifications_none;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'report': return Colors.red;
      case 'review': return Colors.amber;
      case 'inspection_request': return Colors.green;
      default: return Colors.blue;
    }
  }

  String _formatShortDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'just now';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return 'just now';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[parsed.month - 1];
    return '$month ${parsed.day}';
  }

  // --- UI BUILDERS ---

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _bottomNavIndex,
      selectedItemColor: _brandPurple,
      unselectedItemColor: _textGray,
      showUnselectedLabels: true,
      onTap: _onBottomNavTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          label: 'Restaurants',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          label: 'Moderation',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.psychology_rounded),
          label: 'NLP',
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    try {
      await http.post(
        Uri.parse('${Config.baseUrl}/api/accounts/logout/'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      // Ignore network errors for logout
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted && navigator.mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out? You'll need to sign in again to access your account."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handling placeholder full-screen states
    if (_showNLPScreen) {
      return _buildNLPScreenWidget();
    }

    if (_showSentimentDashboard) {
      return _buildSentimentDashboardScreenWidget();
    }

    return Scaffold(
      backgroundColor: _bgGray,
      appBar: _buildAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: _brandTeal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
              title: const Text('Switch to customer'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                widget.onBack(); // Switch to customer
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined, color: Colors.orange),
              title: const Text('Report an Issue'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // TODO: Navigate to report issue screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                _showLogoutDialog();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTopStatsBar(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabs(),
                  const SizedBox(height: 24),
                  _buildTabContent(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: _textDark), // Ensures drawer icon is dark
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Admin Dashboard", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
          Text("System Overview & Management", style: TextStyle(color: _textGray, fontSize: 12, fontWeight: FontWeight.normal)),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_brandPurple.withOpacity(0.1), _brandBlue.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _brandPurple.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Text("NLP Model Active", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 12),
                        Text("Updated: Not available", style: TextStyle(fontSize: 11, color: _textGray)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.show_chart_rounded, size: 14, color: _brandPurple),
                        const SizedBox(width: 4),
                        const Text("Queue: 0", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Container(color: Colors.grey.shade200, height: 1.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatsBar() {
    if (_topStats.isEmpty) {
      return _buildEmptyStateBar("No stats available", "Connect admin analytics to see system metrics.");
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: _topStats.map((stat) {
            bool highlight = stat['highlight'];
            Color highlightColor = stat['highlightColor'] == 'red' ? _brandRed : _brandAmber;
            Color bgColor = highlight ? highlightColor.withOpacity(0.05) : Colors.white;
            Color borderColor = highlight ? highlightColor.withOpacity(0.3) : Colors.grey.shade200;
            Color iconColor = highlight ? highlightColor : _textGray;

            return Container(
              width: 180,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(stat['icon'], size: 20, color: iconColor),
                      if (stat['isPositive']) Icon(Icons.trending_up, size: 16, color: _brandTeal),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(stat['value'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
                  Text(stat['label'], style: TextStyle(fontSize: 12, color: _textGray)),
                  const SizedBox(height: 4),
                  Text(
                    stat['subtext'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: highlight ? highlightColor : (stat['isPositive'] ? _brandTeal : _textGray),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'id': 'overview', 'label': 'Overview'},
      {'id': 'restaurants', 'label': 'Restaurants'},
      {'id': 'reports', 'label': 'Reports'},
      {'id': 'reviews', 'label': 'Reviews'},
      {'id': 'nlp', 'label': 'NLP'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            bool isActive = _activeTab == tab['id'];
            return GestureDetector(
              onTap: () => setState(() => _activeTab = tab['id']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? _brandTeal.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab['label']!,
                  style: TextStyle(
                    color: isActive ? _brandTeal : _textGray,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'overview':
        return Column(
          children: [
            _buildBarChartCard(),
            const SizedBox(height: 16),
            _buildLineChartCard(),
            const SizedBox(height: 16),
            _buildRecentActivityCard(),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(),
          ],
        );
      case 'restaurants':
        return const AdminRestaurantsPanel();
      case 'reviews':
        return const AdminReviewModerationPanel();
      case 'reports':
        return const AdminReportsPanel();
      case 'nlp':
        return _buildNLPAnalysisCenter();
      default:
        // Placeholder for Restaurants, Reports, Reviews tabs
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              Icon(Icons.construction, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text("${_activeTab.toUpperCase()} Panel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
              const Text("Component integrated via separate panel file.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        );
    }
  }

  // --- OVERVIEW TAB WIDGETS ---

  Widget _buildBarChartCard() {
    if (_scoreDistribution.isEmpty) {
      return _buildCard(
        title: "Hygiene Score Distribution",
        child: _buildEmptyMessage("No hygiene score data available yet."),
      );
    }

    return _buildCard(
      title: "Hygiene Score Distribution",
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [4, 4])),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value >= 0 && value < _scoreDistribution.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(_scoreDistribution[value.toInt()]['range'], style: TextStyle(color: _textGray, fontSize: 11)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text("Restaurants", style: TextStyle(color: _textGray, fontSize: 11)),
                sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: _textGray, fontSize: 11))),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _scoreDistribution.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> data = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: data['count'].toDouble(),
                    color: data['color'],
                    width: 24,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChartCard() {
    if (_reportsTrend.isEmpty) {
      return _buildCard(
        title: "Reports Trend (Last 6 Months)",
        child: _buildEmptyMessage("No report trend data available yet."),
      );
    }

    return _buildCard(
      title: "Reports Trend (Last 6 Months)",
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [4, 4])),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < _reportsTrend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(_reportsTrend[value.toInt()]['month'], style: TextStyle(color: _textGray, fontSize: 11)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: _textGray, fontSize: 11))),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: _reportsTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['total'])).toList(),
                    isCurved: true,
                    color: _brandBlue,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 6,
                        color: _brandBlue,
                        strokeWidth: 0,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: _reportsTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['resolved'])).toList(),
                    isCurved: true,
                    color: _brandTeal,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3.5,
                        color: _brandTeal,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _brandBlue)), const SizedBox(width: 6), Text("Total Reports", style: TextStyle(color: _textGray, fontSize: 12))]),
              const SizedBox(width: 16),
              Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _brandTeal)), const SizedBox(width: 6), Text("Resolved Reports", style: TextStyle(color: _textGray, fontSize: 12))]),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    if (_recentActivity.isEmpty) {
      return _buildCard(
        title: "Recent Activity",
        child: _buildEmptyMessage("No recent activity to display."),
      );
    }

    return _buildCard(
      title: "Recent Activity",
      child: Column(
        children: _recentActivity.map((activity) {
          Color color = activity['color'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(activity['icon'], color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activity['text'], style: TextStyle(fontSize: 13, color: _textDark, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(activity['time'], style: TextStyle(fontSize: 11, color: _textGray)),
                    ],
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildActionTile("Moderate Reviews", "Review flagged content", Icons.chat_bubble_outline_rounded, _brandTeal, () => setState(() => _activeTab = 'reviews')),
        _buildActionTile("Manage Reports", "Handle hygiene reports", Icons.warning_amber_rounded, _brandRed, () => setState(() => _activeTab = 'reports')),
        _buildActionTile("View Restaurants", "Browse all restaurants", Icons.storage_rounded, _brandBlue, () => setState(() => _activeTab = 'restaurants')),
        _buildActionTile("NLP Analysis", "View sentiment insights", Icons.psychology_rounded, _brandPurple, () => setState(() => _showNLPScreen = true)),
      ],
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textDark)),
            Text(subtitle, style: TextStyle(fontSize: 10, color: _textGray)),
          ],
        ),
      ),
    );
  }

  // --- NLP TAB SPECIFIC ---

  Widget _buildNLPAnalysisCenter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Icon(Icons.psychology_rounded, size: 64, color: _brandPurple),
          const SizedBox(height: 16),
          Text("NLP Analysis Center", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 8),
          Text("Advanced sentiment analysis and keyword extraction", style: TextStyle(color: _textGray, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _brandPurple.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandPurple.withOpacity(0.2))),
                  child: Column(
                    children: [
                      Text(_nlpSummary != null ? "${_nlpSummary!['model_accuracy']}%" : "87.5%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple.shade900)),
                      Text("Model Accuracy", style: TextStyle(fontSize: 11, color: Colors.purple.shade700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _brandBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: _brandBlue.withOpacity(0.2))),
                  child: Column(
                    children: [
                      Text(_nlpSummary != null ? _nlpSummary!['total_reviews_analyzed'].toString() : "0", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      Text("Reviews Analyzed", style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showNLPScreen = true),
              icon: const Icon(Icons.psychology_rounded, size: 18, color: Colors.white),
              label: const Text("Open Analysis Center", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: _brandPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showSentimentDashboard = true),
              icon: Icon(Icons.bar_chart_rounded, size: 18, color: _textDark),
              label: Text("Sentiment Dashboard", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(message, style: TextStyle(color: _textGray, fontSize: 13)),
    );
  }

  Widget _buildEmptyStateBar(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: _textGray)),
        ],
      ),
    );
  }

  Widget _buildNLPScreenWidget() {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AI NLP Predictor Sandbox", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Real-time sentiment model analysis", style: TextStyle(color: _textGray, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => setState(() => _showNLPScreen = false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sandbox input container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _brandPurple.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.psychology_rounded, color: _brandPurple, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text("Enter Review / Feedback to Test", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _nlpPredictController,
                      maxLines: 4,
                      style: TextStyle(fontSize: 14, color: _textDark),
                      decoration: const InputDecoration(
                        hintText: "E.g., The food was absolutely delicious and the service was amazing! Or: I found a cockroach under the table and the toilet was very dirty...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isNLPPredicting ? null : _runNLPRealtimePredict,
                      icon: _isNLPPredicting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.analytics_rounded, size: 18, color: Colors.white),
                      label: Text(_isNLPPredicting ? "Analyzing..." : "Analyze Sentiment", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Prediction results card
            if (_nlpPredictResult != null) ...[
              Text("Prediction Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text("Sentiment:", style: TextStyle(color: _textGray, fontSize: 14)),
                            const SizedBox(width: 8),
                            _buildSentimentBadge(_nlpPredictResult!['sentiment_label']),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: _brandPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text("${_nlpPredictResult!['confidence_score']}% Confidence", style: TextStyle(color: _brandPurple, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    
                    // Toxicity Score Bar
                    Text("Toxicity & Language Risk", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (_nlpPredictResult!['toxicity_score'] as int) / 100.0,
                              minHeight: 10,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (_nlpPredictResult!['toxicity_score'] as int) > 50 ? _brandRed : _brandAmber,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text("${_nlpPredictResult!['toxicity_score']}%", style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 14)),
                      ],
                    ),
                    const Divider(height: 32),
                    
                    // Auto-Detected issues
                    Text("Auto-Detected Issues", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_nlpPredictResult!['detected_issues'] as List<dynamic>).map((issue) {
                        return Chip(
                          label: Text(issue.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: _brandRed.withOpacity(0.05),
                          labelStyle: TextStyle(color: _brandRed),
                          side: BorderSide(color: _brandRed.withOpacity(0.2)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),

                    // Key phrases
                    Text("Key Phrases Extracted", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_nlpPredictResult!['key_phrases'] as List<dynamic>).map((phrase) {
                        return Chip(
                          label: Text(phrase.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: _brandBlue.withOpacity(0.05),
                          labelStyle: TextStyle(color: _brandBlue),
                          side: BorderSide(color: _brandBlue.withOpacity(0.2)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ] else if (_nlpPredictError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade100)),
                child: Text(_nlpPredictError!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                  children: [
                    Icon(Icons.psychology_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text("Sandbox Ready", style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 15)),
                    Text("Write a hypothetical customer comment to test real-time predictions.", style: TextStyle(color: _textGray, fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSentimentBadge(String label) {
    Color bg;
    Color fg;
    IconData icon;
    if (label == 'Positive') {
      bg = _brandTeal.withOpacity(0.1);
      fg = _brandTeal;
      icon = Icons.sentiment_satisfied_alt_rounded;
    } else if (label == 'Negative') {
      bg = _brandRed.withOpacity(0.1);
      fg = _brandRed;
      icon = Icons.sentiment_very_dissatisfied_rounded;
    } else {
      bg = _brandAmber.withOpacity(0.1);
      fg = _brandAmber;
      icon = Icons.sentiment_neutral_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSentimentDashboardScreenWidget() {
    final summary = _nlpSummary;
    final distribution = summary != null ? (summary['sentiment_distribution'] as Map<String, dynamic>) : null;
    final total = distribution != null ? (distribution['positive'] + distribution['negative'] + distribution['neutral']) : 0;
    
    final positivePercent = total > 0 ? (distribution!['positive'] / total * 100).round() : 0;
    final negativePercent = total > 0 ? (distribution!['negative'] / total * 100).round() : 0;
    final neutralPercent = total > 0 ? (distribution!['neutral'] / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sentiment Dashboard", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Aggregate system sentiment analytics", style: TextStyle(color: _textGray, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => setState(() => _showSentimentDashboard = false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Sentiment Distribution card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _brandTeal.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.pie_chart_rounded, color: _brandTeal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text("Overall Sentiment Breakdown", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Triple Linear Bar Chart
                  if (total > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 24,
                        width: double.infinity,
                        child: Row(
                          children: [
                            if (positivePercent > 0)
                              Expanded(flex: positivePercent, child: Container(color: _brandTeal, alignment: Alignment.center, child: Text("$positivePercent%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                            if (neutralPercent > 0)
                              Expanded(flex: neutralPercent, child: Container(color: _brandAmber, alignment: Alignment.center, child: Text("$neutralPercent%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                            if (negativePercent > 0)
                              Expanded(flex: negativePercent, child: Container(color: _brandRed, alignment: Alignment.center, child: Text("$negativePercent%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem("Positive", distribution!['positive'].toString(), _brandTeal),
                        _buildLegendItem("Neutral", distribution['neutral'].toString(), _brandAmber),
                        _buildLegendItem("Negative", distribution['negative'].toString(), _brandRed),
                      ],
                    ),
                  ] else ...[
                    Center(child: Text("No data available yet.", style: TextStyle(color: _textGray, fontSize: 13))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Key Words Frequency cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Highly Praised Words", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textDark)),
                        const SizedBox(height: 12),
                        if (summary != null && summary['top_positive_words'] != null)
                          ...((summary['top_positive_words'] as List<dynamic>).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _brandTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                    child: Text(item['word'].toString(), style: TextStyle(color: _brandTeal, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                                  Text(item['count'].toString(), style: TextStyle(color: _textGray, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList())
                        else
                          Text("None", style: TextStyle(color: _textGray, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Most Complained Words", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textDark)),
                        const SizedBox(height: 12),
                        if (summary != null && summary['top_negative_words'] != null)
                          ...((summary['top_negative_words'] as List<dynamic>).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _brandRed.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                    child: Text(item['word'].toString(), style: TextStyle(color: _brandRed, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                                  Text(item['count'].toString(), style: TextStyle(color: _textGray, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList())
                        else
                          Text("None", style: TextStyle(color: _textGray, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Model Metadata Specification
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("NLP Model Specifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                  const Divider(height: 24),
                  _buildSpecRow("Model Name", summary != null ? summary['model_name'].toString() : "SVM / TF-IDF Classifier"),
                  _buildSpecRow("Accuracy Rating", summary != null ? "${summary['model_accuracy']}%" : "87.5%"),
                  _buildSpecRow("Status", summary != null ? summary['model_status'].toString() : "Active"),
                  _buildSpecRow("Last Trained", summary != null ? summary['last_trained'].toString() : "2026-05-23"),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: _textGray, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _textGray, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 13)),
        ],
      ),
    );
  }
}