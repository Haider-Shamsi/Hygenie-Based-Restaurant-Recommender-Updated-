import 'package:shared_preferences/shared_preferences.dart';

class Config {
  // Use http://127.0.0.1:8000 for iOS simulator, web, or desktop.
  // Use http://10.0.2.2:8000 for Android emulator.
  // Use your computer's local IP (e.g. http://192.168.1.46:8000) if using a physical device on the same Wi-Fi.
  
  // Set your desired backend URL here:
   static const String _localUrl = 'http://127.0.0.1:8000';
   static const String _productionUrl = 'http://abdullahgilani.pythonanywhere.com';

  static String get baseUrl {
    return _productionUrl;
  }
  //static const String baseUrl = 'http://127.0.0.1:8000';

  /// Helper to build default headers with standard JSON content-type
  /// and authorization token if it exists in SharedPreferences.
  static Future<Map<String, String>> defaultHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  /// Helper to build URI with the auth_token query parameter for
  /// development-mode fallback authentication.
  static Future<Uri> uriWithAuth(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$cleanPath');
    if (token.isEmpty) {
      return uri;
    }
    final queryParams = Map<String, dynamic>.from(uri.queryParameters);
    queryParams['auth_token'] = token;
    return uri.replace(queryParameters: queryParams);
  }
}

// class Config {
 
// }