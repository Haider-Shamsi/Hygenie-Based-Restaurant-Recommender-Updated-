import 'dart:async';
import 'dart:convert';
import 'config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home_screen.dart';
import 'sign_up_page.dart';
import 'widgets/platform_google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isGoogleLoading = false;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;

  late final Future<void> _googleInit;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSub;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();

    // Required by google_sign_in ^7.
    _googleInit = GoogleSignIn.instance.initialize();

    // On Web, the sign-in flow is driven by the rendered Google button.
    // We receive the ID token via authentication events.
    if (kIsWeb) {
      _googleAuthSub = GoogleSignIn.instance.authenticationEvents.listen(
        (event) {
          _onGoogleAuthEvent(event);
        },
        onError: (Object e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google sign-in error: $e')),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _googleAuthSub?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      try {
        final response = await http.post(
          Uri.parse('${Config.baseUrl}/api/accounts/login/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': email, 'password': password}),
        );
        setState(() => isLoading = false);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          final userEmail = (data['user'] is Map && (data['user'] as Map)['email'] != null)
              ? (data['user'] as Map)['email'].toString()
              : email;
          await prefs.setString('userEmail', userEmail);

          if (data['token'] != null) {
            await prefs.setString('auth_token', data['token'].toString());
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logged in as $userEmail')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
            );
          }
        } else {
          final body = jsonDecode(response.body);
          final errorMsg = (body is Map && body['error'] != null) ? body['error'].toString() : 'Login failed.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg)),
            );
          }
        }
      } catch (e) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Network error: $e')),
          );
        }
      }
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00C48C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue finding safe places to eat',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Email Address", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(emailController, "example@gmail.com", TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    const Text("Password", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(passwordController, "Enter your password", TextInputType.text, isPassword: true),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF00C48C))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C48C),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white),
                              )
                            : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PlatformGoogleSignInButton(
                      onPressed: _handleGoogleSignIn,
                      isLoading: isGoogleLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF718096))),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccountScreen()));
                          },
                          child: const Text("Sign Up", style: TextStyle(color: Color(0xFF00C48C), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onGoogleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      if (isGoogleLoading) return;

      final idToken = event.user.authentication.idToken;
      if (idToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in error: Missing ID token')),
        );
        return;
      }

      if (mounted) setState(() => isGoogleLoading = true);
      await _sendGoogleTokenToBackend(idToken, event.user.email);
    }
  }

  // Mobile/desktop sign-in flow. (Web uses the rendered Google button + authenticationEvents.)
  Future<void> _handleGoogleSignIn() async {
    if (kIsWeb) return;
    if (isGoogleLoading) return;

    setState(() => isGoogleLoading = true);

    try {
      await _googleInit;

      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final idToken = account.authentication.idToken;
      if (idToken == null) throw Exception('No Google ID token');

      await _sendGoogleTokenToBackend(idToken, account.email);
    } on GoogleSignInException catch (e) {
      if (mounted) {
        setState(() => isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: ${e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: $e')),
        );
      }
    }
  }

  Future<void> _sendGoogleTokenToBackend(String idToken, String email) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/accounts/google-signin/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': idToken}),
    );

    if (mounted) setState(() => isGoogleLoading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', data['user']['email']);
      if (data['token'] != null) {
        await prefs.setString('auth_token', data['token']);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in with Google as ${data['user']['email']}')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
        );
      }
    } else {
      final error = jsonDecode(response.body)['detail'] ?? 'Google sign-in failed';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint, TextInputType type, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: type,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'This field is required';
        if (type == TextInputType.emailAddress && !value!.contains('@')) {
          return 'Enter a valid email';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F2F6),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
