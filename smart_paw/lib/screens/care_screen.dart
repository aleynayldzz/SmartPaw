import 'package:flutter/material.dart';

import '../models/food_tracking_record.dart';
import '../models/litter_tracking_record.dart';
import '../services/food_tracking_local_store.dart';
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
  final _foodStore = FoodTrackingLocalStore.instance;
  final _litterStore = LitterTrackingLocalStore.instance;

  FoodTrackingRecord? _foodRecord;
  LitterTrackingRecord? _litterRecord;
  bool _litterSaving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _foodRecord = _foodStore.current;
    _litterRecord = _litterStore.current;
  }

  void _reload() {
    setState(() {
      _foodRecord = _foodStore.current;
      _litterRecord = _litterStore.current;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openFoodSheet() async {
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

    if (replacing) {
      await _foodStore.replaceWithNewPackage(draft);
      if (!mounted) return;
      _reload();
      _snack('Yeni mama paketi kaydedildi.');
    } else {
      await _foodStore.save(draft);
      if (!mounted) return;
      _reload();
    }
  }

  Future<void> _confirmDeleteFood() async {
    final yes = await _confirmDelete(
      'Mama takibi kaydını silmek istediğinize emin misiniz?',
    );
    if (yes != true || !mounted) return;
    await _foodStore.delete();
    if (!mounted) return;
    _reload();
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
    _reload();
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
      _reload();
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
    _reload();
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
          FoodTrackingCard(
            record: _foodRecord,
            onAdd: _openFoodSheet,
            onDelete: _foodRecord == null ? () {} : _confirmDeleteFood,
          ),
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
