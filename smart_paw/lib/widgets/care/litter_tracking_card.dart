import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../models/litter_tracking_record.dart';
import '../../utils/turkish_date_format.dart';
import '../health/health_ui.dart';

Color _statusColor(LitterCleaningStatus status) {
  return switch (status) {
    LitterCleaningStatus.ok => HealthUi.accentPink,
    LitterCleaningStatus.warning => const Color(0xFFE8A04C),
    LitterCleaningStatus.overdue => const Color(0xFFD64545),
  };
}

/// Kum takibi kartı — tasarım görseline uygun, pembe tema.
class LitterTrackingCard extends StatelessWidget {
  const LitterTrackingCard({
    super.key,
    required this.record,
    required this.onAdd,
    required this.onDelete,
    required this.onSaveCleaning,
    required this.isSavingCleaning,
  });

  final LitterTrackingRecord? record;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onSaveCleaning;
  final bool isSavingCleaning;

  @override
  Widget build(BuildContext context) {
    if (record == null) {
      return _LitterCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LitterCardHeader(showAddButton: true, onAdd: onAdd),
            const SizedBox(height: 24),
            Text(
              'Kum takibini başlatmak için + ile bilgileri girin.',
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

    return _SwipeToDeleteCard(
      onDelete: onDelete,
      child: _LitterCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LitterCardHeader(showAddButton: false),
            const SizedBox(height: 16),
            _LitterTrackingBody(
              record: record!,
              onSaveCleaning: onSaveCleaning,
              isSavingCleaning: isSavingCleaning,
            ),
          ],
        ),
      ),
    );
  }
}

class _LitterCardShell extends StatelessWidget {
  const _LitterCardShell({required this.child});

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

class _LitterCardHeader extends StatelessWidget {
  const _LitterCardHeader({
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
            'Kum Takibi',
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

class _LitterTrackingBody extends StatelessWidget {
  const _LitterTrackingBody({
    required this.record,
    required this.onSaveCleaning,
    required this.isSavingCleaning,
  });

  final LitterTrackingRecord record;
  final VoidCallback onSaveCleaning;
  final bool isSavingCleaning;

  @override
  Widget build(BuildContext context) {
    final status = record.status();
    final accent = _statusColor(status);
    final remaining = record.daysRemaining();
    final progress = record.intervalProgress();

    final daysLabel =
        remaining < 0 ? '${remaining.abs()}' : '$remaining';
    final daysSuffix = remaining < 0 ? 'gün gecikti' : 'gün kaldı';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Son Temizlik',
                  value: formatTurkishDayMonth(record.lastCleaningDate),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTile(
                  label: 'Önerilen Sonraki Temizlik',
                  value: formatTurkishDayMonth(record.nextCleaningDate()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DaysRemainingText(
                number: daysLabel,
                suffix: daysSuffix,
                color: accent,
              ),
              const SizedBox(width: 14),
              _LitterProgressRing(
                progress: progress,
                accentColor: accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSavingCleaning ? null : onSaveCleaning,
            icon: isSavingCleaning
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: HealthUi.accentPink.withValues(alpha: 0.7),
                    ),
                  )
                : Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: isSavingCleaning
                        ? HealthUi.muted
                        : HealthUi.accentPink,
                  ),
            label: Text(
              isSavingCleaning ? 'Kaydediliyor...' : 'Temizliği Kaydet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSavingCleaning
                    ? HealthUi.muted
                    : HealthUi.accentPink,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: isSavingCleaning
                    ? HealthUi.fieldBorder
                    : HealthUi.accentPink.withValues(alpha: 0.55),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DaysRemainingText extends StatelessWidget {
  const _DaysRemainingText({
    required this.number,
    required this.suffix,
    required this.color,
  });

  final String number;
  final String suffix;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            suffix,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HealthUi.fieldBorder.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HealthUi.calendarIcon(size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: HealthUi.muted.withValues(alpha: 0.95),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: HealthUi.titleInk,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LitterProgressRing extends StatelessWidget {
  const _LitterProgressRing({
    required this.progress,
    required this.accentColor,
  });

  final double progress;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: CustomPaint(
        painter: _LitterRingPainter(
          progress: progress.clamp(0.0, 1.0),
          accentColor: accentColor,
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(78, 70),
            painter: _LitterBoxIconPainter(),
          ),
        ),
      ),
    );
  }
}

/// Minimal kapalı kum kabı — referans görseldeki stile yakın, sade çizim.
class _LitterBoxIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = const Color(0xFFF8F0F2)
      ..style = PaintingStyle.fill;
    final bodyBorder = Paint()
      ..color = HealthUi.accentPink.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final sandPaint = Paint()
      ..color = const Color(0xFFE8D4B8)
      ..style = PaintingStyle.fill;

    final hoodPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final hoodBorder = Paint()
      ..color = HealthUi.accentPink.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Kapalı kapak (üst yay)
    final hoodPath = Path()
      ..moveTo(w * 0.12, h * 0.38)
      ..quadraticBezierTo(w * 0.5, h * 0.02, w * 0.88, h * 0.38)
      ..lineTo(w * 0.88, h * 0.42)
      ..lineTo(w * 0.12, h * 0.42)
      ..close();
    canvas.drawPath(hoodPath, hoodPaint);
    canvas.drawPath(hoodPath, hoodBorder);

    // Gövde
    final bodyR = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.38, w * 0.84, h * 0.54),
      const Radius.circular(7),
    );
    canvas.drawRRect(bodyR, bodyPaint);
    canvas.drawRRect(bodyR, bodyBorder);

    // Kum yüzeyi
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.48, w * 0.72, h * 0.22),
        const Radius.circular(4),
      ),
      sandPaint,
    );

    // Giriş deliği
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.44),
        width: w * 0.28,
        height: h * 0.1,
      ),
      Paint()..color = const Color(0xFFEDE4E6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LitterRingPainter extends CustomPainter {
  _LitterRingPainter({
    required this.progress,
    required this.accentColor,
  });

  final double progress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    const stroke = 10.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFF3D4D8)
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
  bool shouldRepaint(covariant _LitterRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
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
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: HealthUi.accentPink,
              shape: const CircleBorder(),
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
    );
  }
}
