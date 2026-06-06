import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../models/food_tracking_record.dart';
import '../../utils/turkish_date_format.dart';
import '../health/health_ui.dart';

Color _foodStatusColor(FoodSupplyStatus status) {
  return switch (status) {
    FoodSupplyStatus.ok => HealthUi.accentPink,
    FoodSupplyStatus.warning => const Color(0xFFE8A04C),
    FoodSupplyStatus.critical => const Color(0xFFD64545),
  };
}

class AddFoodTrackingSheet extends StatefulWidget {
  const AddFoodTrackingSheet({super.key, this.replacingFinishedPackage = false});

  /// Biten paket sonrası yeni paket girişi.
  final bool replacingFinishedPackage;

  @override
  State<AddFoodTrackingSheet> createState() => _AddFoodTrackingSheetState();
}

class _AddFoodTrackingSheetState extends State<AddFoodTrackingSheet> {
  final _dailyGramsCtrl = TextEditingController();
  final _packageKgCtrl = TextEditingController();

  DateTime? _openingDate;
  String? _validationMessage;
  Timer? _validationTimer;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _dailyGramsCtrl.dispose();
    _packageKgCtrl.dispose();
    super.dispose();
  }

  void _showValidation() {
    setState(() => _validationMessage = 'Zorunlu alanları doldurunuz.');
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _validationMessage = null);
    });
  }

  Future<void> _pickOpeningDate() async {
    final today = _today;
    final replacing = widget.replacingFinishedPackage;

    final picked = await showDatePicker(
      context: context,
      initialDate: _openingDate ?? today,
      firstDate: replacing ? today : DateTime(today.year - 2),
      lastDate: replacing ? DateTime(today.year + 2) : today,
      locale: const Locale('tr'),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _openingDate = DateTime(picked.year, picked.month, picked.day),
    );
  }

  void _save() {
    final daily = double.tryParse(_dailyGramsCtrl.text.replaceAll(',', '.'));
    final pkg = double.tryParse(_packageKgCtrl.text.replaceAll(',', '.'));

    if (_openingDate == null || daily == null || daily <= 0 || pkg == null || pkg <= 0) {
      _showValidation();
      return;
    }

    Navigator.pop(
      context,
      FoodTrackingDraft(
        openingDate: DateTime(
          _openingDate!.year,
          _openingDate!.month,
          _openingDate!.day,
        ),
        dailyFoodGrams: daily,
        packageWeightKg: pkg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: HealthUi.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: HealthUi.accentPink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_outlined,
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
                            widget.replacingFinishedPackage
                                ? 'Yeni Mama Paketi'
                                : 'Mama Takibi Ekle',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: HealthUi.titleInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.replacingFinishedPackage
                                ? 'Biten paketin yerine yeni paket bilgilerini girin.'
                                : 'Paket açılış tarihi, günlük tüketim ve paket ağırlığını girin.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: HealthUi.muted.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _LabeledField(
                  label: 'Paket açılış tarihi',
                  child: InkWell(
                    onTap: _pickOpeningDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _inputDecoration(hint: 'Tarih seçin'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _openingDate == null
                                  ? 'Tarih seçin'
                                  : formatTurkishDate(_openingDate!),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _openingDate == null
                                    ? HealthUi.muted.withValues(alpha: 0.7)
                                    : HealthUi.titleInk,
                              ),
                            ),
                          ),
                          HealthUi.calendarIcon(size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.replacingFinishedPackage) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Geçmiş tarih seçilemez; bugün veya sonraki günlerden birini seçin.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: HealthUi.muted.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Günlük tüketim (gram)',
                  child: TextField(
                    controller: _dailyGramsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(hint: 'Örn. 150'),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Paket ağırlığı (kg)',
                  child: TextField(
                    controller: _packageKgCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(hint: 'Örn. 2'),
                  ),
                ),
                if (_validationMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _validationMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: HealthUi.accentPink,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: HealthUi.accentPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Kaydet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: HealthUi.muted.withValues(alpha: 0.7)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: HealthUi.fieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: HealthUi.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: HealthUi.accentPink, width: 1.5),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: HealthUi.muted,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Tasarıma uygun mama takibi kartı.
class FoodTrackingCard extends StatelessWidget {
  const FoodTrackingCard({
    super.key,
    required this.record,
    required this.onAdd,
    required this.onDelete,
  });

  final FoodTrackingRecord? record;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (record == null) {
      return _FoodCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FoodCardHeader(showAddButton: true, onAdd: onAdd),
            const SizedBox(height: 24),
            Text(
              'Mama takibini başlatmak için + ile bilgileri girin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: HealthUi.muted.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    final showNewPackageButton = record!.canAddNewPackage();

    return _SwipeToDeleteCard(
      onDelete: onDelete,
      child: _FoodCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FoodCardHeader(
              showAddButton: showNewPackageButton,
              onAdd: onAdd,
            ),
            const SizedBox(height: 20),
            _FoodTrackingBody(record: record!),
          ],
        ),
      ),
    );
  }
}

class _FoodCardShell extends StatelessWidget {
  const _FoodCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: child,
    );
  }
}

class _FoodCardHeader extends StatelessWidget {
  const _FoodCardHeader({
    this.showAddButton = false,
    this.onAdd,
  });

  final bool showAddButton;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Yemek Takibi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: HealthUi.titleInk,
            ),
          ),
        ),
        if (showAddButton)
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
    );
  }
}

class _SwipeToDeleteCard extends StatefulWidget {
  const _SwipeToDeleteCard({
    required this.child,
    required this.onDelete,
  });

  final Widget child;
  final VoidCallback onDelete;

  @override
  State<_SwipeToDeleteCard> createState() => _SwipeToDeleteCardState();
}

class _SwipeToDeleteCardState extends State<_SwipeToDeleteCard> {
  static const _revealWidth = 72.0;
  double _offset = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_revealWidth, 0.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _offset = _offset < -_revealWidth / 2 ? -_revealWidth : 0.0;
    });
  }

  void _close() => setState(() => _offset = 0);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: HealthUi.accentPink,
                shape: const CircleBorder(),
                elevation: 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _close();
                    widget.onDelete();
                  },
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTap: _offset < 0 ? _close : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(_offset, 0, 0),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodTrackingBody extends StatelessWidget {
  const _FoodTrackingBody({required this.record});

  final FoodTrackingRecord record;

  String _formatGrams(double grams) {
    if (grams == grams.roundToDouble()) {
      return '${grams.toInt()} gr';
    }
    return '${grams.toStringAsFixed(1)} gr';
  }

  String _formatKg(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()} kg';
    return '${kg.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} kg';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = record.remainingGrams();
    final percent = record.remainingPercent();
    final status = record.status();
    final accent = _foodStatusColor(status);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SideInfo(
                topLabel: 'Günlük miktar:',
                topValue: _formatGrams(record.dailyFoodGrams),
                bottomLabel: 'Paket ağırlığı:',
                bottomValue: _formatKg(record.packageWeightKg),
              ),
            ),
            _FoodRing(
              remainingGrams: remaining,
              progress: percent,
              accentColor: accent,
            ),
            Expanded(
              child: _SideInfo(
                alignEnd: true,
                topLabel: 'Paket açılış:',
                topValue: formatTurkishDateShort(record.openingDate),
                bottomLabel: 'Tahmini bitiş:',
                bottomValue: formatTurkishDateShort(record.estimatedFinishDate()),
              ),
            ),
          ],
        ),
        if (record.isRunningLow) ...[
          const SizedBox(height: 20),
          _LowFoodBanner(status: status),
        ],
      ],
    );
  }
}

class _SideInfo extends StatelessWidget {
  const _SideInfo({
    required this.topLabel,
    required this.topValue,
    required this.bottomLabel,
    required this.bottomValue,
    this.alignEnd = false,
  });

  final String topLabel;
  final String topValue;
  final String bottomLabel;
  final String bottomValue;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _InfoBlock(label: topLabel, value: topValue, alignEnd: alignEnd),
        const SizedBox(height: 16),
        _InfoBlock(label: bottomLabel, value: bottomValue, alignEnd: alignEnd),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: HealthUi.muted.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: HealthUi.titleInk,
          ),
        ),
      ],
    );
  }
}

class _FoodRing extends StatelessWidget {
  const _FoodRing({
    required this.remainingGrams,
    required this.progress,
    required this.accentColor,
  });

  final double remainingGrams;
  final double progress;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final gramsText = remainingGrams == remainingGrams.roundToDouble()
        ? '${remainingGrams.toInt()} gr'
        : '${remainingGrams.toStringAsFixed(0)} gr';

    return SizedBox(
      width: 130,
      height: 130,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          accentColor: accentColor,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gramsText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'kedi maması\nkaldı',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: HealthUi.muted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.accentColor,
  });

  final double progress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const stroke = 10.0;

    final trackPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}

class _LowFoodBanner extends StatelessWidget {
  const _LowFoodBanner({required this.status});

  final FoodSupplyStatus status;

  @override
  Widget build(BuildContext context) {
    final accent = _foodStatusColor(status);
    final message = status == FoodSupplyStatus.critical
        ? 'Mama Bitti - Yeni Paket Alın!'
        : 'Mama Azalıyor - Yeni Paket Alın!';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: HealthUi.titleInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
