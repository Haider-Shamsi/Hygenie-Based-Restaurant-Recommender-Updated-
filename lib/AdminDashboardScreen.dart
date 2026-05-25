import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'AdminRestaurantsPanel.dart';
import 'AdminReviewModerationPanel.dart';
import 'AdminReportsPanel.dart';

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
        case 3: _activeTab = 'nlp'; break;
      }
    });
  }

  // --- MOCK DATA ---
  final List<Map<String, dynamic>> _topStats = [
    {
      'icon': Icons.storage_rounded, 'label': 'Total Restaurants', 'value': '248', 
      'subtext': '+12 this month', 'isPositive': true, 'highlight': false,
    },
    {
      'icon': Icons.people_outline_rounded, 'label': 'Total Users', 'value': '1,847', 
      'subtext': '+15.2% growth', 'isPositive': true, 'highlight': false,
    },
    {
      'icon': Icons.star_outline_rounded, 'label': 'Avg Hygiene Score', 'value': '82.5', 
      'subtext': '+2.3 pts', 'isPositive': true, 'highlight': false,
    },
    {
      'icon': Icons.warning_amber_rounded, 'label': 'Pending Reports', 'value': '14', 
      'subtext': 'Needs attention', 'isPositive': false, 'highlight': true, 'highlightColor': 'red',
    },
    {
      'icon': Icons.chat_bubble_outline_rounded, 'label': 'Flagged Reviews', 'value': '7', 
      'subtext': 'Awaiting moderation', 'isPositive': false, 'highlight': true, 'highlightColor': 'amber',
    },
  ];

  final List<Map<String, dynamic>> _scoreDistribution = [
    {'range': '0-20', 'count': 8, 'color': const Color(0xFFDC2626)},
    {'range': '21-40', 'count': 15, 'color': const Color(0xFFF97316)},
    {'range': '41-60', 'count': 32, 'color': const Color(0xFFF59E0B)},
    {'range': '61-80', 'count': 78, 'color': const Color(0xFF84CC16)},
    {'range': '81-100', 'count': 115, 'color': const Color(0xFF10B981)},
  ];

  final List<Map<String, dynamic>> _reportsTrend = [
    {'month': 'Jul', 'total': 45.0, 'resolved': 38.0},
    {'month': 'Aug', 'total': 52.0, 'resolved': 45.0},
    {'month': 'Sep', 'total': 48.0, 'resolved': 41.0},
    {'month': 'Oct', 'total': 58.0, 'resolved': 52.0},
    {'month': 'Nov', 'total': 61.0, 'resolved': 55.0},
    {'month': 'Dec', 'total': 54.0, 'resolved': 48.0},
  ];

  final List<Map<String, dynamic>> _recentActivity = [
    {'icon': Icons.warning_amber_rounded, 'text': 'New hygiene report filed for "Dragon Wok"', 'time': '5 min ago', 'color': Colors.red},
    {'icon': Icons.chat_bubble_outline_rounded, 'text': 'Review flagged for moderation at "Pizza Palace"', 'time': '12 min ago', 'color': Colors.amber},
    {'icon': Icons.storage_rounded, 'text': 'New restaurant "Sushi Bar" added to system', 'time': '1 hour ago', 'color': Colors.green},
    {'icon': Icons.check_circle_outline_rounded, 'text': 'Inspection completed for "Burger Joint" - Score: 95', 'time': '2 hours ago', 'color': Colors.green},
    {'icon': Icons.people_outline_rounded, 'text': '5 new users registered', 'time': '3 hours ago', 'color': Colors.blue},
    {'icon': Icons.psychology_rounded, 'text': 'NLP analysis completed for 42 reviews', 'time': '4 hours ago', 'color': Colors.purple},
    {'icon': Icons.check_circle_outline_rounded, 'text': 'Report resolved for "Taco Stand"', 'time': '5 hours ago', 'color': Colors.green},
    {'icon': Icons.star_outline_rounded, 'text': 'Owner responded to review at "Cafe Mocha"', 'time': '6 hours ago', 'color': Colors.orange},
    {'icon': Icons.cancel_outlined, 'text': 'Restaurant "Old Diner" marked as closed', 'time': '8 hours ago', 'color': Colors.grey},
    {'icon': Icons.refresh_rounded, 'text': 'Daily database backup completed', 'time': '12 hours ago', 'color': Colors.blue},
  ];

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

  @override
  Widget build(BuildContext context) {
    // Handling placeholder full-screen states
    if (_showNLPScreen) {
      return Scaffold(
        appBar: AppBar(title: const Text("NLP Analysis Center")),
        body: Center(
          child: ElevatedButton(onPressed: () => setState(() => _showNLPScreen = false), child: const Text("Back to Dashboard")),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      );
    }

    if (_showSentimentDashboard) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sentiment Dashboard")),
        body: Center(
          child: ElevatedButton(onPressed: () => setState(() => _showSentimentDashboard = false), child: const Text("Back to Dashboard")),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      );
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
                // TODO: Handle logout logic
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTopStatsBar(),
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
                        Text("Updated: 2 hours ago", style: TextStyle(fontSize: 11, color: _textGray)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.show_chart_rounded, size: 14, color: _brandPurple),
                        const SizedBox(width: 4),
                        const Text("Queue: 8", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _reportsTrend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['resolved'])).toList(),
                    isCurved: true,
                    color: _brandTeal,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
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
                      Text("94.2%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple.shade900)),
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
                      Text("3,847", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
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
}