import '../utils/turkish_date_format.dart';

/// Tek bir ağırlık ölçüm kaydı.
class WeightRecord {
  const WeightRecord({
    this.id,
    required this.catId,
    required this.weightKg,
    required this.recordedDate,
  });

  final int? id;
  final int catId;
  final double weightKg;
  final DateTime recordedDate;

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _parseWeight(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: _parseId(json['weight_id'] ?? json['visit_id']),
      catId: _parseId(json['cat_id']) ?? 0,
      weightKg: _parseWeight(json['weight_kg'] ?? json['weight']),
      recordedDate:
          parseApiCalendarDate(json['recorded_date']) ?? DateTime.now(),
    );
  }

  DateTime get dateOnly =>
      DateTime(recordedDate.year, recordedDate.month, recordedDate.day);
}
