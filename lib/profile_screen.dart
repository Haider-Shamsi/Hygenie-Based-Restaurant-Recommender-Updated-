import 'package:flutter/material.dart';
import 'my_reports_screen.dart';  

import 'my_reviews_screen.dart';  
import 'preferences_screen.dart'; 
import 'sign_up_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';







class ProfileScreen extends StatefulWidget {
  final String userRole; // 'customer', 'owner', 'admin'

  const ProfileScreen({super.key, required this.userRole});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

    Future<void> _handleLogout(BuildContext context) async {
      try {
        await http.post(
          Uri.parse('http://localhost:8000/api/accounts/logout/'),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        // Ignore network errors for logout
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
          (route) => false,
        );
      }
    }
  // Mock Stats
  final int reportsSubmitted = 12;
  final int reviewsWritten = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                onTap: () {
                  // TODO: Redirect to Preferences Screen
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => YourPreferencesScreen()));
                  Navigator.push(context, MaterialPageRoute(builder: (context) => UserPreferencesScreen()));
                },
              ),
              _ProfileOptionTile(
                icon: Icons.notifications_none_outlined,
                title: "Notification Settings",
                subtitle: "Control hygiene alerts and updates",
                onTap: () {
                  // TODO: Redirect to Notification Settings Screen
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => YourNotificationSettingsScreen()));
                },
              ),
              _ProfileOptionTile(
                icon: Icons.manage_accounts_outlined,
                title: "Account Settings",
                subtitle: "Update profile, email, and password",
                onTap: () {
                  // TODO: Redirect to Account Settings Screen
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => YourAccountSettingsScreen()));
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
                onTap: () {
                  // TODO: Redirect to My Reviews Screen
                   Navigator.push(context, MaterialPageRoute(builder: (context) => MyReviewsScreen()));
                },
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFECFDF5),
              ),
              _ProfileOptionTile(
                icon: Icons.report_problem_outlined,
                title: "My Reports",
                subtitle: "Track reported hygiene issues",
                onTap: () {
                  // TODO: Redirect to My Reports Screen
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => YourReportsScreen()));
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyReportsScreen()));
                },
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFECFDF5),
              ),
              if (widget.userRole == 'customer')
                _ProfileOptionTile(
                  icon: Icons.favorite_border,
                  title: "Saved Restaurants",
                  subtitle: "View your favorites list",
                  onTap: () {
                    // TODO: Redirect to Saved Restaurants Screen
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => YourSavedRestaurantsScreen()));
                  },
                  iconColor: const Color(0xFF10B981),
                  iconBgColor: const Color(0xFFECFDF5),
                ),
            ]),
            const SizedBox(height: 24),
           // _buildSectionTitle("Role Actions"),
           // _buildRoleActions(),
            const SizedBox(height: 30),
            _buildLogoutButton(),
            const SizedBox(height: 20),
            const Text("Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Text("Â© 2026 Restaurant Hygiene App", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 100), // Space for bottom nav
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
                  const Text("Lets Testcode", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Letstestcode@gmail.com", style: TextStyle(color: Colors.grey[600])),
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
    if (widget.userRole == 'owner') {
      color = const Color(0xFF10B981);
      label = "Restaurant Owner";
    } else if (widget.userRole == 'admin') {
      color = Colors.purple;
      label = "Administrator";
    } else {
      color = Colors.blue;
      label = "Customer";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
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
              // Stat item: Reports
              Expanded(
                child: InkWell(
                  onTap: () {
                    // TODO: Redirect to My Reports Screen
                     Navigator.push(context, MaterialPageRoute(builder: (context) => MyReportsScreen()));
                  },
                  child: _buildStatItem(Icons.report_problem_outlined, "$reportsSubmitted", "Reports Submitted", Colors.green),
                ),
              ),
              VerticalDivider(color: Colors.grey[200], thickness: 1),
              // Stat item: Reviews
              Expanded(
                child: InkWell(
                  onTap: () {
                    // TODO: Redirect to My Reviews Screen
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyReviewsScreen()));
                  },
                  child: _buildStatItem(Icons.star_outline, "$reviewsWritten", "Reviews Written", Colors.teal),
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


    //shamsi ive commented this part as this is for demo purposes only and we 
    //have to mkae thosee seperately


  // Widget _buildRoleActions() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20),
  //     child: Column(
  //       children: [
  //         if (widget.userRole != 'owner')
  //           _buildRoleActionButton(
  //             Icons.business_outlined, 
  //             "Switch to Owner View", 
  //             "Manage your restaurant dashboard", 
  //             const Color(0xFF10B981),
  //             onTap: () {
  //               // TODO: Redirect to Owner View
  //               // Navigator.push(context, MaterialPageRoute(builder: (context) => YourOwnerViewScreen()));
  //             }
  //           ),
  //         const SizedBox(height: 12),
  //         if (widget.userRole != 'admin')
  //           _buildRoleActionButton(
  //             Icons.shield_outlined, 
  //             "Switch to Admin View", 
  //             "Access system administration", 
  //             Colors.purple,
  //             onTap: () {
  //               // TODO: Redirect to Admin View
  //               // Navigator.push(context, MaterialPageRoute(builder: (context) => YourAdminViewScreen()));
  //             }
  //           ),
  //         const SizedBox(height: 12),
  //         _buildRoleActionButton(
  //           Icons.description_outlined, 
  //           "Audit Demo Mode", 
  //           "View sample hygiene audit", 
  //           Colors.blue,
  //           onTap: () {
  //             // TODO: Redirect to Audit Demo Screen
  //             // Navigator.push(context, MaterialPageRoute(builder: (context) => YourAuditDemoScreen()));
  //           }
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildRoleActionButton(IconData icon, String title, String sub, Color color, {required VoidCallback onTap}) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(20),
  //     child: Container(
  //       padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(20),
  //         border: Border.all(color: Colors.grey[100]!),
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
  //             child: Icon(icon, color: color),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  //                 Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
  //               ],
  //             ),
  //           ),
  //           const Icon(Icons.chevron_right, color: Colors.grey),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
              // Logout logic: call backend, clear local session, and navigate to sign up
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
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
