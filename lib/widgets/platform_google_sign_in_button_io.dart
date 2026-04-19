import 'package:flutter/widgets.dart';

import 'google_sign_in_button.dart';

Widget buildPlatformGoogleSignInButton({
  required BuildContext context,
  required VoidCallback? onPressed,
  required bool isLoading,
}) {
  return GoogleSignInButton(
    onPressed: onPressed ?? () {},
    isLoading: isLoading,
  );
}
