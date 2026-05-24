import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';



class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  @override
  void initState() {
    super.initState();
    // Simulate a redirect to a Dashboard after 3 seconds
    Timer(const Duration(seconds: 3), () {
  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
      (route) => false, // This clears the navigation stack so user can't go back to OTP
    );
  }
});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Email Icon from your design
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00C48C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.email_outlined, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Enter Verification Code',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please enter the code sent to',
            style: TextStyle(color: Color(0xFF718096)),
          ),
          const Text(
            'user@example.com',
            style: TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 40),
          
          // Success Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Checkmark Circle
                  Container(
                    height: 80,
                    width: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Color(0xFF10B981), size: 40),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Verified Successfully!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Redirecting to your dashboard...',
                    style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
