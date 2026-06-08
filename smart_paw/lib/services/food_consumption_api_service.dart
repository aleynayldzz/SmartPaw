import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/food_package_consumption.dart';
import 'auth_session.dart';

class FoodConsumptionApiException implements Exception {
  FoodConsumptionApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class FoodConsumptionApiService {
  FoodConsumptionApiService._();

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

  static Future<List<FoodPackageConsumption>> fetchHistory() async {
    final res = await http.get(
      ApiConfig.foodConsumptionHistoryUri(),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);

    if (res.statusCode == 401) {
      throw FoodConsumptionApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw FoodConsumptionApiException(
        body['message']?.toString() ?? 'Mama tüketim geçmişi yüklenemedi.',
        res.statusCode,
      );
    }

    final data = body['data'];
    if (data is! Map || data['consumption_history'] is! List) {
      return const [];
    }

    return (data['consumption_history'] as List)
        .whereType<Map>()
        .map((e) => FoodPackageConsumption.fromJson(e.cast<String, dynamic>()))
        .where((r) => r.daysLasted > 0)
        .toList(growable: false);
  }
}
