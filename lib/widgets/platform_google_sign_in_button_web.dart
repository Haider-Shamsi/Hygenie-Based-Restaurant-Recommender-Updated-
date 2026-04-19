import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;

Widget buildPlatformGoogleSignInButton({
  required BuildContext context,
  required VoidCallback? onPressed,
  required bool isLoading,
}) {
  // On Web, the official Google button drives the sign-in flow.
  // The app should listen to GoogleSignIn.instance.authenticationEvents.
  return Opacity(
    opacity: isLoading ? 0.7 : 1.0,
    child: IgnorePointer(
      ignoring: isLoading,
      child: gsi.renderButton(),
    ),
  );
}
