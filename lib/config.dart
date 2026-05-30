import 'package:flutter/foundation.dart';

class Config {
  // Use http://127.0.0.1:8000 for web/desktop.
  // Use http://10.0.2.2:8000 for Android emulator.
  // Use your computer's local IP (e.g. http://192.168.1.46:8000) for a physical device.
  static const String _deviceBaseUrl = 'http://192.168.1.67:8000';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return _deviceBaseUrl;
  }
}
