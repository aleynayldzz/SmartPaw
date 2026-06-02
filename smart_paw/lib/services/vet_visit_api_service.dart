import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/health_record.dart';
import 'auth_session.dart';

class VetVisitApiException implements Exception {
  VetVisitApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class VetVisitApiService {
  VetVisitApiService._();

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

  static Future<List<VetAppointmentRecord>> fetchAll() async {
    final res = await http.get(
      ApiConfig.vetVisitsUri(),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw VetVisitApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw VetVisitApiException(
        body['message']?.toString() ?? 'Veteriner kayıtları yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['vet_visits'] is! List) {
      return [];
    }
    return (data['vet_visits'] as List)
        .whereType<Map>()
        .map((e) => VetAppointmentRecord.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<VetAppointmentRecord> create({
    required int catId,
    required DateTime visitDate,
    required double weight,
    required String reason,
    String doctorNotes = '',
    DateTime? nextVisitDate,
  }) async {
    final payload = <String, dynamic>{
      'cat_id': catId,
      'visit_date': _dateToIso(visitDate),
      'weight': weight,
      'reason': reason,
      'doctor_notes': doctorNotes,
    };
    if (nextVisitDate != null) {
      payload['next_visit_date'] = _dateToIso(nextVisitDate);
    }

    final res = await http.post(
      ApiConfig.vetVisitsUri(),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw VetVisitApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 201 || body['ok'] != true) {
      throw VetVisitApiException(
        body['message']?.toString() ?? 'Veteriner kaydı oluşturulamadı.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['vet_visit'] is! Map) {
      throw VetVisitApiException('Geçersiz yanıt.', res.statusCode);
    }
    return VetAppointmentRecord.fromJson(
      (data['vet_visit'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<VetAppointmentRecord> update({
    required int visitId,
    required int catId,
    required DateTime visitDate,
    required double weight,
    required String reason,
    String doctorNotes = '',
    DateTime? nextVisitDate,
  }) async {
    final payload = <String, dynamic>{
      'cat_id': catId,
      'visit_date': _dateToIso(visitDate),
      'weight': weight,
      'reason': reason,
      'doctor_notes': doctorNotes,
    };
    if (nextVisitDate != null) {
      payload['next_visit_date'] = _dateToIso(nextVisitDate);
    }

    final res = await http.put(
      ApiConfig.vetVisitUri(visitId),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw VetVisitApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      final msg = body['message']?.toString();
      throw VetVisitApiException(
        msg ?? (res.statusCode == 404
            ? 'Güncelleme servisi bulunamadı. Backend yeniden başlatılmalı.'
            : 'Veteriner kaydı güncellenemedi.'),
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['vet_visit'] is! Map) {
      throw VetVisitApiException('Geçersiz yanıt.', res.statusCode);
    }
    return VetAppointmentRecord.fromJson(
      (data['vet_visit'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<void> delete(int visitId) async {
    final res = await http.delete(
      ApiConfig.vetVisitUri(visitId),
      headers: _headers(),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw VetVisitApiException(
        'Oturum süresi doldu veya giriş gerekli.',
        401,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      final msg = body['message']?.toString();
      throw VetVisitApiException(
        msg ?? (res.statusCode == 404
            ? 'Silme servisi bulunamadı. Backend yeniden başlatılmalı.'
            : 'Veteriner kaydı silinemedi.'),
        res.statusCode,
      );
    }
  }
}
