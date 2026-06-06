import 'package:flutter/material.dart';

import '../models/weekly_care_completion.dart';
import '../models/weight_record.dart';
import '../services/weekly_care_completion_service.dart';
import '../services/weight_history_service.dart';
import '../widgets/analysis/analysis_ui.dart';
import '../widgets/analysis/weekly_care_completion_card.dart';
import '../widgets/analysis/weight_history_card.dart';

/// Analiz sekmesi — sağlık ve bakım verilerinin görselleştirilmesi.
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key, required this.onBackToHome});

  final VoidCallback onBackToHome;

  @override
  State<AnalysisScreen> createState() => AnalysisScreenState();
}

class AnalysisScreenState extends State<AnalysisScreen>
    with AutomaticKeepAliveClientMixin {
  final _service = WeightHistoryService.instance;

  int? _selectedCatId;
  WeeklyCareCompletion? _weeklyCare;
  bool _weeklyCareLoading = true;
  String? _weeklyCareError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    if (!_service.isLoading &&
        _service.cats.isEmpty &&
        _service.error == null) {
      _service.refresh();
    } else {
      _ensureDefaultCat();
    }
    _loadWeeklyCare();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    _ensureDefaultCat();
    setState(() {});
  }

  void _ensureDefaultCat() {
    if (_service.cats.isEmpty) {
      _selectedCatId = null;
      return;
    }
    final ids = _service.cats
        .map((c) => (c['cat_id'] as num?)?.toInt())
        .whereType<int>()
        .toList();
    if (_selectedCatId == null || !ids.contains(_selectedCatId)) {
      _selectedCatId = ids.first;
    }
  }

  Future<void> _loadWeeklyCare() async {
    if (mounted) {
      setState(() {
        _weeklyCareLoading = true;
        _weeklyCareError = null;
      });
    }

    try {
      final data = await WeeklyCareCompletionService.fetchCurrentWeek();
      if (!mounted) return;
      setState(() {
        _weeklyCare = data;
        _weeklyCareLoading = false;
        _weeklyCareError = null;
      });
    } on WeeklyCareCompletionException catch (e) {
      if (!mounted) return;
      setState(() {
        _weeklyCareError = e.message;
        _weeklyCareLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _weeklyCareError =
            'Haftalık bakım analizi yüklenemedi. Lütfen tekrar deneyin.';
        _weeklyCareLoading = false;
      });
    }
  }

  /// Sekme görünür olduğunda veriyi yeniler.
  Future<void> refresh() async {
    await Future.wait([
      _service.refresh(),
      _loadWeeklyCare(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final cats = _service.cats;
    final List<WeightRecord> records = _selectedCatId == null
        ? const <WeightRecord>[]
        : _service.recordsForCat(_selectedCatId!);

    return ColoredBox(
      color: AnalysisUi.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _AnalysisPageHeader(onBack: widget.onBackToHome),
          const SizedBox(height: 12),
          _WeeklyCareSection(
            loading: _weeklyCareLoading,
            error: _weeklyCareError,
            data: _weeklyCare,
            onRetry: _loadWeeklyCare,
          ),
          const SizedBox(height: 16),
          if (_service.isLoading && cats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else if (_service.error != null && cats.isEmpty)
            _ErrorState(message: _service.error!, onRetry: _service.refresh)
          else if (cats.isEmpty)
            const _EmptyCatsState()
          else
            WeightHistoryCard(
              cats: cats,
              selectedCatId: _selectedCatId,
              records: records,
              onCatSelected: (id) => setState(() => _selectedCatId = id),
            ),
        ],
      ),
    );
  }
}

class _WeeklyCareSection extends StatelessWidget {
  const _WeeklyCareSection({
    required this.loading,
    required this.error,
    required this.data,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final WeeklyCareCompletion? data;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && data == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (error != null && data == null) {
      return _InlineErrorCard(message: error!, onRetry: onRetry);
    }

    if (data == null) return const SizedBox.shrink();

    return WeeklyCareCompletionCard(data: data!);
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AnalysisUi.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AnalysisUi.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
        ],
      ),
    );
  }
}

class _AnalysisPageHeader extends StatelessWidget {
  const _AnalysisPageHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AnalysisUi.titleInk,
              iconSize: 20,
            ),
          ),
          Text(
            'Analiz',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AnalysisUi.titleInk,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AnalysisUi.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Yeniden dene')),
        ],
      ),
    );
  }
}

class _EmptyCatsState extends StatelessWidget {
  const _EmptyCatsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'Ağırlık grafiği için önce bir kedi profili ekleyin.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: AnalysisUi.muted,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
