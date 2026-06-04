// Kum takibi — tam değişim ve yıkama.

enum LitterCleaningStatus { ok, warning, overdue }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class LitterTrackingRecord {
  LitterTrackingRecord({
    this.id,
    required this.lastCleaningDate,
    required this.frequencyDays,
  }) : assert(frequencyDays == 14 || frequencyDays == 21 || frequencyDays == 28);

  final int? id;
  final DateTime lastCleaningDate;
  final int frequencyDays;

  DateTime nextCleaningDate([DateTime? reference]) {
    final last = _dateOnly(lastCleaningDate);
    return last.add(Duration(days: frequencyDays));
  }

  int daysRemaining([DateTime? reference]) {
    final today = _dateOnly(reference ?? DateTime.now());
    return nextCleaningDate(reference).difference(today).inDays;
  }

  int daysElapsed([DateTime? reference]) {
    final today = _dateOnly(reference ?? DateTime.now());
    return today.difference(_dateOnly(lastCleaningDate)).inDays.clamp(0, 99999);
  }

  /// Geçen sürenin aralığa oranı (halka doluluk).
  double intervalProgress([DateTime? reference]) {
    if (frequencyDays <= 0) return 0;
    return (daysElapsed(reference) / frequencyDays).clamp(0.0, 1.0);
  }

  LitterCleaningStatus status([DateTime? reference]) {
    final remaining = daysRemaining(reference);
    if (remaining < 0) return LitterCleaningStatus.overdue;
    if (remaining <= 3) return LitterCleaningStatus.warning;
    return LitterCleaningStatus.ok;
  }

  LitterTrackingRecord copyWith({
    int? id,
    DateTime? lastCleaningDate,
    int? frequencyDays,
  }) {
    return LitterTrackingRecord(
      id: id ?? this.id,
      lastCleaningDate: lastCleaningDate ?? this.lastCleaningDate,
      frequencyDays: frequencyDays ?? this.frequencyDays,
    );
  }
}

class LitterTrackingDraft {
  const LitterTrackingDraft({
    this.id,
    required this.lastCleaningDate,
    required this.frequencyDays,
  });

  final int? id;
  final DateTime lastCleaningDate;
  final int frequencyDays;
}
