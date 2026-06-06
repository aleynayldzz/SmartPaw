import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/weekly_care_completion.dart';
import 'auth_session.dart';
import 'daily_routine_api_service.dart';

class WeeklyCareCompletionException implements Exception {
  WeeklyCareCompletionException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract final class WeeklyCareCompletionService {
  static const dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

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

  static DateTime _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? 1970,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  static WeeklyCareCompletion _fromData(Map<String, dynamic> data) {
    final daysRaw = data['days'];
    final days = <DailyCareDaySummary>[];

    if (daysRaw is List) {
      for (final item in daysRaw) {
        if (item is! Map) continue;
        final day = item.cast<String, dynamic>();
        final dateStr = day['date']?.toString() ?? '';
        if (dateStr.isEmpty) continue;
        days.add(
          DailyCareDaySummary(
            date: _parseDate(dateStr),
            completedCount: (day['completedCount'] as num?)?.toInt() ??
                int.tryParse(day['completedCount']?.toString() ?? '') ??
                0,
            isToday: day['isToday'] == true,
            isFuture: day['isFuture'] == true,
          ),
        );
      }
    }

    final weekStartStr = data['weekStart']?.toString() ?? '';
    final maxTasks = (data['maxTasksPerDay'] as num?)?.toInt() ??
        int.tryParse(data['maxTasksPerDay']?.toString() ?? '') ??
        0;
    final totalCompleted = (data['totalCompleted'] as num?)?.toInt() ??
        int.tryParse(data['totalCompleted']?.toString() ?? '') ??
        0;
    final completionPercent = (data['completionPercent'] as num?)?.toInt() ??
        int.tryParse(data['completionPercent']?.toString() ?? '') ??
        0;

    return WeeklyCareCompletion(
      weekStart: weekStartStr.isEmpty ? DateTime.now() : _parseDate(weekStartStr),
      days: days,
      maxTasksPerDay: maxTasks,
      totalCompleted: totalCompleted,
      completionPercent: completionPercent.clamp(0, 100),
    );
  }

  static Future<WeeklyCareCompletion> fetchCurrentWeek() async {
    final date = DailyRoutineApiService.todayLocalDateString();
    final uri = ApiConfig.weeklyCareCompletionUri(date: date);
    final res = await http.get(uri, headers: _headers());
    final body = _decodeBody(res.body);

    if (res.statusCode == 401) {
      throw WeeklyCareCompletionException(
        'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
        res.statusCode,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw WeeklyCareCompletionException(
        body['message']?.toString() ??
            'Haftalık bakım analizi yüklenemedi.',
        res.statusCode,
      );
    }

    final data = body['data'];
    if (data is! Map) {
      throw WeeklyCareCompletionException(
        'Geçersiz sunucu yanıtı.',
        res.statusCode,
      );
    }

    return _fromData(data.cast<String, dynamic>());
  }
}
