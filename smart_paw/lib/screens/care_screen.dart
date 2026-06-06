import 'package:flutter/material.dart';

import '../models/food_tracking_record.dart';
import '../models/litter_tracking_record.dart';
import '../services/food_tracking_api_service.dart';
import '../services/litter_tracking_api_service.dart';
import '../widgets/care/add_litter_tracking_sheet.dart';
import '../widgets/care/food_tracking_card.dart';
import '../widgets/care/litter_tracking_card.dart';
import '../widgets/health/health_ui.dart';

/// Bakım sekmesi — mama ve kum takibi.
class CareScreen extends StatefulWidget {
  const CareScreen({super.key, required this.onBackToHome});

  final VoidCallback onBackToHome;

  @override
  State<CareScreen> createState() => CareScreenState();
}

class CareScreenState extends State<CareScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  FoodTrackingRecord? _foodRecord;
  bool _foodLoading = true;
  bool _foodSaving = false;
  String? _foodError;

  LitterTrackingRecord? _litterRecord;
  bool _litterLoading = true;
  bool _litterSaving = false;
  String? _litterError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reloadFromApi();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      reloadFromApi(silent: true);
    }
  }

  /// Sunucudan kayıtları yükler. Uygulama açılışı ve sekme dönüşlerinde çağrılır.
  Future<void> reloadFromApi({bool silent = false}) async {
    await Future.wait([
      _loadFood(silent: silent),
      _loadLitter(silent: silent),
    ]);
  }

  Future<void> _loadFood({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _foodLoading = true;
        _foodError = null;
      });
    }
    try {
      final record = await FoodTrackingApiService.fetchCurrent();
      if (!mounted) return;
      setState(() {
        _foodRecord = record;
        _foodLoading = false;
        _foodError = null;
      });
    } on FoodTrackingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent || _foodRecord == null) {
          _foodError = e.message;
        }
        _foodLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!silent || _foodRecord == null) {
          _foodError =
              'Mama takibi yüklenemedi. Sunucunun çalıştığından emin olun.';
        }
        _foodLoading = false;
      });
    }
  }

  Future<void> _loadLitter({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _litterLoading = true;
        _litterError = null;
      });
    }
    try {
      final record = await LitterTrackingApiService.fetchCurrent();
      if (!mounted) return;
      setState(() {
        _litterRecord = record;
        _litterLoading = false;
        _litterError = null;
      });
    } on LitterTrackingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent || _litterRecord == null) {
          _litterError = e.message;
        }
        _litterLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!silent || _litterRecord == null) {
          _litterError =
              'Kum takibi yüklenemedi. Sunucunun çalıştığından emin olun.';
        }
        _litterLoading = false;
      });
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openFoodSheet() async {
    if (_foodSaving || _foodLoading) return;

    final replacing = _foodRecord?.canAddNewPackage() ?? false;
    if (_foodRecord != null && !replacing) return;

    final draft = await showModalBottomSheet<FoodTrackingDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodTrackingSheet(
        replacingFinishedPackage: replacing,
      ),
    );
    if (draft == null || !mounted) return;

    setState(() => _foodSaving = true);
    try {
      if (replacing) {
        final foodId = _foodRecord?.id;
        if (foodId == null) {
          throw FoodTrackingApiException('Kayıt kimliği bulunamadı.');
        }
        final record = await FoodTrackingApiService.replace(
          foodId: foodId,
          draft: draft,
        );
        if (!mounted) return;
        setState(() => _foodRecord = record);
        _snack('Yeni mama paketi kaydedildi.');
      } else {
        final record = await FoodTrackingApiService.create(draft);
        if (!mounted) return;
        setState(() => _foodRecord = record);
        _snack('Mama takibi kaydedildi.');
      }
    } on FoodTrackingApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      _snack('Mama takibi kaydedilemedi. Sunucunun çalıştığından emin olun.');
    } finally {
      if (mounted) setState(() => _foodSaving = false);
    }
  }

  Future<void> _confirmDeleteFood() async {
    if (_foodSaving || _foodRecord?.id == null) return;

    final yes = await _confirmDelete(
      'Mama takibi kaydını silmek istediğinize emin misiniz?',
    );
    if (yes != true || !mounted) return;

    setState(() => _foodSaving = true);
    try {
      await FoodTrackingApiService.delete(_foodRecord!.id!);
      if (!mounted) return;
      setState(() => _foodRecord = null);
      _snack('Mama takibi silindi.');
    } on FoodTrackingApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      _snack('Mama takibi silinemedi. Sunucunun çalıştığından emin olun.');
    } finally {
      if (mounted) setState(() => _foodSaving = false);
    }
  }

  Future<void> _openLitterSheet() async {
    if (_litterSaving || _litterLoading || _litterRecord != null) return;

    final draft = await showModalBottomSheet<LitterTrackingDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddLitterTrackingSheet(),
    );
    if (draft == null || !mounted) return;

    setState(() => _litterSaving = true);
    try {
      final record = await LitterTrackingApiService.create(draft);
      if (!mounted) return;
      setState(() => _litterRecord = record);
      _snack('Kum takibi kaydedildi.');
    } on LitterTrackingApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      _snack('Kum takibi kaydedilemedi. Sunucunun çalıştığından emin olun.');
    } finally {
      if (mounted) setState(() => _litterSaving = false);
    }
  }

  Future<void> _saveLitterCleaning() async {
    if (_litterRecord == null || _litterSaving) return;

    final remaining = _litterRecord!.daysRemaining();
    if (remaining > 0) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Erken temizlik'),
          content: const Text(
            'Kumu planlanan zamandan erken temizlediğinizi onaylıyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Onayla'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }

    final litterId = _litterRecord!.id;
    if (litterId == null) {
      _snack('Kayıt kimliği bulunamadı.');
      return;
    }

    setState(() => _litterSaving = true);
    try {
      final record = await LitterTrackingApiService.saveCleaning(litterId);
      if (!mounted) return;
      setState(() => _litterRecord = record);
      _snack('Temizlik kaydedildi.');
    } on LitterTrackingApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      _snack('Temizlik kaydedilemedi. Sunucunun çalıştığından emin olun.');
    } finally {
      if (mounted) setState(() => _litterSaving = false);
    }
  }

  Future<void> _confirmDeleteLitter() async {
    if (_litterSaving || _litterRecord?.id == null) return;

    final yes = await _confirmDelete(
      'Kum takibi kaydını silmek istediğinize emin misiniz?',
    );
    if (yes != true || !mounted) return;

    setState(() => _litterSaving = true);
    try {
      await LitterTrackingApiService.delete(_litterRecord!.id!);
      if (!mounted) return;
      setState(() => _litterRecord = null);
      _snack('Kum takibi silindi.');
    } on LitterTrackingApiException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      _snack('Kum takibi silinemedi. Sunucunun çalıştığından emin olun.');
    } finally {
      if (mounted) setState(() => _litterSaving = false);
    }
  }

  Future<bool?> _confirmDelete(String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingErrorCard({
    required String title,
    required String message,
    required VoidCallback onRetry,
    required bool retryDisabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HealthUi.titleInk,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: HealthUi.muted.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: retryDisabled ? null : onRetry,
              child: const Text('Yeniden dene'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSection() {
    if (_foodLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_foodError != null) {
      return _buildTrackingErrorCard(
        title: 'Mama Takibi',
        message: _foodError!,
        onRetry: _loadFood,
        retryDisabled: _foodSaving,
      );
    }

    return FoodTrackingCard(
      record: _foodRecord,
      onAdd: _foodSaving ? () {} : _openFoodSheet,
      onDelete: _foodRecord == null || _foodSaving ? () {} : _confirmDeleteFood,
    );
  }

  Widget _buildLitterSection() {
    if (_litterLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_litterError != null) {
      return _buildTrackingErrorCard(
        title: 'Kum Takibi',
        message: _litterError!,
        onRetry: _loadLitter,
        retryDisabled: _litterSaving,
      );
    }

    return LitterTrackingCard(
      record: _litterRecord,
      onAdd: _litterSaving ? () {} : _openLitterSheet,
      onDelete:
          _litterRecord == null || _litterSaving ? () {} : _confirmDeleteLitter,
      onSaveCleaning: _saveLitterCleaning,
      isSavingCleaning: _litterSaving,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ColoredBox(
      color: HealthUi.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: widget.onBackToHome,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: HealthUi.titleInk,
                    iconSize: 20,
                  ),
                ),
                Text(
                  'Bakım',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HealthUi.titleInk,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildFoodSection(),
          const SizedBox(height: 16),
          _buildLitterSection(),
        ],
      ),
    );
  }
}
