import 'package:flutter/widgets.dart';

import 'platform_google_sign_in_button_stub.dart'
    if (dart.library.html) 'platform_google_sign_in_button_web.dart'
    if (dart.library.io) 'platform_google_sign_in_button_io.dart' as impl;

class PlatformGoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const PlatformGoogleSignInButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return impl.buildPlatformGoogleSignInButton(
      context: context,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}
