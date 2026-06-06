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

  DateTime get dateOnly =>
      DateTime(recordedDate.year, recordedDate.month, recordedDate.day);
}
