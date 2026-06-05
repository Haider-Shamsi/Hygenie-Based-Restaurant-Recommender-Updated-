import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'OwnerRestaurantManageScreen.dart';
import 'OwnerReviewsManagementScreen.dart';
import 'OwnerAnalyticsScreen.dart';
import 'config.dart';
import 'OwnerHygieneReportsScreen.dart';


// ============================================================================
// 1. DATA MODELS (Mapped to Django Serializers)
// ============================================================================

class OwnerDashboardData {
  final String restaurantName;
  final String lastInspectionDate;
  final double hygieneScore;
  final int totalReviews;
  final String reviewTrend;
  final double averageRating;
  final int monthlyVisitors;
  final String visitorTrend;
  final List<HygieneDataPoint> hygieneTrend;
  final List<ActivityItem> recentActivities;

  OwnerDashboardData({
    required this.restaurantName,
    required this.lastInspectionDate,
    required this.hygieneScore,
    required this.totalReviews,
    required this.reviewTrend,
    required this.averageRating,
    required this.monthlyVisitors,
    required this.visitorTrend,
    required this.hygieneTrend,
    required this.recentActivities,
  });

  factory OwnerDashboardData.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardData(
      restaurantName: json['restaurant_name'] ?? 'Unknown',
      lastInspectionDate: json['last_inspection_date'] ?? 'N/A',
      hygieneScore: (json['hygiene_score'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      reviewTrend: json['review_trend'] ?? '+0%',
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      monthlyVisitors: json['monthly_visitors'] ?? 0,
      visitorTrend: json['visitor_trend'] ?? '+0%',
      hygieneTrend: (json['hygiene_trend'] as List<dynamic>?)
              ?.map((e) => HygieneDataPoint.fromJson(e))
              .toList() ??
          [],
      recentActivities: (json['recent_activities'] as List<dynamic>?)
              ?.map((e) => ActivityItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class HygieneDataPoint {
  final String month;
  final double score;

  HygieneDataPoint({required this.month, required this.score});

  factory HygieneDataPoint.fromJson(Map<String, dynamic> json) {
    return HygieneDataPoint(
      month: json['month'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
    );
  }
}

class ActivityItem {
  final String type; // 'review', 'report', 'inspection'
  final String description;
  final String timeAgo;

  ActivityItem({required this.type, required this.description, required this.timeAgo});

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: json['type'] ?? 'info',
      description: json['description'] ?? '',
      timeAgo: json['time_ago'] ?? '',
    );
  }
}

// ============================================================================
// 2. STATEFUL WIDGET & UI
// ============================================================================

class OwnerDashboardScreen extends StatefulWidget {
  final VoidCallback onBack;
  const OwnerDashboardScreen({super.key, required this.onBack});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  OwnerDashboardData? _dashboardData;
  int _selectedIndex = 0;
  bool _isRequestingInspection = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Theme Colors matching the React Tailwind classes
  final Color _brandTeal = const Color(0xFF10B981);
  final Color _bgGray = const Color(0xFFF9FBFB);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGray = const Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // --- DJANGO API INTEGRATION ---
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Replace with your actual Django endpoint
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/owner/dashboard/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        setState(() {
          _dashboardData = OwnerDashboardData.fromJson(jsonData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load dashboard data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to reach the server.';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestInspection() async {
    if (_isRequestingInspection) return;
    setState(() => _isRequestingInspection = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/accounts/owner/inspection-requests/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final message = body['detail'] ?? 'Inspection request submitted.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: _brandTeal),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit inspection request.'), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to reach the server.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isRequestingInspection = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildDashboardContent(),
      OwnerReviewsManagementScreen(onBack: () => _onItemTapped(0)),
      OwnerAnalyticsScreen(onBack: () => _onItemTapped(0)),
      OwnerHygieneReportsScreen(onBack: () => _onItemTapped(0)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: _brandTeal,
        unselectedItemColor: _textGray,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Owner Dashboard", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
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
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text('Owner Menu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _brandTeal));
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: _fetchDashboardData, child: const Text("Retry"))
          ],
        ),
      );
    }

    final data = _dashboardData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(data),
          const SizedBox(height: 20),
          _buildQuickStats(data),
          const SizedBox(height: 20),
          _buildTrendChart(data),
          const SizedBox(height: 20),
          _buildRecentActivity(data),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- 1. Header Card ---
  Widget _buildHeaderCard(OwnerDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data.restaurantName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, color: _brandTeal, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Last inspection: ${data.lastInspectionDate}", style: TextStyle(color: _textGray, fontSize: 13)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OwnerRestaurantManageScreen(
                          onBack: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text("Edit Restaurant"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              ],
            ),
          ),
          _buildCircularGauge(data.hygieneScore),
        ],
      ),
    );
  }

  Widget _buildCircularGauge(double score) {
    return Column(
      children: [
        SizedBox(
          width: 80, height: 80,
          child: Stack(
            children: [
              Center(child: CustomPaint(size: const Size(80, 80), painter: _GaugePainter(score: score, color: _brandTeal))),
              Center(child: Text("${score.toInt()}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _brandTeal))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text("Hygiene Score", style: TextStyle(fontSize: 11, color: _textGray)),
      ],
    );
  }

  // --- 2. Quick Stats Row ---
  Widget _buildQuickStats(OwnerDashboardData data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _statCard("Total Reviews", data.totalReviews.toString(), data.reviewTrend, Icons.chat_bubble_outline, Colors.blue),
          _statCard("Average Rating", data.averageRating.toString(), "★", Icons.star_outline, Colors.orange),
          _statCard("Hygiene Score", data.hygieneScore.toInt().toString(), "Excellent", Icons.verified_user_outlined, _brandTeal),
        ],
      ),
    );
  }

  Widget _statCard(String title, String val, String trend, IconData icon, Color color) {
    bool isPositive = trend.startsWith('+') || trend == 'Excellent';
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: _textGray)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
              if (trend == "★") 
                const Icon(Icons.star, color: Colors.amber, size: 16)
              else
                Row(
                  children: [
                    if (trend.startsWith('+') || trend.startsWith('-'))
                      Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 14, color: isPositive ? _brandTeal : Colors.red),
                    const SizedBox(width: 2),
                    Text(trend, style: TextStyle(fontSize: 11, color: isPositive ? _brandTeal : Colors.red, fontWeight: FontWeight.bold)),
                  ],
                )
            ],
          )
        ],
      ),
    );
  }

  // --- 3. Line Chart ---
  Widget _buildTrendChart(OwnerDashboardData data) {
    List<FlSpot> spots = data.hygieneTrend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.score);
    }).toList();

    if (spots.isEmpty) {
      spots = [const FlSpot(0, 0)];
    } else if (spots.length == 1) {
      spots = [FlSpot(0.0, spots[0].y), FlSpot(1.0, spots[0].y)];
    }


    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hygiene Score Trend", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
          const SizedBox(height: 4),
          Text("Last 12 months performance", style: TextStyle(color: _textGray, fontSize: 13)),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < data.hygieneTrend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(data.hygieneTrend[value.toInt()].month, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 25 || value == 50 || value == 75 || value == 100) {
                          return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0, maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: _brandTeal,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => CircleButtPainter(color: _brandTeal, strokeWidth: 2, strokeColor: Colors.white, radius: 4),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [_brandTeal.withOpacity(0.2), _brandTeal.withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Recent Activity ---
  Widget _buildRecentActivity(OwnerDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...data.recentActivities.map((activity) {
            Color color;
            IconData icon;
            String btnText;

            if (activity.type == 'review') {
              color = Colors.blue; icon = Icons.chat_bubble_outline; btnText = "Respond";
            } else if (activity.type == 'report') {
              color = Colors.red; icon = Icons.warning_amber_rounded; btnText = "View";
            } else {
              color = _brandTeal; icon = Icons.check_circle_outline; btnText = "Details";
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity.description, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
                          Text(activity.timeAgo, style: TextStyle(fontSize: 11, color: _textGray)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        if (activity.type == 'review') {
                          _onItemTapped(1);
                        } else if (activity.type == 'report') {
                          _onItemTapped(3);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(btnText, style: TextStyle(fontSize: 11, color: _textDark)),
                    )
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 5. Quick Actions Grid ---
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _actionBtn("View All Reviews", Icons.chat_bubble_outline, Colors.blue, () {
            _onItemTapped(1);
          }),
          _actionBtn("View Hygiene Reports", Icons.report_problem_outlined, Colors.red, () {
            _onItemTapped(3);
          }),
          _actionBtn("Update Restaurant Info", Icons.settings_outlined, Colors.grey.shade700, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerRestaurantManageScreen(onBack: () => Navigator.pop(context))));
          }),
          _actionBtn("View Analytics", Icons.bar_chart, Colors.purple, () {
            _onItemTapped(2);
          }),
          _actionBtn("Request Inspection", Icons.assignment_turned_in_outlined, _brandTeal, () {
            _requestInspection();
          }),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _bgGray, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: Colors.transparent)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _textDark)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. UTILITY COMPONENTS
// ============================================================================

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;
  _GaugePainter({required this.score, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    Paint base = Paint()..color = Colors.grey[200]!..style = PaintingStyle.stroke..strokeWidth = 8;
    Paint progress = Paint()..color = color..strokeCap = StrokeCap.round..style = PaintingStyle.stroke..strokeWidth = 8;
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = math.min(size.width / 2, size.height / 2);
    
    // Draw background track
    canvas.drawCircle(center, radius, base);
    
    // Draw progress arc (Starts at top: -pi/2)
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * (score / 100), false, progress);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CircleButtPainter extends FlDotPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final Color strokeColor;

  CircleButtPainter({required this.color, required this.radius, required this.strokeWidth, required this.strokeColor});

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    canvas.drawCircle(offsetInCanvas, radius, Paint()..color = strokeColor);
    canvas.drawCircle(offsetInCanvas, radius - strokeWidth, Paint()..color = color);
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  @override
  List<Object?> get props => [color, radius, strokeWidth, strokeColor];

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    // If both are CircleButtPainter, interpolate their properties
    if (a is CircleButtPainter && b is CircleButtPainter) {
      Color interpColor = Color.lerp(a.color, b.color, t) ?? color;
      Color interpStroke = Color.lerp(a.strokeColor, b.strokeColor, t) ?? strokeColor;
      double interpRadius = a.radius + (b.radius - a.radius) * t;
      double interpStrokeWidth = a.strokeWidth + (b.strokeWidth - a.strokeWidth) * t;
      return CircleButtPainter(
        color: interpColor,
        radius: interpRadius,
        strokeWidth: interpStrokeWidth,
        strokeColor: interpStroke,
      );
    }

    // Fallback: return this painter
    return this;
  }
}
