import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sign_in_page.dart';
import 'home_screen.dart';
import 'config.dart';
import 'services/notification_service.dart';

void startAlertPolling() {
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final token = prefs.getString('auth_token');

    if (!isLoggedIn || token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/accounts/alerts/?unread_only=true'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> results = body['results'] ?? [];
        
        final lastNotifiedAlertId = prefs.getInt('lastNotifiedAlertId') ?? 0;
        
        for (var alert in results) {
          final alertId = (alert['id'] as num?)?.toInt() ?? 0;
          if (alertId > lastNotifiedAlertId) {
            final restName = alert['restaurant_name'] ?? 'Restaurant';
            final msg = alert['message'] ?? 'Hygiene warning issued!';
            
            await NotificationService().showNotification(
              id: alertId,
              title: 'Warning: $restName',
              body: msg,
            );
            
            await prefs.setInt('lastNotifiedAlertId', alertId);
          }
        }
      }
    } catch (e) {
      // Silently ignore polling errors
    }
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().init();
  startAlertPolling();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(SafeDiningApp(isLoggedIn: isLoggedIn));
}

class SafeDiningApp extends StatelessWidget {
  final bool isLoggedIn;
  const SafeDiningApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant Hygiene App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      // App starts at Home if logged in, otherwise Login screen
      home: isLoggedIn ? const RestaurantListScreen() : const LoginScreen(), 
    );
  }
}
