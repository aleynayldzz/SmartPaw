import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/litter_tracking_record.dart';
import 'auth_session.dart';

class LitterTrackingApiException implements Exception {
  LitterTrackingApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class LitterTrackingApiService {
  LitterTrackingApiService._();

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

  static Map<String, dynamic> _draftPayload(LitterTrackingDraft draft) {
    return {
      'last_cleaning_date': _dateToIso(draft.lastCleaningDate),
      'frequency_days': draft.frequencyDays,
    };
  }

  static LitterTrackingRecord _parseRecord(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map || data['litter_tracking'] is! Map) {
      throw LitterTrackingApiException('Geçersiz yanıt.');
    }
    return LitterTrackingRecord.fromJson(
      (data['litter_tracking'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<LitterTrackingRecord?> fetchCurrent() async {
    final res = await http.get(
      ApiConfig.litterTrackingUri(),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw LitterTrackingApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw LitterTrackingApiException(
        body['message']?.toString() ?? 'Kum takibi yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map) return null;
    final raw = data['litter_tracking'];
    if (raw == null) return null;
    if (raw is! Map) return null;
    return LitterTrackingRecord.fromJson(raw.cast<String, dynamic>());
  }

  static Future<LitterTrackingRecord> create(LitterTrackingDraft draft) async {
    final res = await http.post(
      ApiConfig.litterTrackingUri(),
      headers: _headers(),
      body: jsonEncode(_draftPayload(draft)),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw LitterTrackingApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 201 || body['ok'] != true) {
      throw LitterTrackingApiException(
        body['message']?.toString() ?? 'Kum takibi kaydedilemedi.',
        res.statusCode,
      );
    }
    return _parseRecord(body);
  }

  static Future<LitterTrackingRecord> saveCleaning(int litterId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final res = await http.post(
      ApiConfig.litterTrackingCleaningUri(litterId),
      headers: _headers(),
      body: jsonEncode({
        'last_cleaning_date': _dateToIso(today),
      }),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw LitterTrackingApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw LitterTrackingApiException(
        body['message']?.toString() ?? 'Temizlik kaydedilemedi.',
        res.statusCode,
      );
    }
    return _parseRecord(body);
  }

  static Future<void> delete(int litterId) async {
    final res = await http.delete(
      ApiConfig.litterTrackingRecordUri(litterId),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw LitterTrackingApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      final msg = body['message']?.toString();
      throw LitterTrackingApiException(
        msg ?? (res.statusCode == 404
            ? 'Silme servisi bulunamadı. Backend yeniden başlatılmalı.'
            : 'Kum takibi silinemedi.'),
        res.statusCode,
      );
    }
  }
}
