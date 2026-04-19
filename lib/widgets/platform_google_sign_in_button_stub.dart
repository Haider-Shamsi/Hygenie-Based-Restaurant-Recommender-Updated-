import 'package:flutter/widgets.dart';

Widget buildPlatformGoogleSignInButton({
  required BuildContext context,
  required VoidCallback? onPressed,
  required bool isLoading,
}) {
  // Fallback for unsupported platforms.
  return const SizedBox.shrink();
}
