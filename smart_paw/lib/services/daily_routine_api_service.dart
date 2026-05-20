import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_session.dart';

class DailyRoutineApiException implements Exception {
  DailyRoutineApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class DailyRoutineTask {
  const DailyRoutineTask({
    required this.key,
    required this.title,
    required this.isDone,
  });

  final String key;
  final String title;
  final bool isDone;

  DailyRoutineTask copyWith({bool? isDone}) {
    return DailyRoutineTask(
      key: key,
      title: title,
      isDone: isDone ?? this.isDone,
    );
  }
}

class DailyRoutineSnapshot {
  const DailyRoutineSnapshot({
    required this.date,
    required this.tasks,
    required this.completedCount,
    required this.totalApplicable,
    this.hasActiveMedication = false,
  });

  final String date;
  final List<DailyRoutineTask> tasks;
  final int completedCount;
  final int totalApplicable;
  final bool hasActiveMedication;
}

class DailyRoutineApiService {
  DailyRoutineApiService._();

  static String todayLocalDateString() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

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

  static DailyRoutineSnapshot _snapshotFromData(Map data) {
    final date = data['date']?.toString() ?? todayLocalDateString();
    final completed = data['completedCount'];
    final total = data['totalApplicable'];
    final completedCount = completed is num
        ? completed.toInt()
        : int.tryParse(completed?.toString() ?? '') ?? 0;
    final totalApplicable = total is num
        ? total.toInt()
        : int.tryParse(total?.toString() ?? '') ?? 0;

    final list = data['tasks'];
    final tasks = <DailyRoutineTask>[];
    if (list is List) {
      for (final item in list) {
        if (item is! Map) continue;
        final m = item.cast<String, dynamic>();
        final key = m['key']?.toString() ?? '';
        if (key.isEmpty) continue;
        tasks.add(
          DailyRoutineTask(
            key: key,
            title: m['title']?.toString() ?? key,
            isDone: m['isDone'] == true,
          ),
        );
      }
    }

    return DailyRoutineSnapshot(
      date: date,
      tasks: tasks,
      completedCount: completedCount,
      totalApplicable: totalApplicable,
      hasActiveMedication: data['hasActiveMedication'] == true,
    );
  }

  static Future<DailyRoutineSnapshot> fetchToday() async {
    return fetchForDate(todayLocalDateString());
  }

  static Future<DailyRoutineSnapshot> fetchForDate(String date) async {
    final uri = ApiConfig.dailyRoutineUri(date: date);
    final res = await http.get(uri, headers: _headers());
    final body = _decodeBody(res.body);

    if (res.statusCode == 401) {
      throw DailyRoutineApiException(
        'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
        res.statusCode,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw DailyRoutineApiException(
        body['message']?.toString() ?? 'Günlük bakım yüklenemedi.',
        res.statusCode,
      );
    }

    final data = body['data'];
    if (data is! Map) {
      throw DailyRoutineApiException('Geçersiz sunucu yanıtı.', res.statusCode);
    }
    return _snapshotFromData(data.cast<String, dynamic>());
  }

  static Future<DailyRoutineSnapshot> setTaskDone({
    required String date,
    required String taskKey,
    required bool isDone,
  }) async {
    final res = await http.put(
      ApiConfig.dailyRoutineUri(),
      headers: _headers(),
      body: jsonEncode({
        'date': date,
        'taskKey': taskKey,
        'isDone': isDone,
      }),
    );
    final body = _decodeBody(res.body);

    if (res.statusCode == 401) {
      throw DailyRoutineApiException(
        'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
        res.statusCode,
      );
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw DailyRoutineApiException(
        body['message']?.toString() ?? 'Görev güncellenemedi.',
        res.statusCode,
      );
    }

    final data = body['data'];
    if (data is! Map) {
      throw DailyRoutineApiException('Geçersiz sunucu yanıtı.', res.statusCode);
    }
    return _snapshotFromData(data.cast<String, dynamic>());
  }
}
