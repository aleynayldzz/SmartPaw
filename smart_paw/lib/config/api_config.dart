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

  static Uri vaccinationsUri() => Uri.parse('$baseUrl/api/vaccinations');

  static Uri vaccinationUri(int vaccinationId) =>
      Uri.parse('$baseUrl/api/vaccinations/$vaccinationId');

  static Uri vetVisitsUri() => Uri.parse('$baseUrl/api/vet-visits');

  static Uri vetVisitUri(int visitId) =>
      Uri.parse('$baseUrl/api/vet-visits/$visitId');

  static Uri medicationsUri() => Uri.parse('$baseUrl/api/medications');

  static Uri medicationUri(int medicationId) =>
      Uri.parse('$baseUrl/api/medications/$medicationId');

  static Uri medicationScheduleUri({String? date}) {
    final base = '$baseUrl/api/medications/schedule';
    if (date == null || date.isEmpty) return Uri.parse(base);
    return Uri.parse(base).replace(queryParameters: {'date': date});
  }

  static Uri medicationTakenUri(int medicationId) =>
      Uri.parse('$baseUrl/api/medications/$medicationId/taken');

  static Uri foodTrackingUri() => Uri.parse('$baseUrl/api/food-tracking');

  static Uri foodTrackingRecordUri(int foodId) =>
      Uri.parse('$baseUrl/api/food-tracking/$foodId');

  static Uri foodTrackingReplaceUri(int foodId) =>
      Uri.parse('$baseUrl/api/food-tracking/$foodId/replace');
}
