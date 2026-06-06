import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/food_tracking_record.dart';
import 'auth_session.dart';

class FoodTrackingApiException implements Exception {
  FoodTrackingApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class FoodTrackingApiService {
  FoodTrackingApiService._();

  static Map<String, String> _headers() {
    final token = AuthSession.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decodeBody(String raw) {
    if (raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return {};
  }

  static String _dateToIso(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static Map<String, dynamic> _draftPayload(FoodTrackingDraft draft) {
    return {
      'opening_date': _dateToIso(draft.openingDate),
      'daily_food_grams': draft.dailyFoodGrams,
      'package_weight_kg': draft.packageWeightKg,
    };
  }

  static FoodTrackingRecord _parseRecord(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map || data['food_tracking'] is! Map) {
      throw FoodTrackingApiException('Geçersiz yanıt.');
    }
    return FoodTrackingRecord.fromJson(
      (data['food_tracking'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<FoodTrackingRecord?> fetchCurrent() async {
    final res = await http.get(
      ApiConfig.foodTrackingUri(),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw FoodTrackingApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw FoodTrackingApiException(
        body['message']?.toString() ?? 'Mama takibi yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map) return null;
    final raw = data['food_tracking'];
    if (raw == null) return null;
    if (raw is! Map) return null;
    return FoodTrackingRecord.fromJson(raw.cast<String, dynamic>());
  }

  static Future<FoodTrackingRecord> create(FoodTrackingDraft draft) async {
    final res = await http.post(
      ApiConfig.foodTrackingUri(),
      headers: _headers(),
      body: jsonEncode(_draftPayload(draft)),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw FoodTrackingApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 201 || body['ok'] != true) {
      throw FoodTrackingApiException(
        body['message']?.toString() ?? 'Mama takibi kaydedilemedi.',
        res.statusCode,
      );
    }
    return _parseRecord(body);
  }

  static Future<FoodTrackingRecord> replace({
    required int foodId,
    required FoodTrackingDraft draft,
  }) async {
    final res = await http.post(
      ApiConfig.foodTrackingReplaceUri(foodId),
      headers: _headers(),
      body: jsonEncode(_draftPayload(draft)),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw FoodTrackingApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw FoodTrackingApiException(
        body['message']?.toString() ?? 'Yeni mama paketi kaydedilemedi.',
        res.statusCode,
      );
    }
    return _parseRecord(body);
  }

  static Future<void> delete(int foodId) async {
    final res = await http.delete(
      ApiConfig.foodTrackingRecordUri(foodId),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw FoodTrackingApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      final msg = body['message']?.toString();
      throw FoodTrackingApiException(
        msg ?? (res.statusCode == 404
            ? 'Silme servisi bulunamadı. Backend yeniden başlatılmalı.'
            : 'Mama takibi silinemedi.'),
        res.statusCode,
      );
    }
  }
}
