import 'dart:convert';
import 'config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// --- DATA MODELS ---

class TimelineEvent {
  final String status;
  final String date;

  TimelineEvent({required this.status, required this.date});
}

class OwnerResponse {
  final String text;
  final String timestamp;
  final String? evidenceUrl;
  final String? evidenceImageUrl;

  OwnerResponse({required this.text, required this.timestamp, this.evidenceUrl, this.evidenceImageUrl});
}

class HygieneReport {
  final String id;
  final String reportId;
  final String dateSubmitted;
  final String issueType;
  final String priority;
  final String description;
  String status;
  OwnerResponse? ownerResponse;
  final List<TimelineEvent> timeline;
  final DateTime createdAt;
  final String? imageProofUrl;

  HygieneReport({
    required this.id,
    required this.reportId,
    required this.dateSubmitted,
    required this.issueType,
    required this.priority,
    required this.description,
    required this.status,
    this.ownerResponse,
    required this.timeline,
    required this.createdAt,
    this.imageProofUrl,
  });

  factory HygieneReport.fromJson(Map<String, dynamic> json) {
    return HygieneReport(
      id: json['id']?.toString() ?? '',
      reportId: json['report_id'] ?? '',
      dateSubmitted: json['date_submitted'] ?? '',
      issueType: json['issue_type'] ?? '',
      priority: json['priority'] ?? 'Medium',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Open',
      ownerResponse: json['owner_response'] != null
          ? OwnerResponse(
              text: json['owner_response']['text'] ?? '',
              timestamp: json['owner_response']['date'] ?? '',
              evidenceUrl: json['owner_response']['evidence_url'],
              evidenceImageUrl: json['owner_response']['evidence_image_url'],
            )
          : null,
      timeline: [TimelineEvent(status: 'Submitted', date: json['date_submitted'] ?? '')],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      imageProofUrl: json['image_proof_url'],
    );
  }
}


// --- SCREEN WIDGET ---

class OwnerHygieneReportsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const OwnerHygieneReportsScreen({super.key, required this.onBack});

  @override
  State<OwnerHygieneReportsScreen> createState() => _OwnerHygieneReportsScreenState();
}

class _OwnerHygieneReportsScreenState extends State<OwnerHygieneReportsScreen> {
  // Theme Colors
  final Color _brandTeal = const Color(0xFF10B981);
  final Color _bgGray = const Color(0xFFF9FBFB);
  final Color _textDark = const Color(0xFF111827);
  final Color _textGray = const Color(0xFF6B7280);

  // State Variables
  String _filterStatus = 'all'; // 'all', 'Open', 'Investigating', 'Resolved'
  String _sortBy = 'newest'; // 'newest', 'oldest', 'priority'
  String? _respondingToId;
  final TextEditingController _responseController = TextEditingController();
  final Set<String> _expandedDescriptions = {};
  PlatformFile? _selectedEvidenceFile; // Document
  PlatformFile? _selectedEvidenceImage; // Image

  bool _isLoading = true;
  String? _errorMessage;
  List<HygieneReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  // --- LOGIC & HELPERS ---

  Future<void> _pickEvidence() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedEvidenceFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickEvidenceImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedEvidenceImage = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<HygieneReport> get _filteredAndSortedReports {
    var filtered = _reports.where((r) {
      if (_filterStatus == 'all') return true;
      return r.status.toLowerCase() == _filterStatus.toLowerCase();
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'newest') {
        return b.createdAt.compareTo(a.createdAt);
      } else if (_sortBy == 'oldest') {
        return a.createdAt.compareTo(b.createdAt);
      } else if (_sortBy == 'priority') {
        const pOrder = {'High': 0, 'Medium': 1, 'Low': 2};
        return (pOrder[a.priority] ?? 3).compareTo(pOrder[b.priority] ?? 3);
      }
      return 0;
    });

    return filtered;
  }


  void _submitResponse(String id) {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a response'), backgroundColor: Colors.red));
      return;
    }
    _sendResponse(id, _responseController.text.trim());
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/owner/reports/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>? ?? [])
            .map((item) => HygieneReport.fromJson(item))
            .toList();
        setState(() {
          _reports = results;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load reports.';
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

  Future<void> _sendResponse(String id, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.baseUrl}/api/accounts/owner/reports/$id/response/'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Token $token';
      }

      request.fields['text'] = text;

      if (_selectedEvidenceFile != null) {
        if (_selectedEvidenceFile!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'evidence',
            _selectedEvidenceFile!.bytes!,
            filename: _selectedEvidenceFile!.name,
          ));
        } else if (_selectedEvidenceFile!.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'evidence',
            _selectedEvidenceFile!.path!,
            filename: _selectedEvidenceFile!.name,
          ));
        }
      }

      if (_selectedEvidenceImage != null) {
        if (_selectedEvidenceImage!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'evidence_image',
            _selectedEvidenceImage!.bytes!,
            filename: _selectedEvidenceImage!.name,
          ));
        } else if (_selectedEvidenceImage!.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'evidence_image',
            _selectedEvidenceImage!.path!,
            filename: _selectedEvidenceImage!.name,
          ));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          final reportIndex = _reports.indexWhere((r) => r.id == id);
          if (reportIndex != -1) {
            _reports[reportIndex].ownerResponse = OwnerResponse(
              text: text,
              timestamp: responseData['date'] ?? 'Just now',
              evidenceUrl: responseData['evidence_url'],
              evidenceImageUrl: responseData['evidence_image_url'],
            );
            _reports[reportIndex].status = 'Investigating';
          }
          _respondingToId = null;
          _selectedEvidenceFile = null;
          _selectedEvidenceImage = null;
          _responseController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response submitted successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit response.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to reach the server.'), backgroundColor: Colors.red),
      );
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedDescriptions.contains(id)) {
        _expandedDescriptions.remove(id);
      } else {
        _expandedDescriptions.add(id);
      }
    });
  }

  // --- STYLING HELPERS ---

  Color _getPriorityDotColor(String priority) {
    switch (priority) {
      case 'High': return Colors.red.shade500;
      case 'Medium': return Colors.amber.shade500;
      case 'Low': return _brandTeal;
      default: return Colors.grey.shade500;
    }
  }

  Map<String, Color> _getStatusColors(String status) {
    switch (status) {
      case 'Open': return {'bg': Colors.red.shade50, 'text': Colors.red.shade700, 'border': Colors.red.shade200};
      case 'Investigating': return {'bg': Colors.amber.shade50, 'text': Colors.amber.shade700, 'border': Colors.amber.shade200};
      case 'Resolved': return {'bg': _brandTeal.withOpacity(0.1), 'text': _brandTeal, 'border': _brandTeal.withOpacity(0.3)};
      default: return {'bg': Colors.grey.shade50, 'text': Colors.grey.shade700, 'border': Colors.grey.shade200};
    }
  }

  Map<String, Color> _getIssueTypeColors(String type) {
    switch (type) {
      case 'Food Safety': return {'bg': Colors.red.shade50, 'text': Colors.red.shade700, 'border': Colors.red.shade200};
      case 'Cleanliness': return {'bg': Colors.blue.shade50, 'text': Colors.blue.shade700, 'border': Colors.blue.shade200};
      case 'Pest': return {'bg': Colors.purple.shade50, 'text': Colors.purple.shade700, 'border': Colors.purple.shade200};
      case 'Staff Hygiene': return {'bg': Colors.amber.shade50, 'text': Colors.amber.shade700, 'border': Colors.amber.shade200};
      default: return {'bg': Colors.grey.shade50, 'text': Colors.grey.shade700, 'border': Colors.grey.shade200};
    }
  }

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
        title: const Text("Hygiene Reports", style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: Colors.grey.shade200, height: 1.0)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildFilterAndSortBar(),
            const SizedBox(height: 20),
            _buildReportsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    int openCount = _reports.where((r) => r.status == 'Open').length;
    int invCount = _reports.where((r) => r.status == 'Investigating').length;
    int resCount = _reports.where((r) => r.status == 'Resolved').length;

    return Row(
      children: [
        _buildSummaryCard("Open Reports", openCount, Icons.cancel_outlined, Colors.red, openCount > 0),
        const SizedBox(width: 12),
        _buildSummaryCard("Investigating", invCount, Icons.access_time, Colors.amber.shade700, false),
        const SizedBox(width: 12),
        _buildSummaryCard("Resolved", resCount, Icons.check_circle_outline, _brandTeal, false),
      ],
    );
  }

  Widget _buildSummaryCard(String title, int count, IconData icon, Color iconColor, bool isWarning) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isWarning ? Colors.red.shade50.withOpacity(0.5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isWarning ? Colors.red.shade200 : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 12),
            Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
            Text(title, style: TextStyle(fontSize: 11, color: _textGray, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndSortBar() {
    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'Open', 'label': 'Open'},
      {'id': 'Investigating', 'label': 'Investigating'},
      {'id': 'Resolved', 'label': 'Resolved'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Tabs
          Row(
            children: filters.map((f) {
              bool isActive = _filterStatus.toLowerCase() == f['id']!.toLowerCase();
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _filterStatus = f['id']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: isActive ? _brandTeal : Colors.transparent, width: 2)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      f['label']!,
                      style: TextStyle(color: isActive ? _brandTeal : _textGray, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          
          // Sort Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_filteredAndSortedReports.length} ${_filteredAndSortedReports.length == 1 ? 'report' : 'reports'}",
                  style: TextStyle(color: _textGray, fontSize: 12),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => setState(() => _sortBy = value),
                  offset: const Offset(0, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Text(
                        "Sort: ${_sortBy == 'newest' ? 'Newest' : _sortBy == 'oldest' ? 'Oldest' : 'Priority'}",
                        style: TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                  itemBuilder: (context) => [
                    _buildPopupItem('newest', 'Newest First'),
                    _buildPopupItem('oldest', 'Oldest First'),
                    _buildPopupItem('priority', 'Priority'),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String label) {
    bool isSelected = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _brandTeal.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? _brandTeal : _textDark, fontSize: 13)),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _brandTeal.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.thumb_up_outlined, color: _brandTeal, size: 32),
            ),
            const SizedBox(height: 16),
            Text("No ${_filterStatus != 'all' ? _filterStatus : ''} reports - Great job!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text("You currently have no hygiene reports matching this filter.", textAlign: TextAlign.center, style: TextStyle(color: _textGray, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: reports.map((report) => _buildReportCard(report)).toList(),
    );
  }

  Widget _buildReportCard(HygieneReport report) {
    bool isExpanded = _expandedDescriptions.contains(report.id);
    bool shouldTruncate = report.description.length > 120;
    String displayDescription = (isExpanded || !shouldTruncate) ? report.description : '${report.description.substring(0, 120)}...';
    
    final statusStyle = _getStatusColors(report.status);
    final typeStyle = _getIssueTypeColors(report.issueType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(report.reportId, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
                      const SizedBox(width: 8),
                      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _getPriorityDotColor(report.priority))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(report.dateSubmitted, style: TextStyle(color: _textGray, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusStyle['bg'], border: Border.all(color: statusStyle['border']!), borderRadius: BorderRadius.circular(20)),
                child: Text(report.status, style: TextStyle(color: statusStyle['text'], fontSize: 11, fontWeight: FontWeight.w600)),
              )
            ],
          ),
          const SizedBox(height: 16),

          // Issue Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: typeStyle['bg'], border: Border.all(color: typeStyle['border']!), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: typeStyle['text']),
                const SizedBox(width: 4),
                Text(report.issueType, style: TextStyle(color: typeStyle['text'], fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(displayDescription, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5)),
          if (report.imageProofUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                report.imageProofUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
          if (shouldTruncate)
            InkWell(
              onTap: () => _toggleExpand(report.id),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(isExpanded ? "Show less" : "Read more", style: TextStyle(color: _brandTeal, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          const SizedBox(height: 16),

          // Timeline
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Timeline", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textGray)),
                const SizedBox(height: 12),
                ...report.timeline.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _brandTeal)),
                      const SizedBox(width: 8),
                      Text(event.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)),
                      const SizedBox(width: 4),
                      Text("- ${event.date}", style: TextStyle(fontSize: 12, color: _textGray)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Area
          if (report.ownerResponse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _brandTeal.withOpacity(0.05), borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12), bottomLeft: Radius.circular(12)), border: Border(left: BorderSide(color: _brandTeal.withOpacity(0.3), width: 3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("Your Response", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(report.ownerResponse!.timestamp, style: TextStyle(color: _textGray, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(report.ownerResponse!.text, style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.5)),
                  if (report.ownerResponse!.evidenceUrl != null) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse(report.ownerResponse!.evidenceUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open evidence document.')),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 16, color: _brandTeal),
                          const SizedBox(width: 6),
                          Text(
                            "View Attached Document",
                            style: TextStyle(
                              color: _brandTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (report.ownerResponse!.evidenceImageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        report.ownerResponse!.evidenceImageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else if (_respondingToId == report.id)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  TextField(
                    controller: _responseController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Explain how you're addressing this issue...",
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickEvidence,
                      icon: const Icon(Icons.attach_file, size: 16),
                      label: Text(_selectedEvidenceFile != null
                          ? "Change Document (${_selectedEvidenceFile!.name})"
                          : "Attach Document"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedEvidenceFile != null ? _brandTeal : _textDark,
                        side: _selectedEvidenceFile != null ? BorderSide(color: _brandTeal) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (_selectedEvidenceFile != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: _brandTeal),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Selected: ${_selectedEvidenceFile!.name}",
                            style: TextStyle(color: _brandTeal, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedEvidenceFile = null),
                          child: const Icon(Icons.cancel, size: 16, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickEvidenceImage,
                      icon: const Icon(Icons.image_outlined, size: 16),
                      label: Text(_selectedEvidenceImage != null
                          ? "Change Image Proof (${_selectedEvidenceImage!.name})"
                          : "Attach Image Proof"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedEvidenceImage != null ? _brandTeal : _textDark,
                        side: _selectedEvidenceImage != null ? BorderSide(color: _brandTeal) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (_selectedEvidenceImage != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: _brandTeal),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "Selected: ${_selectedEvidenceImage!.name}",
                            style: TextStyle(color: _brandTeal, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedEvidenceImage = null),
                          child: const Icon(Icons.cancel, size: 16, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton.icon(onPressed: () => _submitResponse(report.id), icon: const Icon(Icons.send, size: 14, color: Colors.white), label: const Text("Submit Response", style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: _brandTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: () => setState(() => { _respondingToId = null, _selectedEvidenceFile = null, _selectedEvidenceImage = null }), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text("Cancel", style: TextStyle(color: Colors.grey)))),
                    ],
                  )
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() { _respondingToId = report.id; _responseController.clear(); _selectedEvidenceFile = null; _selectedEvidenceImage = null; }),
                style: OutlinedButton.styleFrom(foregroundColor: _brandTeal, side: BorderSide(color: _brandTeal.withOpacity(0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Respond to Report"),
              ),
            ),
        ],
      ),
    );
  }
}
