import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<_AlertItem> _alerts = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Sign in to view hygiene alerts.';
          _alerts = [];
          _unreadCount = 0;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/accounts/alerts/?sort=recent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> results = (body['results'] as List<dynamic>? ?? <dynamic>[]);
        setState(() {
          _alerts = results
              .map((e) => _AlertItem.fromJson(e as Map<String, dynamic>))
              .toList(growable: false);
          _unreadCount = (body['unread_count'] as num?)?.toInt() ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _alerts = [];
          _error = 'Failed to load alerts (${response.statusCode}).';
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _alerts = [];
        _error = 'Unable to load alerts right now.';
      });
    }
  }

  Future<void> _markRead(int alertId) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) return;

      final response = await http.patch(
        Uri.parse('http://127.0.0.1:8000/api/accounts/alerts/$alertId/read/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _alerts = _alerts
              .map((item) => item.id == alertId ? item.copyWith(isRead: true) : item)
              .toList(growable: false);
          _unreadCount = _alerts.where((a) => !a.isRead).length;
        });
      }
    } catch (_) {
      // No-op: alert read marking is best-effort.
    }
  }

  Future<Map<String, dynamic>?> _loadAlertPreferences() async {
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) return null;

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/accounts/alerts/preferences/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode != 200) return null;
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<bool> _saveAlertPreferences({
    required int minHygieneScore,
    required bool excludeFlagged,
    required bool hygieneAlertsEnabled,
  }) async {
    final token = await _getAuthToken();
    if (token == null || token.isEmpty) return false;

    final response = await http.patch(
      Uri.parse('http://127.0.0.1:8000/api/accounts/alerts/preferences/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode({
        'min_hygiene_score': minHygieneScore,
        'exclude_flagged': excludeFlagged,
        'hygiene_alerts_enabled': hygieneAlertsEnabled,
      }),
    );

    return response.statusCode == 200;
  }

  Future<void> _openPreferencesSheet() async {
    final prefs = await _loadAlertPreferences();
    if (!mounted) return;

    int minScore = 75;
    bool excludeFlagged = true;
    bool alertsEnabled = true;

    if (prefs != null) {
      final prefMap = prefs['preferences'] as Map<String, dynamic>?;
      final notifMap = prefs['notification_settings'] as Map<String, dynamic>?;
      minScore = (prefMap?['min_hygiene_score'] as num?)?.toInt() ?? 75;
      excludeFlagged = (prefMap?['exclude_flagged'] as bool?) ?? true;
      alertsEnabled = (notifMap?['hygiene_alerts_enabled'] as bool?) ?? true;
    }

    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alert Preferences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Text('Minimum hygiene score: $minScore'),
                  Slider(
                    value: minScore.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (value) {
                      setModalState(() {
                        minScore = value.round();
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Exclude flagged restaurants'),
                    value: excludeFlagged,
                    onChanged: (v) {
                      setModalState(() {
                        excludeFlagged = v;
                      });
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable hygiene alerts'),
                    value: alertsEnabled,
                    onChanged: (v) {
                      setModalState(() {
                        alertsEnabled = v;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() {
                                isSaving = true;
                              });
                              final ok = await _saveAlertPreferences(
                                minHygieneScore: minScore,
                                excludeFlagged: excludeFlagged,
                                hygieneAlertsEnabled: alertsEnabled,
                              );
                              if (!mounted || !context.mounted) return;
                              Navigator.pop(context);
                              if (ok) {
                                _fetchAlerts();
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Alert preferences updated.')),
                                );
                              } else {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('Failed to update preferences.')),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Preferences'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF323F4B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hygiene Alerts',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF323F4B)),
                ),
                const SizedBox(height: 8),
                Text(
                  _unreadCount > 0
                      ? '$_unreadCount unread alerts near you'
                      : 'Restaurants near you with hygiene concerns',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF7A869A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildContent()),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: _openPreferencesSheet,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Adjust Alert Preferences',
                  style: TextStyle(color: Color(0xFF323F4B), fontSize: 16),
                ),
              ),
            ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchAlerts,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'No hygiene alerts right now.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7A869A)),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          return AlertCard(
            name: alert.name,
            category: alert.category,
            message: alert.message,
            distance: alert.distance,
            timeAgo: alert.timeAgo,
            score: alert.score,
            severityColor: alert.severityColor,
            dimmed: alert.isRead,
            onTap: () => _markRead(alert.id),
          );
        },
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final String name;
  final String category;
  final String message;
  final String distance;
  final String timeAgo;
  final int score;
  final Color severityColor;
  final bool dimmed;
  final VoidCallback onTap;

  const AlertCard({
    super.key,
    required this.name,
    required this.category,
    required this.message,
    required this.distance,
    required this.timeAgo,
    required this.score,
    required this.severityColor,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.72 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: severityColor.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: severityColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF323F4B)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: severityColor, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            score.toString(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(category, style: const TextStyle(color: Color(0xFF7A869A), fontSize: 14)),
                    const SizedBox(height: 12),
                    Text(message, style: const TextStyle(color: Color(0xFF323F4B), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF7A869A)),
                        const SizedBox(width: 4),
                        Text('$distance  •  $timeAgo', style: const TextStyle(color: Color(0xFF7A869A), fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertItem {
  final int id;
  final String name;
  final String category;
  final String message;
  final String distance;
  final String timeAgo;
  final int score;
  final bool isRead;

  const _AlertItem({
    required this.id,
    required this.name,
    required this.category,
    required this.message,
    required this.distance,
    required this.timeAgo,
    required this.score,
    required this.isRead,
  });

  factory _AlertItem.fromJson(Map<String, dynamic> json) {
    final score = (json['score'] as num?)?.toInt() ?? 0;
    return _AlertItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['restaurant_name'] as String?) ?? 'Unknown restaurant',
      category: (json['category'] as String?) ?? 'N/A',
      message: (json['message'] as String?) ?? 'Hygiene issue reported',
      distance: (json['distance'] as String?) ?? '${(json['distance_km'] as num?)?.toStringAsFixed(1) ?? '0.0'} km',
      timeAgo: (json['time_since_alert'] as String?) ?? 'recently',
      score: score,
      isRead: (json['is_read'] as bool?) ?? false,
    );
  }

  _AlertItem copyWith({bool? isRead}) {
    return _AlertItem(
      id: id,
      name: name,
      category: category,
      message: message,
      distance: distance,
      timeAgo: timeAgo,
      score: score,
      isRead: isRead ?? this.isRead,
    );
  }

  Color get severityColor {
    if (score < 60) return Colors.red;
    if (score < 75) return Colors.orange;
    return Colors.amber;
  }
}
