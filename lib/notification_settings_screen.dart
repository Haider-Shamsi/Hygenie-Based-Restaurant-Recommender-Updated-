import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool _hygieneAlertsEnabled = true;
  bool _inspectionWarningsEnabled = true;
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _quietHoursEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Sign in to manage notification settings.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/profile/notification-settings/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load notification settings (${response.statusCode}).';
        });
        return;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      setState(() {
        _hygieneAlertsEnabled = (body['hygiene_alerts_enabled'] as bool?) ?? true;
        _inspectionWarningsEnabled = (body['inspection_warnings_enabled'] as bool?) ?? true;
        _pushEnabled = (body['push_enabled'] as bool?) ?? true;
        _emailEnabled = (body['email_enabled'] as bool?) ?? false;
        _quietHoursEnabled = (body['quiet_hours_enabled'] as bool?) ?? false;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to load notification settings right now.';
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    final token = await _getAuthToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save settings.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.patch(
        Uri.parse('${Config.baseUrl}/api/accounts/profile/notification-settings/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'hygiene_alerts_enabled': _hygieneAlertsEnabled,
          'inspection_warnings_enabled': _inspectionWarningsEnabled,
          'push_enabled': _pushEnabled,
          'email_enabled': _emailEnabled,
          'quiet_hours_enabled': _quietHoursEnabled,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings (${response.statusCode}).')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save settings. Try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF323F4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: Color(0xFF323F4B), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _fetchSettings, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _settingTile(
                      title: 'Hygiene Alerts',
                      subtitle: 'Get notified about hygiene changes and issues',
                      value: _hygieneAlertsEnabled,
                      onChanged: (v) => setState(() => _hygieneAlertsEnabled = v),
                    ),
                    _settingTile(
                      title: 'Inspection Warnings',
                      subtitle: 'Get alerts on warnings from inspections',
                      value: _inspectionWarningsEnabled,
                      onChanged: (v) => setState(() => _inspectionWarningsEnabled = v),
                    ),
                    _settingTile(
                      title: 'Push Notifications',
                      subtitle: 'Enable mobile/browser push notifications',
                      value: _pushEnabled,
                      onChanged: (v) => setState(() => _pushEnabled = v),
                    ),
                    _settingTile(
                      title: 'Email Notifications',
                      subtitle: 'Receive important hygiene updates by email',
                      value: _emailEnabled,
                      onChanged: (v) => setState(() => _emailEnabled = v),
                    ),
                    _settingTile(
                      title: 'Quiet Hours',
                      subtitle: 'Temporarily silence non-critical notifications',
                      value: _quietHoursEnabled,
                      onChanged: (v) => setState(() => _quietHoursEnabled = v),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _settingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
