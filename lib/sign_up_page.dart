import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Ensure font_awesome_flutter is in your pubspec.yaml
import 'sign_in_page.dart';
import 'otp_page.dart';

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
              onPressed: () => Navigator.maybePop(context),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Image.network( // Use image asset in real app
          'https://w7.pngwing.com/pngs/351/319/png-transparent-logo-safe-food-brand-dining-cutlery-green-safety-label-text-rectangle.png',
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCreateAccountPressed() {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network request
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Placeholder for your logic
          String fullName = _fullNameController.text;
          String email = _emailController.text;
          debugPrint('Simulating Account Creation for: $fullName');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(email: email),
            ),
          );
        }
      });
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
                          hintText: 'your.email@example.com',
                          controller: _emailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email is required';
                            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                              return 'Invalid email address';
                            }
                            return null;
                          },
                        ),
                        CommonWidgets.buildLabeledTextField(
                          context,
                          label: 'Mobile Number',
                          hintText: '+1 (555) 123-4567',
                          controller: _mobileController,
                          validator: (value) => value == null || value.isEmpty ? 'Mobile number is required' : null,
                        ),
                        CommonWidgets.buildLabeledTextField(
                          context,
                          label: 'Password',
                          hintText: 'Create a strong password',
                          controller: _passwordController,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          onPasswordVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
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
                        CommonWidgets.buildSocialButtons(context),
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