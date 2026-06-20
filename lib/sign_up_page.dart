import 'dart:async';
import 'dart:convert';
import 'config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Ensure font_awesome_flutter is in your pubspec.yaml
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'otp_page.dart';
import 'sign_in_page.dart';
import 'widgets/platform_google_sign_in_button.dart';
import 'OwnerDashboardScreen.dart';
import 'AdminDashboardScreen.dart';

// Define your app's main color scheme
const Color appTeal = Color(0xFF67B5A3);
const Color appBackground = Color(0xFFF9FBFB);
const Color cardBackground = Colors.white;
const Color textPrimary = Color(0xFF323F4B);
const Color textSecondary = Color(0xFF7A869A);
const Color textLink = Color(0xFF147E64);
const Color textFieldBackground = Color(0xFFF1F2F6);
const Color googleIconColor = Colors.grey; // Example, could be original colors

// --- Common Widgets ---

class CommonWidgets {
  static Widget buildHeader(BuildContext context, String iconAsset, String title, String subtitle) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        Image.network( // Use image asset in real app
          'https://imgs.search.brave.com/78Zxol2K-kDEL8FVgzqDYkzKIgYwKJj1JdmgxuBuUnQ/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly90My5m/dGNkbi5uZXQvanBn/LzE1LzIxLzEyLzc0/LzM2MF9GXzE1MjEx/Mjc0NzhfeG1OeUhq/QmYzQXVLVjJLejJr/MlBuR1F4ZE96UTJo/QkMuanBn',
          height: 120,
        ),
        const SizedBox(height: 20),
        Text(title, style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  static Widget buildLabeledTextField(BuildContext context, {
    required String label,
    required String hintText,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onPasswordVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: textFieldBackground,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isPasswordVisible,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: textSecondary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: textSecondary,
                      ),
                      onPressed: onPasswordVisibilityToggle,
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 16, color: textPrimary),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  static Widget buildActionButton(BuildContext context, String text, bool isLoading, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading ? Colors.grey[300] : appTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }

  static Widget buildSocialButtons(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: const [
            Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or')),
            Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
          ],
        ),
        const SizedBox(height: 20),
        _buildSocialButton(context, FontAwesomeIcons.google, 'Continue with Google', googleIconColor),
        const SizedBox(height: 15),
        _buildSocialButton(context, FontAwesomeIcons.apple, 'Continue with Apple', Colors.white, backgroundColor: Colors.black),
      ],
    );
  }

  static Widget _buildSocialButton(BuildContext context, FaIconData icon, String text, Color iconColor, {Color backgroundColor = Colors.white}) {
    bool isApple = backgroundColor == Colors.black;
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        border: isApple ? null : Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            // Social sign-in logic here
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: iconColor, size: 24),
              const SizedBox(width: 15),
              Text(text, style: TextStyle(fontSize: 16, color: isApple ? Colors.white : textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Create Account Screen ---

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToTerms = false;

  bool _isGoogleLoading = false;
  late final Future<void> _googleInit;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSub;

  @override
  void initState() {
    super.initState();

    // Required by google_sign_in ^7.
    _googleInit = GoogleSignIn.instance.initialize();

    // On Web, the sign-in flow is driven by the rendered Google button.
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
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onGoogleAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      if (_isGoogleLoading) return;

      final idToken = event.user.authentication.idToken;
      if (idToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in error: Missing ID token')),
        );
        return;
      }

      if (mounted) setState(() => _isGoogleLoading = true);
      await _sendGoogleTokenToBackend(idToken, event.user.email);
    }
  }

  // Mobile/desktop sign-in flow. (Web uses the rendered Google button + authenticationEvents.)
  Future<void> _handleGoogleSignIn() async {
    if (kIsWeb) return;
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);

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
        setState(() => _isGoogleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: ${e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
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

    if (mounted) setState(() => _isGoogleLoading = false);

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
          SnackBar(content: Text('Signed in with Google as $userEmail')),
        );
        
        if (userEmail.endsWith('@owner.com')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OwnerDashboardScreen(onBack: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RestaurantListScreen()));
            })),
          );
        } else if (userEmail.endsWith('@admin.com')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboardScreen(onBack: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RestaurantListScreen()));
            })),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RestaurantListScreen()),
          );
        }
      }
    } else {
      String error = 'Google sign-in failed';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['detail'] != null) error = body['detail'].toString();
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: const [
            Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or')),
            Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
          ],
        ),
        const SizedBox(height: 20),
        PlatformGoogleSignInButton(
          onPressed: _handleGoogleSignIn,
          isLoading: _isGoogleLoading,
        ),
        const SizedBox(height: 15),
        CommonWidgets._buildSocialButton(
          context,
          FontAwesomeIcons.apple,
          'Continue with Apple',
          Colors.white,
          backgroundColor: Colors.black,
        ),
      ],
    );
  }

  void _onCreateAccountPressed() async {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      setState(() {
        _isLoading = true;
      });
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      try {
        final response = await http.post(
          Uri.parse('${Config.baseUrl}/api/accounts/signup/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': email, 
            'password': password,
            'email': email,
            'full_name': _fullNameController.text.trim(),
            'phone_number': _mobileController.text.trim(),
          }),
        );
        setState(() {
          _isLoading = false;
        });
        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final otp = data['otp'];
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Account created! OTP: $otp'),
                duration: const Duration(seconds: 25),
              ), 
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OTPScreen(email: email),
              ),
            );
          }
        } else {
          final errorMsg = jsonDecode(response.body)['error'] ?? 'Sign up failed.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg)),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Network error: $e')),
          );
        }
      }
    } else if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms & privacy policy')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CommonWidgets.buildHeader(context, 'assets/logo.png', 'Create Your Account', 'Join us in promoting safe and hygienic dining'),
                Card(
                  color: cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CommonWidgets.buildLabeledTextField(
                          context,
                          label: 'Full Name',
                          hintText: 'John Smith',
                          controller: _fullNameController,
                          validator: (value) => value == null || value.isEmpty ? 'Full name is required' : null,
                        ),
                        CommonWidgets.buildLabeledTextField(
                          context,
                          label: 'Email Address',
                          hintText: 'your.email@gmail.com',
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email is required';
                            if (!value.endsWith('@gmail.com') && !value.endsWith('@owner.com') && !value.endsWith('@admin.com')) {
                              return 'Must be @gmail.com or @owner.com';
                            }
                            return null;
                          },
                        ),
                        CommonWidgets.buildLabeledTextField(
                          context,
                          label: 'Mobile Number',
                          hintText: '03XXXXXXXXX',
                          controller: _mobileController,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Mobile number is required';
                            if (!RegExp(r'^03\d{9}$').hasMatch(value)) return 'Must be 11 digits starting with 03';
                            return null;
                          },
                        ),
                        CommonWidgets.buildLabeledTextField(
                          context,
                          label: 'Password',
                          hintText: 'Create a strong password',
                          controller: _passwordController,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onPasswordVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password is required';
                            if (value.length < 8) return 'Password must be at least 8 characters';
                            if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain a number';
                            return null;
                          },
                        ),
                        CommonWidgets.buildLabeledTextField(
                          context,
                          label: 'Confirm Password',
                          hintText: 'Re-enter your password',
                          controller: _confirmPasswordController,
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          onPasswordVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please re-enter password';
                            if (value != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) => setState(() => _agreedToTerms = value!),
                              activeColor: appTeal,
                              side: const BorderSide(color: Colors.grey, width: 1),
                            ),
                            RichText(
                              text: const TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(color: textPrimary, fontSize: 14),
                                children: [
                                  TextSpan(text: 'Terms & Privacy Policy', style: TextStyle(color: textLink, fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        CommonWidgets.buildActionButton(context, 'Create Account', _isLoading, _onCreateAccountPressed),
                        const SizedBox(height: 20),
                        _buildSocialButtons(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?', style: TextStyle(color: textPrimary, fontSize: 16)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      },
                      child: const Text('Sign In', style: TextStyle(color: textLink, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
