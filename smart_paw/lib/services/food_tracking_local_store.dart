import '../models/food_tracking_record.dart';

/// Geçici yerel depolama — backend API hazır olunca değiştirilecek.
class FoodTrackingLocalStore {
  FoodTrackingLocalStore._();

  static final FoodTrackingLocalStore instance = FoodTrackingLocalStore._();

  FoodTrackingRecord? _record;
  int _nextId = 1;

  FoodTrackingRecord? get current => _record;

  Future<FoodTrackingRecord> save(FoodTrackingDraft draft) async {
    _record = FoodTrackingRecord(
      id: draft.id ?? _record?.id ?? _nextId++,
      openingDate: DateTime(
        draft.openingDate.year,
        draft.openingDate.month,
        draft.openingDate.day,
      ),
      dailyFoodGrams: draft.dailyFoodGrams,
      packageWeightKg: draft.packageWeightKg,
    );
    return _record!;
  }

  Future<void> delete() async {
    _record = null;
  }
}
