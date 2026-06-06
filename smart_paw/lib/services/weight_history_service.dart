import 'package:flutter/foundation.dart';

import '../models/weight_record.dart';
import 'cat_api_service.dart';
import 'weight_history_api_service.dart';

/// Ağırlık geçmişi — backend /api/weight-history üzerinden.
class WeightHistoryService extends ChangeNotifier {
  WeightHistoryService._();

  static final WeightHistoryService instance = WeightHistoryService._();

  List<Map<String, dynamic>> _cats = [];
  final Map<int, List<WeightRecord>> _recordsByCat = {};
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get cats => List.unmodifiable(_cats);

  static DateTime sixMonthCutoff([DateTime? now]) =>
      _sixMonthCutoff(now ?? DateTime.now());

  List<WeightRecord> recordsForCat(int catId) {
    return List.unmodifiable(_recordsByCat[catId] ?? const []);
  }

  static DateTime _sixMonthCutoff(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(today.year, today.month - 6, today.day);
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cats = await CatApiService.fetchMyCats();
      final records = await WeightHistoryApiService.fetchAll(months: 6);
      _cats = _sortedCats(cats);
      _recordsByCat
        ..clear()
        ..addAll(_buildRecordsByCat(records));
      _error = null;
    } on CatApiException catch (e) {
      _cats = [];
      _recordsByCat.clear();
      _error = e.message;
    } on WeightHistoryApiException catch (e) {
      _cats = [];
      _recordsByCat.clear();
      _error = e.message;
    } catch (_) {
      _cats = [];
      _recordsByCat.clear();
      _error = 'Ağırlık verileri yüklenemedi.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void markDirty() {
    refresh();
  }

  static List<Map<String, dynamic>> _sortedCats(
    List<Map<String, dynamic>> rows,
  ) {
    final copy = List<Map<String, dynamic>>.from(rows);
    copy.sort((a, b) {
      final da = CatApiService.parseBirthDate(a['birth_date']);
      final db = CatApiService.parseBirthDate(b['birth_date']);
      final byBirth = da.compareTo(db);
      if (byBirth != 0) return byBirth;
      final ida = (a['cat_id'] as num?)?.toInt() ?? 0;
      final idb = (b['cat_id'] as num?)?.toInt() ?? 0;
      return ida.compareTo(idb);
    });
    return copy;
  }

  static Map<int, List<WeightRecord>> _buildRecordsByCat(
    List<WeightRecord> records,
  ) {
    final byCat = <int, List<WeightRecord>>{};

    for (final record in records) {
      byCat.putIfAbsent(record.catId, () => []).add(record);
    }

    for (final entry in byCat.entries) {
      final byDate = <DateTime, WeightRecord>{};
      for (final record in entry.value) {
        byDate[record.dateOnly] = record;
      }
      entry.value
        ..clear()
        ..addAll(byDate.values)
        ..sort((a, b) => a.dateOnly.compareTo(b.dateOnly));
    }

    return byCat;
  }
}
