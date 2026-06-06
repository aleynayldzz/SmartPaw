import 'package:flutter/material.dart';

import '../models/food_tracking_record.dart';
import '../models/litter_tracking_record.dart';
import '../services/food_tracking_api_service.dart';
import '../services/litter_tracking_local_store.dart';
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
    with AutomaticKeepAliveClientMixin {
  final _litterStore = LitterTrackingLocalStore.instance;

  FoodTrackingRecord? _foodRecord;
  bool _foodLoading = true;
  bool _foodSaving = false;
  String? _foodError;
  LitterTrackingRecord? _litterRecord;
  bool _litterSaving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _litterRecord = _litterStore.current;
    _loadFood();
  }

  Future<void> _loadFood() async {
    if (mounted) {
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
        _foodError = e.message;
        _foodLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _foodError =
            'Mama takibi yüklenemedi. Sunucunun çalıştığından emin olun.';
        _foodLoading = false;
      });
    }
  }

  void _reloadLitter() {
    setState(() => _litterRecord = _litterStore.current);
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
    if (_litterRecord != null) return;

    final draft = await showModalBottomSheet<LitterTrackingDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddLitterTrackingSheet(),
    );
    if (draft == null || !mounted) return;
    await _litterStore.save(draft);
    if (!mounted) return;
    _reloadLitter();
    _snack('Kum takibi kaydedildi.');
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

    setState(() => _litterSaving = true);
    try {
      await _litterStore.saveCleaning();
      if (!mounted) return;
      _reloadLitter();
      _snack('Temizlik kaydedildi.');
    } catch (_) {
      if (!mounted) return;
      _snack('Temizlik kaydedilemedi.');
    } finally {
      if (mounted) setState(() => _litterSaving = false);
    }
  }

  Future<void> _confirmDeleteLitter() async {
    final yes = await _confirmDelete(
      'Kum takibi kaydını silmek istediğinize emin misiniz?',
    );
    if (yes != true || !mounted) return;
    await _litterStore.delete();
    if (!mounted) return;
    _reloadLitter();
    _snack('Kum takibi silindi.');
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
              'Mama Takibi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: HealthUi.titleInk,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _foodError!,
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
                onPressed: _foodSaving ? null : _loadFood,
                child: const Text('Yeniden dene'),
              ),
            ),
          ],
        ),
      );
    }

    return FoodTrackingCard(
      record: _foodRecord,
      onAdd: _foodSaving ? () {} : _openFoodSheet,
      onDelete: _foodRecord == null || _foodSaving ? () {} : _confirmDeleteFood,
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
          LitterTrackingCard(
            record: _litterRecord,
            onAdd: _openLitterSheet,
            onDelete: _litterRecord == null ? () {} : _confirmDeleteLitter,
            onSaveCleaning: _saveLitterCleaning,
            isSavingCleaning: _litterSaving,
          ),
        ],
      ),
    );
  }
}
