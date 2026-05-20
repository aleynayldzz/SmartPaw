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

  static Uri loginUri() => Uri.parse('$baseUrl/api/auth/login');

  static Uri authMeUri() => Uri.parse('$baseUrl/api/auth/me');

  static Uri dailyRoutineUri({String? date}) {
    final base = '$baseUrl/api/daily-routine';
    if (date == null || date.isEmpty) return Uri.parse(base);
    return Uri.parse(base).replace(queryParameters: {'date': date});
  }

  static Uri verifyEmailUri() => Uri.parse('$baseUrl/api/auth/verify-email');

  static Uri catBreedsUri() => Uri.parse('$baseUrl/api/cats/breeds');

  static Uri catsUri() => Uri.parse('$baseUrl/api/cats');

  static Uri catUri(int catId) => Uri.parse('$baseUrl/api/cats/$catId');
}
