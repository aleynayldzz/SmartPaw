import '../utils/turkish_date_format.dart';

class FoodPackageConsumption {
  const FoodPackageConsumption({
    this.id,
    required this.openingDate,
    required this.completionDate,
    required this.daysLasted,
  });

  final int? id;
  final DateTime openingDate;
  final DateTime completionDate;
  final int daysLasted;

  factory FoodPackageConsumption.fromJson(Map<String, dynamic> json) {
    final opening =
        parseApiCalendarDate(json['opening_date']) ?? DateTime.now();
    final completion =
        parseApiCalendarDate(json['completion_date']) ?? opening;

    final rawDays = json['days_lasted'];
    final parsedDays = rawDays is num
        ? rawDays.round()
        : int.tryParse(rawDays?.toString() ?? '');

    return FoodPackageConsumption(
      id: (json['consumption_id'] as num?)?.toInt(),
      openingDate: opening,
      completionDate: completion,
      daysLasted: parsedDays ?? _daysBetween(opening, completion),
    );
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    return end.difference(start).inDays.clamp(0, 99999);
  }

  static double averageDays(List<FoodPackageConsumption> records) {
    if (records.isEmpty) return 0;
    final total = records.fold<int>(0, (sum, r) => sum + r.daysLasted);
    return total / records.length;
  }
}
