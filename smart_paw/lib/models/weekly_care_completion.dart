/// Tek bir günün bakım tamamlama özeti.
class DailyCareDaySummary {
  const DailyCareDaySummary({
    required this.date,
    required this.completedCount,
    required this.isToday,
    required this.isFuture,
  });

  final DateTime date;
  final int completedCount;
  final bool isToday;
  final bool isFuture;
}

/// Mevcut hafta (Pzt–Paz) bakım tamamlama analizi.
class WeeklyCareCompletion {
  const WeeklyCareCompletion({
    required this.weekStart,
    required this.days,
    required this.maxTasksPerDay,
    required this.totalCompleted,
    required this.completionPercent,
  });

  final DateTime weekStart;
  final List<DailyCareDaySummary> days;
  final int maxTasksPerDay;
  final int totalCompleted;
  final int completionPercent;
}
