import '../models/litter_tracking_record.dart';

/// Geçici yerel depolama — backend API hazır olunca değiştirilecek.
class LitterTrackingLocalStore {
  LitterTrackingLocalStore._();

  static final LitterTrackingLocalStore instance = LitterTrackingLocalStore._();

  LitterTrackingRecord? _record;
  int _nextId = 1;

  LitterTrackingRecord? get current => _record;

  Future<LitterTrackingRecord> save(LitterTrackingDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _record = LitterTrackingRecord(
      id: draft.id ?? _record?.id ?? _nextId++,
      lastCleaningDate: DateTime(
        draft.lastCleaningDate.year,
        draft.lastCleaningDate.month,
        draft.lastCleaningDate.day,
      ),
      frequencyDays: draft.frequencyDays,
    );
    return _record!;
  }

  Future<LitterTrackingRecord> saveCleaning() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final existing = _record;
    if (existing == null) {
      throw StateError('Kum takibi kaydı yok.');
    }
    final today = DateTime.now();
    _record = existing.copyWith(
      lastCleaningDate: DateTime(today.year, today.month, today.day),
    );
    return _record!;
  }

  Future<void> delete() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _record = null;
  }
}
