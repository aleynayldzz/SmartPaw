import 'package:flutter/material.dart';

import '../models/food_tracking_record.dart';
import '../services/food_tracking_local_store.dart';
import '../widgets/care/food_tracking_card.dart';
import '../widgets/health/health_ui.dart';

/// Bakım sekmesi — yemek takibi.
class CareScreen extends StatefulWidget {
  const CareScreen({super.key, required this.onBackToHome});

  final VoidCallback onBackToHome;

  @override
  State<CareScreen> createState() => CareScreenState();
}

class CareScreenState extends State<CareScreen>
    with AutomaticKeepAliveClientMixin {
  final _store = FoodTrackingLocalStore.instance;
  FoodTrackingRecord? _record;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _record = _store.current;
  }

  void _reload() {
    setState(() => _record = _store.current);
  }

  Future<void> _openSheet() async {
    if (_record != null) return;

    final draft = await showModalBottomSheet<FoodTrackingDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFoodTrackingSheet(),
    );
    if (draft == null || !mounted) return;
    await _store.save(draft);
    if (!mounted) return;
    _reload();
  }

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: const Text(
          'Mama takibi kaydını silmek istediğinize emin misiniz?',
        ),
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
    if (yes != true || !mounted) return;
    await _store.delete();
    if (!mounted) return;
    _reload();
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
            record: _record,
            onAdd: _openSheet,
            onDelete: _record == null ? () {} : _confirmDelete,
          ),
        ],
      ),
    );
  }
}
