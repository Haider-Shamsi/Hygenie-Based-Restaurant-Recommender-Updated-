import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- SCREEN WIDGET ---

class OwnerAnalyticsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const OwnerAnalyticsScreen({super.key, required this.onBack});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  // Theme Colors
  final Color _brandTeal = const Color(0xFF10B981);
  final Color _bgGray = const Color(0xFFF9FBFB);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGray = const Color(0xFF6B7280);

  // State
  String _selectedPeriod = '30d';
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _analyticsData = {};

  // --- UI OPTIONS ---
  final List<Map<String, String>> _timePeriods = [
    {'id': '7d', 'label': '7 Days'},
    {'id': '30d', 'label': '30 Days'},
    {'id': '90d', 'label': '90 Days'},
    {'id': '12m', 'label': '12 Months'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('http://192.168.1.46:8000/api/accounts/owner/analytics/?period=$_selectedPeriod'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load analytics.';
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

  List<Map<String, dynamic>> get _hygieneBreakdown =>
      (_analyticsData['hygiene_breakdown'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _sentimentData =>
      (_analyticsData['sentiment'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

  List<FlSpot> get _reviewsOverTime {
    final points = (_analyticsData['reviews_over_time'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return points.map((p) => FlSpot((p['x'] ?? 0).toDouble(), (p['y'] ?? 0).toDouble())).toList();
  }

  List<Map<String, dynamic>> get _topKeywords =>
      (_analyticsData['top_keywords'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get _inspectionHistory =>
      (_analyticsData['inspection_history'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)), onPressed: widget.onBack),
        title: const Text("Analytics", style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Column(
            children: [
              _buildTimePeriodSelector(),
              Container(color: Colors.grey.shade200, height: 1.0),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildKeyMetricsGrid(),
            const SizedBox(height: 16),
            _buildRadarChartCard(),
            const SizedBox(height: 16),
            _buildSentimentCard(),
            const SizedBox(height: 16),
            _buildAreaChartCard(),
            const SizedBox(height: 16),
            _buildKeywordsCard(),
            const SizedBox(height: 16),
            _buildInspectionHistoryCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: _timePeriods.map((period) {
            bool isSelected = _selectedPeriod == period['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedPeriod = period['id']!);
                  _fetchAnalytics();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    period['label']!,
                    style: TextStyle(
                      color: isSelected ? _brandTeal : _textGray,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildKeyMetricsGrid() {
    final keyMetrics = _analyticsData['key_metrics'] as Map<String, dynamic>? ?? {};
    final reviewsReceived = keyMetrics['reviews_received']?.toString() ?? '0';
    final avgHygieneScore = keyMetrics['avg_hygiene_score']?.toString() ?? '0';
    final customerSatisfaction = keyMetrics['customer_satisfaction']?.toString() ?? '0';
    final reportsFiled = keyMetrics['reports_filed']?.toString() ?? '0';
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard("Reviews Received", reviewsReceived, "", true),
        _buildMetricCard("Avg Hygiene Score", avgHygieneScore, "", true),
        _buildMetricCard("Customer Satisfaction", "$customerSatisfaction%", "", true, percentage: int.tryParse(customerSatisfaction) ?? 0),
        _buildMetricCard("Reports Filed", reportsFiled, "", true),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String trend, bool isPositive, {List<FlSpot>? sparklineData, int? percentage}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: _textGray)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
              if (sparklineData != null)
                SizedBox(
                  width: 60, height: 24,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(spots: sparklineData, isCurved: true, color: _brandTeal, barWidth: 2, dotData: const FlDotData(show: false)),
                      ],
                    ),
                  ),
                ),
              if (percentage != null)
                SizedBox(
                  width: 40, height: 40,
                  child: Stack(
                    children: [
                      Center(child: CircularProgressIndicator(value: percentage / 100, color: _brandTeal, backgroundColor: Colors.grey.shade200, strokeWidth: 4)),
                      Center(child: Text("$percentage%", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _brandTeal))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 14, color: isPositive ? _brandTeal : Colors.red),
              const SizedBox(width: 4),
              Text(trend, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPositive ? _brandTeal : Colors.red)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRadarChartCard() {
    if (_hygieneBreakdown.isEmpty) {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hygiene Score Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
            const SizedBox(height: 16),
            Text("No data available", style: TextStyle(color: _textGray)),
          ],
        ),
      );
    }
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hygiene Score Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.15,
                titleTextStyle: TextStyle(color: _textGray, fontSize: 10),
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                gridBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
                tickBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
                getTitle: (index, angle) {
                  return RadarChartTitle(text: _hygieneBreakdown[index]['category']);
                },
                dataSets: [
                  RadarDataSet(
                    dataEntries: _hygieneBreakdown.map((e) => RadarEntry(value: e['score'])).toList(),
                    fillColor: _brandTeal.withOpacity(0.5),
                    borderColor: _brandTeal,
                    borderWidth: 2,
                    entryRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentCard() {
    if (_sentimentData.isEmpty) {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Review Sentiment Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
            const SizedBox(height: 16),
            Text("No data available", style: TextStyle(color: _textGray)),
          ],
        ),
      );
    }
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Review Sentiment Analysis", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
              Row(children: [const Icon(Icons.auto_awesome, size: 14, color: Colors.grey), const SizedBox(width: 4), Text("NLP Analysis", style: TextStyle(color: _textGray, fontSize: 11))]),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 140, width: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _sentimentData.map((e) {
                      final color = _sentimentColor(e['name']);
                      return PieChartSectionData(
                        value: e['value'],
                        color: color,
                        radius: 30,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _sentimentData.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _sentimentColor(e['name']))),
                              const SizedBox(width: 8),
                              Text(e['name'], style: TextStyle(color: _textDark, fontSize: 13)),
                            ],
                          ),
                          Row(
                            children: [
                              Text("${e['percentage']}%", style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 13)),
                              const SizedBox(width: 4),
                              Text("(${e['value'].toInt()})", style: TextStyle(color: _textGray, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChartCard() {
    if (_reviewsOverTime.isEmpty) {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reviews Over Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
            const SizedBox(height: 16),
            Text("No data available", style: TextStyle(color: _textGray)),
          ],
        ),
      );
    }
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Reviews Over Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1, dashArray: [4, 4])),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Week ${value.toInt() + 1}", style: TextStyle(color: _textGray, fontSize: 11)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        if (value % 4 == 0) return Text(value.toInt().toString(), style: TextStyle(color: _textGray, fontSize: 11));
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: _reviewsOverTime,
                    isCurved: true,
                    color: _brandTeal,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [_brandTeal.withOpacity(0.4), _brandTeal.withOpacity(0.0)],
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

  Color _sentimentColor(String? name) {
    switch (name?.toLowerCase()) {
      case 'positive':
        return const Color(0xFF10B981);
      case 'neutral':
        return const Color(0xFF9CA3AF);
      case 'negative':
        return const Color(0xFFEF4444);
      case 'mixed':
        return const Color(0xFFF59E0B);
      default:
        return _brandTeal;
    }
  }

  Widget _buildKeywordsCard() {
    if (_topKeywords.isEmpty) {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Top Keywords", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
            const SizedBox(height: 16),
            Text("No data available", style: TextStyle(color: _textGray)),
          ],
        ),
      );
    }
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Top Keywords from Reviews", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
              Row(children: [const Icon(Icons.auto_awesome, size: 14, color: Colors.grey), const SizedBox(width: 4), Text("NLP-Extracted", style: TextStyle(color: _textGray, fontSize: 11))]),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _topKeywords.map((keyword) {
              bool isPos = keyword['sentiment'] == 'positive';
              double size = math.min(12 + (keyword['count'] as int) / 5, 20).toDouble();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPos ? _brandTeal.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(keyword['word'], style: TextStyle(color: isPos ? _brandTeal : Colors.red, fontWeight: FontWeight.bold, fontSize: size)),
                    const SizedBox(width: 4),
                    Text("(${keyword['count']})", style: TextStyle(color: isPos ? _brandTeal.withOpacity(0.7) : Colors.red.withOpacity(0.7), fontSize: size * 0.7)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(children: [Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981))), const SizedBox(width: 6), Text("Positive", style: TextStyle(color: _textGray, fontSize: 12))]),
              const SizedBox(width: 16),
              Row(children: [Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444))), const SizedBox(width: 6), Text("Negative", style: TextStyle(color: _textGray, fontSize: 12))]),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInspectionHistoryCard() {
    if (_inspectionHistory.isEmpty) {
      return _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Inspection History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
            const SizedBox(height: 16),
            Text("No data available", style: TextStyle(color: _textGray)),
          ],
        ),
      );
    }
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Inspection History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2.5),
              2: IntrinsicColumnWidth(),
              3: IntrinsicColumnWidth(),
              4: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                children: ["Date", "Inspector", "Score", "Status", "Actions"].map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(e, style: TextStyle(color: _textGray, fontSize: 11, fontWeight: FontWeight.bold), textAlign: e == "Score" || e == "Status" ? TextAlign.center : (e == "Actions" ? TextAlign.right : TextAlign.left)),
                  );
                }).toList(),
              ),
              ..._inspectionHistory.asMap().entries.map((entry) {
                int index = entry.key;
                var data = entry.value;
                bool isWarning = data['color'] == 'amber';
                return TableRow(
                  decoration: BoxDecoration(color: index % 2 == 0 ? Colors.transparent : _bgGray),
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(data['date'], style: TextStyle(fontSize: 12, color: _textDark))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(data['inspector'], style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text("${data['score']}", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark))),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: isWarning ? Colors.orange.withOpacity(0.1) : _brandTeal.withOpacity(0.1), border: Border.all(color: isWarning ? Colors.orange.withOpacity(0.3) : _brandTeal.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                          child: Text(data['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isWarning ? Colors.orange.shade700 : _brandTeal)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: InkWell(
                        onTap: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text("View Details", style: TextStyle(color: _brandTeal, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 2),
                            Icon(Icons.open_in_new, color: _brandTeal, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          )
        ],
      ),
    );
  }
}
