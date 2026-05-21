import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../utils/turkish_date_format.dart';
import '../widgets/health/add_vaccine_sheet.dart';
import '../widgets/health/health_ui.dart';

/// Sağlık sekmesi — şimdilik yalnızca aşı takibi.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, required this.onBackToHome});

  final VoidCallback onBackToHome;

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with AutomaticKeepAliveClientMixin {
  final List<VaccineRecord> _vaccines = [];

  @override
  bool get wantKeepAlive => true;

  Future<void> _openAddVaccine() async {
    final record = await showModalBottomSheet<VaccineRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddVaccineSheet(),
    );
    if (record == null || !mounted) return;
    setState(() => _vaccines.insert(0, record));
  }

  List<VaccineRecord> get _sortedVaccines {
    final copy = List<VaccineRecord>.from(_vaccines);
    copy.sort((a, b) => b.vaccinationDate.compareTo(a.vaccinationDate));
    return copy;
  }

  void _removeVaccine(String id) {
    setState(() => _vaccines.removeWhere((v) => v.id == id));
  }

  Future<void> _confirmDeleteVaccine(VaccineRecord record) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: Text(
          '"${record.name}" kaydını silmek istediğinize emin misiniz?',
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
    if (yes == true && mounted) _removeVaccine(record.id);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ColoredBox(
      color: HealthUi.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _HealthPageHeader(onBack: widget.onBackToHome),
          const SizedBox(height: 8),
          _HealthSectionCard(
            title: 'AŞI TAKİBİ',
            onAdd: _openAddVaccine,
            child: _sortedVaccines.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Henüz aşı kaydı yok. Sağ üstteki + ile ekleyin.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: HealthUi.muted.withValues(alpha: 0.9),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < _sortedVaccines.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: HealthUi.fieldBorder.withValues(alpha: 0.6),
                          ),
                        _VaccineListTile(
                          record: _sortedVaccines[i],
                          onDelete: () =>
                              _confirmDeleteVaccine(_sortedVaccines[i]),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HealthPageHeader extends StatelessWidget {
  const _HealthPageHeader({required this.onBack});

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
              color: HealthUi.titleInk,
              iconSize: 20,
            ),
          ),
          Text(
            'Sağlık',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: HealthUi.titleInk,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _HealthSectionCard extends StatelessWidget {
  const _HealthSectionCard({
    required this.title,
    required this.onAdd,
    required this.child,
  });

  final String title;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HealthUi.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: HealthUi.titleInk,
                  ),
                ),
              ),
              Material(
                color: HealthUi.accentPink,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _VaccineListTile extends StatelessWidget {
  const _VaccineListTile({
    required this.record,
    required this.onDelete,
  });

  final VaccineRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: HealthUi.accentPink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.vaccines_outlined,
              color: HealthUi.accentPink,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: HealthUi.titleInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatTurkishDate(record.vaccinationDate),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: HealthUi.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: HealthUi.muted.withValues(alpha: 0.85),
            ),
            tooltip: 'Sil',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
