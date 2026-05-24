import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sign_in_page.dart';
import 'home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Hygiene App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      // App starts at Home if logged in, otherwise Login screen
      home: isLoggedIn ? const RestaurantListScreen() : const LoginScreen(), 
    );
  }
}
