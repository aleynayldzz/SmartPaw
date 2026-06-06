import '../models/weekly_care_completion.dart';
import 'daily_routine_api_service.dart';

class WeeklyCareCompletionException implements Exception {
  WeeklyCareCompletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Haftalık bakım tamamlama verisini günlük rutin API'sinden türetir.
/// İleride özel bir haftalık endpoint eklenebilir.
abstract final class WeeklyCareCompletionService {
  static const dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Pazartesi gününü hafta başlangıcı kabul eder.
  static DateTime weekStartMonday(DateTime reference) {
    final local = _dateOnly(reference);
    return local.subtract(Duration(days: local.weekday - DateTime.monday));
  }

  static String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  static int _completionPercent(int totalCompleted, int maxTasksPerDay) {
    if (maxTasksPerDay <= 0) return 0;
    final maxPossible = maxTasksPerDay * 7;
    final raw = ((totalCompleted / maxPossible) * 100).round();
    return raw.clamp(0, 100);
  }

  static Future<WeeklyCareCompletion> fetchCurrentWeek() async {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final weekStart = weekStartMonday(now);
    final dates = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    final snapshots = await Future.wait(
      dates.map((date) async {
        if (date.isAfter(today)) return null;
        try {
          return await DailyRoutineApiService.fetchForDate(_formatDate(date));
        } on DailyRoutineApiException catch (e) {
          throw WeeklyCareCompletionException(e.message);
        }
      }),
    );

    var maxTasksPerDay = 0;
    for (final snap in snapshots) {
      if (snap == null) continue;
      if (snap.totalApplicable > maxTasksPerDay) {
        maxTasksPerDay = snap.totalApplicable;
      }
    }

    final days = <DailyCareDaySummary>[];
    var totalCompleted = 0;

    for (var i = 0; i < dates.length; i++) {
      final date = dates[i];
      final snap = snapshots[i];
      final isFuture = date.isAfter(today);
      final completed = isFuture ? 0 : (snap?.completedCount ?? 0);

      totalCompleted += completed;
      days.add(
        DailyCareDaySummary(
          date: date,
          completedCount: completed,
          isToday: date == today,
          isFuture: isFuture,
        ),
      );
    }

    return WeeklyCareCompletion(
      weekStart: weekStart,
      days: days,
      maxTasksPerDay: maxTasksPerDay,
      totalCompleted: totalCompleted,
      completionPercent: _completionPercent(totalCompleted, maxTasksPerDay),
    );
  }
}
