import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/weight_record.dart';
import 'auth_session.dart';

class WeightHistoryApiException implements Exception {
  WeightHistoryApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class WeightHistoryApiService {
  WeightHistoryApiService._();

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

  static Future<List<WeightRecord>> fetchAll({int months = 6}) async {
    final res = await http.get(
      ApiConfig.weightHistoryUri(months: months),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw WeightHistoryApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw WeightHistoryApiException(
        body['message']?.toString() ?? 'Ağırlık geçmişi yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['weight_history'] is! List) {
      return [];
    }
    return (data['weight_history'] as List)
        .whereType<Map>()
        .map((e) => WeightRecord.fromJson(e.cast<String, dynamic>()))
        .where((r) => r.weightKg > 0)
        .toList(growable: false);
  }
}
