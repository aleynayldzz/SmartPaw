import 'package:flutter/foundation.dart';

import '../models/health_record.dart';
import '../models/weight_record.dart';
import 'cat_api_service.dart';
import 'vet_visit_api_service.dart';

/// Ağırlık geçmişi — yalnızca veteriner ziyareti kayıtlarından türetilir.
/// Backend weight_history API hazır olunca bu katman değiştirilebilir.
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
    final all = _recordsByCat[catId] ?? const [];
    final cutoff = _sixMonthCutoff(DateTime.now());
    return all
        .where((r) => !r.dateOnly.isBefore(cutoff))
        .toList(growable: false);
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
      final vetVisits = await VetVisitApiService.fetchAll();
      _cats = _sortedCats(cats);
      _recordsByCat
        ..clear()
        ..addAll(_buildRecordsByCat(vetVisits));
      _error = null;
    } on CatApiException catch (e) {
      _cats = [];
      _recordsByCat.clear();
      _error = e.message;
    } on VetVisitApiException catch (e) {
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
    List<VetAppointmentRecord> vetVisits,
  ) {
    final byCat = <int, List<WeightRecord>>{};

    for (final visit in vetVisits) {
      if (visit.weightKg <= 0) continue;
      final day = DateTime(
        visit.visitDate.year,
        visit.visitDate.month,
        visit.visitDate.day,
      );
      byCat.putIfAbsent(visit.catId, () => []).add(
            WeightRecord(
              id: visit.id,
              catId: visit.catId,
              weightKg: visit.weightKg,
              recordedDate: day,
            ),
          );
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
