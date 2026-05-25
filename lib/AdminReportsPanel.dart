import 'package:flutter/material.dart';

// --- DATA MODELS ---

class Reporter {
  final String name;
  final bool isAnonymous;
  final String? email;
  final String? phone;

  Reporter({required this.name, required this.isAnonymous, this.email, this.phone});
}

class RestaurantSummary {
  final String name;
  final String id;
  final int currentScore;

  RestaurantSummary({required this.name, required this.id, required this.currentScore});
}

class NLPAnalysis {
  final String severityAssessment; // 'Critical', 'Major', 'Minor'
  final int confidenceScore;
  final List<String> autoFlags;

  NLPAnalysis({required this.severityAssessment, required this.confidenceScore, required this.autoFlags});
}

class TimelineEvent {
  final String status;
  final String timestamp;
  final String admin;

  TimelineEvent({required this.status, required this.timestamp, required this.admin});
}

class AdminReport {
  final String id;
  final String reportId;
  final String submittedDate;
  final Reporter reporter;
  final RestaurantSummary restaurant;
  final String issueType; // 'food-safety', 'cleanliness', 'staff-hygiene', 'pest-control', 'other'
  final String priority; // 'high', 'medium', 'low'
  String status; // 'pending', 'investigating', 'resolved', 'dismissed'
  final String description;
  final List<String> photos;
  final NLPAnalysis nlpAnalysis;
  final List<TimelineEvent> timeline;

  AdminReport({
    required this.id,
    required this.reportId,
    required this.submittedDate,
    required this.reporter,
    required this.restaurant,
    required this.issueType,
    required this.priority,
    required this.status,
    required this.description,
    required this.photos,
    required this.nlpAnalysis,
    required this.timeline,
  });
}

// --- WIDGET ---

class AdminReportsPanel extends StatefulWidget {
  const AdminReportsPanel({super.key});

  @override
  State<AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<AdminReportsPanel> {
  // Theme Colors
  final Color _brandTeal = const Color(0xFF10B981);
  final Color _brandRed = const Color(0xFFEF4444);
  final Color _brandAmber = const Color(0xFFF59E0B);
  final Color _brandBlue = const Color(0xFF3B82F6);
  final Color _brandPurple = const Color(0xFF8B5CF6);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGray = const Color(0xFF6B7280);

  // State Variables
  String _activeTab = 'all'; // 'all', 'pending', 'investigating', 'resolved'
  String _searchQuery = '';
  String _filterPriority = 'all';
  String _filterCategory = 'all';
  String _sortBy = 'newest';
  final Set<String> _expandedReports = {};

  late List<AdminReport> _allReports;

  @override
  void initState() {
    super.initState();
    _allReports = [
      AdminReport(
        id: '1',
        reportId: 'RPT-2025-089',
        submittedDate: '10 mins ago',
        reporter: Reporter(name: 'Sarah Mitchell', isAnonymous: false, email: 'sarah.m@example.com', phone: '(555) 123-4567'),
        restaurant: RestaurantSummary(name: 'Dragon Wok', id: 'rest-1', currentScore: 95),
        issueType: 'food-safety',
        priority: 'high',
        status: 'pending',
        description: 'Observed raw chicken being stored on the top shelf above fresh vegetables in the walk-in cooler. This is a severe cross-contamination risk.',
        photos: ['https://images.unsplash.com/photo-1583394838336-acd977736f90?w=400'],
        nlpAnalysis: NLPAnalysis(
          severityAssessment: 'Critical',
          confidenceScore: 94,
          autoFlags: ['Cross-contamination', 'Raw meat storage', 'Health code violation'],
        ),
        timeline: [
          TimelineEvent(status: 'Report Submitted', timestamp: 'Dec 10, 2025 14:30', admin: 'System'),
        ],
      ),
      AdminReport(
        id: '2',
        reportId: 'RPT-2025-088',
        submittedDate: '2 hours ago',
        reporter: Reporter(name: 'Anonymous Customer', isAnonymous: true),
        restaurant: RestaurantSummary(name: 'Pizza Palace', id: 'rest-2', currentScore: 88),
        issueType: 'cleanliness',
        priority: 'medium',
        status: 'investigating',
        description: 'The bathrooms were extremely dirty, no paper towels, and the trash cans were overflowing into the dining area hallway.',
        photos: [],
        nlpAnalysis: NLPAnalysis(
          severityAssessment: 'Major',
          confidenceScore: 88,
          autoFlags: ['Restroom sanitation', 'Waste management'],
        ),
        timeline: [
          TimelineEvent(status: 'Investigation Started', timestamp: 'Dec 10, 2025 13:15', admin: 'Admin John'),
          TimelineEvent(status: 'Report Submitted', timestamp: 'Dec 10, 2025 12:30', admin: 'System'),
        ],
      ),
      AdminReport(
        id: '3',
        reportId: 'RPT-2025-087',
        submittedDate: '1 day ago',
        reporter: Reporter(name: 'David Park', isAnonymous: false, email: 'david.p@example.com'),
        restaurant: RestaurantSummary(name: 'Sushi Bar', id: 'rest-4', currentScore: 91),
        issueType: 'staff-hygiene',
        priority: 'low',
        status: 'resolved',
        description: 'A server was wearing a strong perfume that affected the dining experience. Not a major health issue but poor practice.',
        photos: [],
        nlpAnalysis: NLPAnalysis(
          severityAssessment: 'Minor',
          confidenceScore: 75,
          autoFlags: ['Staff conduct', 'Allergen risk (fragrance)'],
        ),
        timeline: [
          TimelineEvent(status: 'Resolved - Warning sent to owner', timestamp: 'Dec 10, 2025 09:00', admin: 'Admin Sarah'),
          TimelineEvent(status: 'Investigation Started', timestamp: 'Dec 9, 2025 15:20', admin: 'Admin Sarah'),
          TimelineEvent(status: 'Report Submitted', timestamp: 'Dec 9, 2025 14:10', admin: 'System'),
        ],
      ),
    ];
  }

  // --- LOGIC ---

  List<AdminReport> get _filteredAndSortedReports {
    var filtered = _allReports.where((r) {
      bool matchesTab = _activeTab == 'all' || r.status == _activeTab;
      bool matchesSearch = _searchQuery.isEmpty ||
          r.reportId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.reporter.name.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesPriority = _filterPriority == 'all' || r.priority == _filterPriority;
      bool matchesCategory = _filterCategory == 'all' || r.issueType == _filterCategory;
      return matchesTab && matchesSearch && matchesPriority && matchesCategory;
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'newest') return b.submittedDate.compareTo(a.submittedDate);
      if (_sortBy == 'oldest') return a.submittedDate.compareTo(b.submittedDate);
      if (_sortBy == 'severity') {
        const pOrder = {'high': 0, 'medium': 1, 'low': 2};
        return (pOrder[a.priority] ?? 3).compareTo(pOrder[b.priority] ?? 3);
      }
      return 0;
    });

    return filtered;
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedReports.contains(id)) _expandedReports.remove(id);
      else _expandedReports.add(id);
    });
  }

  void _updateStatus(String id, String newStatus) {
    setState(() {
      final report = _allReports.firstWhere((r) => r.id == id);
      report.status = newStatus;
      report.timeline.insert(0, TimelineEvent(
        status: newStatus == 'investigating' ? 'Investigation Started' : 'Status changed to $newStatus',
        timestamp: 'Just now',
        admin: 'Current Admin'
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report $newStatus successfully'), backgroundColor: _brandTeal));
  }

  void _showImageLightbox(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, fit: BoxFit.contain))),
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STYLING HELPERS ---

  Map<String, dynamic> _getPriorityStyles(String priority) {
    switch (priority) {
      case 'high': return {'color': _brandRed, 'bg': _brandRed.withOpacity(0.1), 'label': 'High Priority'};
      case 'medium': return {'color': _brandAmber, 'bg': _brandAmber.withOpacity(0.1), 'label': 'Medium Priority'};
      case 'low': return {'color': _brandBlue, 'bg': _brandBlue.withOpacity(0.1), 'label': 'Low Priority'};
      default: return {'color': _textGray, 'bg': Colors.grey.shade100, 'label': 'Unknown'};
    }
  }

  Map<String, dynamic> _getStatusStyles(String status) {
    switch (status) {
      case 'pending': return {'color': _brandAmber, 'bg': Colors.white, 'border': _brandAmber, 'icon': Icons.access_time};
      case 'investigating': return {'color': _brandBlue, 'bg': _brandBlue.withOpacity(0.1), 'border': _brandBlue, 'icon': Icons.search};
      case 'resolved': return {'color': _brandTeal, 'bg': _brandTeal.withOpacity(0.1), 'border': _brandTeal, 'icon': Icons.check_circle_outline};
      case 'dismissed': return {'color': _textGray, 'bg': Colors.grey.shade100, 'border': _textGray, 'icon': Icons.cancel_outlined};
      default: return {'color': _textGray, 'bg': Colors.grey.shade100, 'border': Colors.transparent, 'icon': Icons.info_outline};
    }
  }

  String _formatIssueType(String type) {
    return type.split('-').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsHeader(),
        const SizedBox(height: 24),
        _buildTabs(),
        const SizedBox(height: 16),
        _buildFilterBar(),
        const SizedBox(height: 16),
        _buildReportsList(),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Row(
      children: [
        _statCard("Total Reports", _allReports.length.toString(), Icons.folder_open, _brandBlue, "+12%"),
        const SizedBox(width: 12),
        _statCard("Critical Issues", _allReports.where((r) => r.priority == 'high').length.toString(), Icons.warning_amber_rounded, _brandRed, "+2"),
        const SizedBox(width: 12),
        _statCard("Pending Review", _allReports.where((r) => r.status == 'pending').length.toString(), Icons.access_time, _brandAmber, "-5"),
        const SizedBox(width: 12),
        _statCard("Avg Resolution", "2.4h", Icons.timer_outlined, _brandTeal, "-15m"),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String trend) {
    bool isPositiveTrend = trend.startsWith('-') && title != "Pending Review" || trend.startsWith('+') && title == "Total Reports";
    if (title == "Pending Review" || title == "Avg Resolution") isPositiveTrend = trend.startsWith('-');
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Row(
                  children: [
                    Icon(isPositiveTrend ? Icons.trending_down : Icons.trending_up, size: 14, color: isPositiveTrend ? _brandTeal : _brandRed),
                    const SizedBox(width: 2),
                    Text(trend, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPositiveTrend ? _brandTeal : _brandRed)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
            Text(title, style: TextStyle(fontSize: 11, color: _textGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'id': 'all', 'label': 'All Reports'},
      {'id': 'pending', 'label': 'Pending'},
      {'id': 'investigating', 'label': 'Investigating'},
      {'id': 'resolved', 'label': 'Resolved'},
    ];

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            bool isActive = _activeTab == tab['id'];
            return InkWell(
              onTap: () => setState(() => _activeTab = tab['id']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isActive ? _brandTeal : Colors.transparent, width: 2)),
                ),
                child: Text(
                  tab['label']!,
                  style: TextStyle(color: isActive ? _brandTeal : _textGray, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Search
        Container(
          width: 250,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: "Search reports...",
              prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
              isDense: true,
            ),
          ),
        ),
        // Priority Filter
        _buildDropdown(
          value: _filterPriority,
          items: const [
            DropdownMenuItem(value: 'all', child: Text("All Priorities")),
            DropdownMenuItem(value: 'high', child: Text("High Priority")),
            DropdownMenuItem(value: 'medium', child: Text("Medium Priority")),
            DropdownMenuItem(value: 'low', child: Text("Low Priority")),
          ],
          onChanged: (val) => setState(() => _filterPriority = val!),
        ),
        // Category Filter
        _buildDropdown(
          value: _filterCategory,
          items: const [
            DropdownMenuItem(value: 'all', child: Text("All Categories")),
            DropdownMenuItem(value: 'food-safety', child: Text("Food Safety")),
            DropdownMenuItem(value: 'cleanliness', child: Text("Cleanliness")),
            DropdownMenuItem(value: 'staff-hygiene', child: Text("Staff Hygiene")),
            DropdownMenuItem(value: 'pest-control', child: Text("Pest Control")),
          ],
          onChanged: (val) => setState(() => _filterCategory = val!),
        ),
        // Sort
        _buildDropdown(
          value: _sortBy,
          items: const [
            DropdownMenuItem(value: 'newest', child: Text("Newest First")),
            DropdownMenuItem(value: 'oldest', child: Text("Oldest First")),
            DropdownMenuItem(value: 'severity', child: Text("Highest Severity")),
          ],
          onChanged: (val) => setState(() => _sortBy = val!),
        ),
        // Export/Notify
        OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.download, size: 16), label: const Text("Export"), style: OutlinedButton.styleFrom(foregroundColor: _textDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      ],
    );
  }

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          style: TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w500),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReportsList() {
    final reports = _filteredAndSortedReports;
    if (reports.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No reports found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
            const Text("Try adjusting your filters", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: reports.map((report) => _buildReportCard(report)).toList(),
    );
  }

  Widget _buildReportCard(AdminReport report) {
    bool isExpanded = _expandedReports.contains(report.id);
    final pStyle = _getPriorityStyles(report.priority);
    final sStyle = _getStatusStyles(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info (Always visible)
          InkWell(
            onTap: () => _toggleExpand(report.id),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                    child: Icon(report.reporter.isAnonymous ? Icons.masks : Icons.person, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(report.reporter.name, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 14)),
                            Text(report.submittedDate, style: TextStyle(color: _textGray, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(report.reportId, style: TextStyle(color: _textGray, fontSize: 12)),
                            const SizedBox(width: 8),
                            Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                            const SizedBox(width: 8),
                            Text(report.restaurant.name, style: TextStyle(color: _brandTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: pStyle['bg'], borderRadius: BorderRadius.circular(12)),
                              child: Text(pStyle['label'], style: TextStyle(color: pStyle['color'], fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Text(_formatIssueType(report.issueType), style: TextStyle(color: _textDark, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: sStyle['bg'], border: Border.all(color: sStyle['border']), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  Icon(sStyle['icon'], size: 12, color: sStyle['color']),
                                  const SizedBox(width: 4),
                                  Text(report.status.toUpperCase(), style: TextStyle(color: sStyle['color'], fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          
          // Expanded Details
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(report.description, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 20),

                  // NLP Analysis Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _brandPurple.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandPurple.withOpacity(0.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, size: 16, color: _brandPurple),
                            const SizedBox(width: 8),
                            Text("AI Analysis Summary", style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text("Severity Assessment", style: TextStyle(color: Colors.purple.shade700, fontSize: 11)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: report.nlpAnalysis.severityAssessment == 'Critical' ? Colors.red.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                                child: Text(report.nlpAnalysis.severityAssessment, style: TextStyle(color: report.nlpAnalysis.severityAssessment == 'Critical' ? Colors.red.shade700 : Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ])),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text("Confidence Score", style: TextStyle(color: Colors.purple.shade700, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text("${report.nlpAnalysis.confidenceScore}%", style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold, fontSize: 14)),
                            ])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text("Auto-detected Flags:", style: TextStyle(color: Colors.purple.shade700, fontSize: 11)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: report.nlpAnalysis.autoFlags.map((flag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _brandPurple.withOpacity(0.3))),
                            child: Text(flag, style: TextStyle(color: _brandPurple, fontSize: 10, fontWeight: FontWeight.w600)),
                          )).toList(),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Attached Photos
                  if (report.photos.isNotEmpty) ...[
                    const Text("Attached Photos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: report.photos.map((url) => InkWell(
                        onTap: () => _showImageLightbox(url),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 80, height: 80,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Timeline
                  const Text("Report Timeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: report.timeline.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var event = entry.value;
                        bool isLast = idx == report.timeline.length - 1;
                        return IntrinsicHeight(
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: idx == 0 ? _brandTeal : Colors.grey.shade400)),
                                  if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.status, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 12)),
                                      Text(event.timestamp, style: TextStyle(color: _textGray, fontSize: 11)),
                                      Text("by ${event.admin}", style: TextStyle(color: _textGray, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      if (report.status != 'resolved')
                        ElevatedButton.icon(
                          onPressed: () => _updateStatus(report.id, 'resolved'),
                          icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                          label: const Text("Mark Resolved", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      const SizedBox(width: 8),
                      if (report.status == 'pending')
                        OutlinedButton.icon(
                          onPressed: () => _updateStatus(report.id, 'investigating'),
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text("Investigate"),
                          style: OutlinedButton.styleFrom(foregroundColor: _brandBlue, side: BorderSide(color: _brandBlue.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _updateStatus(report.id, 'dismissed'),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text("Dismiss"),
                        style: OutlinedButton.styleFrom(foregroundColor: _textGray, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text("Request Inspection"),
                        style: OutlinedButton.styleFrom(foregroundColor: _textDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ],
                  )
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}