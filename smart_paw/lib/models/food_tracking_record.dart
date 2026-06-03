// Mama takibi modeli — açılış tarihinden itibaren günlük tüketimle hesaplanır.

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class FoodTrackingRecord {
  FoodTrackingRecord({
    this.id,
    required this.openingDate,
    required this.dailyFoodGrams,
    required this.packageWeightKg,
  });

  final int? id;
  final DateTime openingDate;
  final double dailyFoodGrams;
  final double packageWeightKg;

  double get packageGrams => packageWeightKg * 1000;

  /// Bugün itibarıyla geçen gün sayısı (açılış günü = 0).
  int daysElapsed([DateTime? reference]) {
    final today = _dateOnly(reference ?? DateTime.now());
    final opened = _dateOnly(openingDate);
    return today.difference(opened).inDays.clamp(0, 99999);
  }

  /// Günlük tüketime göre kalan gram (her gün otomatik azalır).
  double remainingGrams([DateTime? reference]) {
    if (packageGrams <= 0) return 0;
    final consumed = daysElapsed(reference) * dailyFoodGrams;
    return (packageGrams - consumed).clamp(0.0, packageGrams);
  }

  double remainingPercent([DateTime? reference]) {
    if (packageGrams <= 0) return 0;
    return remainingGrams(reference) / packageGrams;
  }

  /// Tahmini bitiş tarihi.
  DateTime estimatedFinishDate([DateTime? reference]) {
    final today = _dateOnly(reference ?? DateTime.now());
    if (dailyFoodGrams <= 0 || remainingGrams(reference) <= 0) {
      return today;
    }
    final daysLeft = (remainingGrams(reference) / dailyFoodGrams).ceil();
    return today.add(Duration(days: daysLeft));
  }

  int daysUntilFinish([DateTime? reference]) {
    final today = _dateOnly(reference ?? DateTime.now());
    return estimatedFinishDate(reference).difference(today).inDays;
  }

  /// 1 haftalık veya daha az mama kaldığında uyarı.
  bool get isRunningLow {
    final remaining = remainingGrams();
    if (remaining <= 0 || dailyFoodGrams <= 0) return false;
    return daysUntilFinish() <= 7;
  }

  FoodTrackingRecord copyWith({
    int? id,
    DateTime? openingDate,
    double? dailyFoodGrams,
    double? packageWeightKg,
  }) {
    return FoodTrackingRecord(
      id: id ?? this.id,
      openingDate: openingDate ?? this.openingDate,
      dailyFoodGrams: dailyFoodGrams ?? this.dailyFoodGrams,
      packageWeightKg: packageWeightKg ?? this.packageWeightKg,
    );
  }
}

class FoodTrackingDraft {
  const FoodTrackingDraft({
    this.id,
    required this.openingDate,
    required this.dailyFoodGrams,
    required this.packageWeightKg,
  });

  final int? id;
  final DateTime openingDate;
  final double dailyFoodGrams;
  final double packageWeightKg;
}
