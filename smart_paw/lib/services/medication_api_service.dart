import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/health_record.dart';
import 'auth_session.dart';

class MedicationApiException implements Exception {
  MedicationApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class MedicationApiService {
  MedicationApiService._();

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

  static Future<List<MedicationRecord>> fetchAll({int? catId}) async {
    final res = await http.get(
      ApiConfig.medicationsUri(catId: catId),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw MedicationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw MedicationApiException(
        body['message']?.toString() ?? 'İlaç kayıtları yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['medications'] is! List) return [];
    return (data['medications'] as List)
        .whereType<Map>()
        .map((e) => MedicationRecord.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<List<MedicationRecord>> fetchSchedule({DateTime? date}) async {
    final res = await http.get(
      ApiConfig.medicationScheduleUri(date: date != null ? _dateToIso(date) : null),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw MedicationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw MedicationApiException(
        body['message']?.toString() ?? 'İlaç programı yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['medications'] is! List) return [];
    return (data['medications'] as List)
        .whereType<Map>()
        .map((e) => MedicationRecord.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<MedicationRecord> create({
    required int catId,
    required String medicationName,
    required String dosage,
    required String frequency,
    required DateTime startDate,
    required DateTime endDate,
    String notes = '',
  }) async {
    final payload = <String, dynamic>{
      'cat_id': catId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'start_date': _dateToIso(startDate),
      'end_date': _dateToIso(endDate),
      'notes': notes,
    };

    final res = await http.post(
      ApiConfig.medicationsUri(),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw MedicationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 201 || body['ok'] != true) {
      throw MedicationApiException(
        body['message']?.toString() ?? 'İlaç kaydı oluşturulamadı.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['medication'] is! Map) {
      throw MedicationApiException('Geçersiz yanıt.', res.statusCode);
    }
    return MedicationRecord.fromJson(
      (data['medication'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<MedicationRecord> update({
    required int medicationId,
    required int catId,
    required String medicationName,
    required String dosage,
    required String frequency,
    required DateTime startDate,
    required DateTime endDate,
    String notes = '',
  }) async {
    final payload = <String, dynamic>{
      'cat_id': catId,
      'medication_name': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'start_date': _dateToIso(startDate),
      'end_date': _dateToIso(endDate),
      'notes': notes,
    };

    final res = await http.put(
      ApiConfig.medicationUri(medicationId),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw MedicationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      final msg = body['message']?.toString();
      throw MedicationApiException(
        msg ?? (res.statusCode == 404
            ? 'Güncelleme servisi bulunamadı. Backend yeniden başlatılmalı.'
            : 'İlaç kaydı güncellenemedi.'),
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['medication'] is! Map) {
      throw MedicationApiException('Geçersiz yanıt.', res.statusCode);
    }
    return MedicationRecord.fromJson(
      (data['medication'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<void> delete(int medicationId) async {
    final res = await http.delete(
      ApiConfig.medicationUri(medicationId),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw MedicationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      final msg = body['message']?.toString();
      throw MedicationApiException(
        msg ?? (res.statusCode == 404
            ? 'Silme servisi bulunamadı. Backend yeniden başlatılmalı.'
            : 'İlaç kaydı silinemedi.'),
        res.statusCode,
      );
    }
  }

  static Future<void> setTaken({
    required int medicationId,
    required DateTime date,
    required bool isTaken,
  }) async {
    final payload = <String, dynamic>{
      'date': _dateToIso(date),
      'is_taken': isTaken,
    };
    final res = await http.post(
      ApiConfig.medicationTakenUri(medicationId),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw MedicationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw MedicationApiException(
        body['message']?.toString() ?? 'İlaç alımı kaydedilemedi.',
        res.statusCode,
      );
    }
  }
}

