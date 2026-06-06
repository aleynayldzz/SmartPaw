import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/health_record.dart';
import 'auth_session.dart';

class VaccinationApiException implements Exception {
  VaccinationApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class VaccinationApiService {
  VaccinationApiService._();

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

  static Future<List<VaccineRecord>> fetchAll({int? catId}) async {
    final res = await http.get(
      ApiConfig.vaccinationsUri(catId: catId),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw VaccinationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw VaccinationApiException(
        body['message']?.toString() ?? 'Aşı kayıtları yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['vaccinations'] is! List) {
      return [];
    }
    return (data['vaccinations'] as List)
        .whereType<Map>()
        .map((e) => VaccineRecord.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<VaccineRecord> create({
    required int catId,
    required String vaccineName,
    required DateTime vaccinationDate,
    DateTime? nextDueDate,
    bool reminderEnabled = false,
    String notes = '',
  }) async {
    final payload = <String, dynamic>{
      'cat_id': catId,
      'vaccine_name': vaccineName,
      'vaccination_date': _dateToIso(vaccinationDate),
      'reminder_enabled': reminderEnabled,
      'notes': notes,
    };
    if (nextDueDate != null) {
      payload['next_due_date'] = _dateToIso(nextDueDate);
    }

    final res = await http.post(
      ApiConfig.vaccinationsUri(),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw VaccinationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 201 || body['ok'] != true) {
      throw VaccinationApiException(
        body['message']?.toString() ?? 'Aşı kaydı oluşturulamadı.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['vaccination'] is! Map) {
      throw VaccinationApiException('Geçersiz yanıt.', res.statusCode);
    }
    return VaccineRecord.fromJson(
      (data['vaccination'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<VaccineRecord> update({
    required int vaccinationId,
    required int catId,
    required String vaccineName,
    required DateTime vaccinationDate,
    DateTime? nextDueDate,
    bool reminderEnabled = false,
    String notes = '',
  }) async {
    final payload = <String, dynamic>{
      'cat_id': catId,
      'vaccine_name': vaccineName,
      'vaccination_date': _dateToIso(vaccinationDate),
      'reminder_enabled': reminderEnabled,
      'notes': notes,
    };
    if (nextDueDate != null) {
      payload['next_due_date'] = _dateToIso(nextDueDate);
    }

    final res = await http.put(
      ApiConfig.vaccinationUri(vaccinationId),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw VaccinationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      final msg = body['message']?.toString();
      throw VaccinationApiException(
        msg ?? (res.statusCode == 404
            ? 'Güncelleme servisi bulunamadı. Backend yeniden başlatılmalı.'
            : 'Aşı kaydı güncellenemedi.'),
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['vaccination'] is! Map) {
      throw VaccinationApiException('Geçersiz yanıt.', res.statusCode);
    }
    return VaccineRecord.fromJson(
      (data['vaccination'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<void> delete(int vaccinationId) async {
    final res = await http.delete(
      ApiConfig.vaccinationUri(vaccinationId),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw VaccinationApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      final msg = body['message']?.toString();
      throw VaccinationApiException(
        msg ?? (res.statusCode == 404
            ? 'Silme servisi bulunamadı. Backend yeniden başlatılmalı.'
            : 'Aşı kaydı silinemedi.'),
        res.statusCode,
      );
    }
  }
}
