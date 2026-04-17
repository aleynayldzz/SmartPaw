import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3001';
      default:
        return 'http://localhost:3001';
    }
  }

  static Uri signupUri() => Uri.parse('$baseUrl/api/auth/signup');
}