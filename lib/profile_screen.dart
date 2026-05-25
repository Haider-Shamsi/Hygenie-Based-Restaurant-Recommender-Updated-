import 'package:flutter/material.dart';
import 'dart:convert';
import 'config.dart';
import 'my_reports_screen.dart';  
import 'my_reviews_screen.dart';  
import 'preferences_screen.dart'; 
import 'notification_settings_screen.dart';
import 'account_settings_screen.dart';
import 'favorites_screen.dart';
import 'sign_up_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'OwnerDashboardScreen.dart' ;
import 'AdminDashboardScreen.dart' ;


class ProfileScreen extends StatefulWidget {
  final String userRole; // 'customer', 'owner', 'admin'

  const ProfileScreen({super.key, required this.userRole});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'User';
  String _email = '';
  String _role = 'customer';
  int _reportsSubmitted = 0;
  int _reviewsWritten = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Sign in to view profile.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load profile (${response.statusCode}).';
        });
        return;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final profile = body['profile'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final metrics = profile['metrics'] as Map<String, dynamic>? ?? <String, dynamic>{};

      setState(() {
        _name = (profile['name'] as String?) ?? 'User';
        _email = (profile['email'] as String?) ?? '';
        _role = (profile['role'] as String?) ?? 'customer';
        _reportsSubmitted = (metrics['reports_submitted'] as num?)?.toInt() ?? 0;
        _reviewsWritten = (metrics['reviews_written'] as num?)?.toInt() ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to load profile right now.';
      });
    }
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
        MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 200),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _fetchProfile, child: const Text('Retry')),
                  ],
                ),
              )
            else
              ...[
                _buildHeader(),
                const SizedBox(height: 20),
                _buildStatsCard(),
                const SizedBox(height: 24),
                _buildSectionTitle("Account & Settings"),
                _buildSettingsGroup([
                  _ProfileOptionTile(
                    icon: Icons.settings_outlined,
                    title: "Preferences",
                    subtitle: "Manage hygiene thresholds and filters",
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const UserPreferencesScreen()));
                      _fetchProfile();
                    },
                  ),
                  _ProfileOptionTile(
                    icon: Icons.notifications_none_outlined,
                    title: "Notification Settings",
                    subtitle: "Control hygiene alerts and updates",
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
                      _fetchProfile();
                    },
                  ),
                  _ProfileOptionTile(
                    icon: Icons.manage_accounts_outlined,
                    title: "Account Settings",
                    subtitle: "Update profile, email, and password",
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen()));
                      _fetchProfile();
                    },
                  ),
                ]),
                const SizedBox(height: 24),
                _buildSectionTitle("Activity & History"),
                _buildSettingsGroup([
                  _ProfileOptionTile(
                    icon: Icons.message_outlined,
                    title: "My Reviews",
                    subtitle: "View all reviews you've submitted",
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReviewsScreen()));
                      _fetchProfile();
                    },
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFECFDF5),
                  ),
                  _ProfileOptionTile(
                    icon: Icons.report_problem_outlined,
                    title: "My Reports",
                    subtitle: "Track reported hygiene issues",
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReportsScreen()));
                      _fetchProfile();
                    },
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFECFDF5),
                  ),
                  if (_role == 'customer')
                    _ProfileOptionTile(
                      icon: Icons.favorite_border,
                      title: "Saved Restaurants",
                      subtitle: "View your favorites list",
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                        _fetchProfile();
                      },
                      iconColor: const Color(0xFF10B981),
                      iconBgColor: const Color(0xFFECFDF5),
                    ),
                ]),
                const SizedBox(height: 24),
                // Re-integrated Role Actions Section
                _buildSectionTitle("Role Actions"),
                _buildRoleActions(),
                const SizedBox(height: 30),
                _buildLogoutButton(),
                const SizedBox(height: 20),
                const Text("Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const Text("(c) 2026 Restaurant Hygiene App", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 100), // Space for bottom nav
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF14B8A6)]),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(_email, style: TextStyle(color: Colors.grey[600])),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildRoleBadge(),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color color;
    String label;
    if (_role == 'owner') {
      color = const Color(0xFF10B981);
      label = "Restaurant Owner";
    } else if (_role == 'admin') {
      color = Colors.purple;
      label = "Administrator";
    } else {
      color = Colors.blue;
      label = "Customer";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReportsScreen()));
                    _fetchProfile();
                  },
                  child: _buildStatItem(Icons.report_problem_outlined, "$_reportsSubmitted", "Reports Submitted", Colors.green),
                ),
              ),
              VerticalDivider(color: Colors.grey[200], thickness: 1),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReviewsScreen()));
                    _fetchProfile();
                  },
                  child: _buildStatItem(Icons.star_outline, "$_reviewsWritten", "Reviews Written", Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String val, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(children: children),
      ),
    );
  }

  // --- Role Actions Implementation ---
  Widget _buildRoleActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildRoleActionButton(
            icon: Icons.business_outlined, 
            title: "Switch to Owner View", 
            sub: "Manage your restaurant dashboard", 
            color: const Color(0xFF10B981), // Emerald Teal
            onTap: () {
          
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OwnerDashboardScreen(
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 12),
          _buildRoleActionButton(
            icon: Icons.shield_outlined, 
            title: "Switch to Admin View", 
            sub: "Access system administration", 
            color: Colors.purple, // Purple
            onTap: () async {
              // TODO: Add navigation to Admin Dashboard
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AdminDashboardScreen(
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              );
            }

          ),
        ],
      ),
    );
  }

  Widget _buildRoleActionButton({
    required IconData icon, 
    required String title, 
    required String sub, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF323F4B))),
                  Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFFCDD2), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    );
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
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBgColor;

  const _ProfileOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: iconBgColor ?? Colors.grey[100], shape: BoxShape.circle),
        child: Icon(icon, color: iconColor ?? Colors.grey[700], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF323F4B))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
