import 'package:flutter/material.dart';
import 'dart:async';

import '../../models/litter_tracking_record.dart';
import '../../utils/turkish_date_format.dart';
import '../health/health_ui.dart';

const _frequencyOptions = <({int days, String title, String subtitle})>[
  (days: 14, title: '2 haftada bir', subtitle: '(14 gün)'),
  (days: 21, title: '3 haftada bir', subtitle: '(21 gün)'),
  (days: 28, title: '4 haftada bir', subtitle: '(28 gün)'),
];

class AddLitterTrackingSheet extends StatefulWidget {
  const AddLitterTrackingSheet({super.key});

  @override
  State<AddLitterTrackingSheet> createState() => _AddLitterTrackingSheetState();
}

class _AddLitterTrackingSheetState extends State<AddLitterTrackingSheet> {
  DateTime? _lastCleaningDate;
  int? _frequencyDays;
  String? _validationMessage;
  Timer? _validationTimer;

  @override
  void dispose() {
    _validationTimer?.cancel();
    super.dispose();
  }

  void _showValidation() {
    setState(() => _validationMessage = 'Zorunlu alanları doldurunuz.');
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _validationMessage = null);
    });
  }

  Future<void> _pickLastCleaningDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastCleaningDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      locale: const Locale('tr'),
    );
    if (picked == null || !mounted) return;
    setState(() => _lastCleaningDate = picked);
  }

  void _save() {
    if (_lastCleaningDate == null || _frequencyDays == null) {
      _showValidation();
      return;
    }

    Navigator.pop(
      context,
      LitterTrackingDraft(
        lastCleaningDate: DateTime(
          _lastCleaningDate!.year,
          _lastCleaningDate!.month,
          _lastCleaningDate!.day,
        ),
        frequencyDays: _frequencyDays!,
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
                        Icons.cleaning_services_outlined,
                        color: HealthUi.accentPink,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kum Takibi Ekle',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: HealthUi.titleInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Son derin temizlik tarihini ve sıklığı seçin.',
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
                  label: 'Son derin temizlik tarihi',
                  child: InkWell(
                    onTap: _pickLastCleaningDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _inputDecoration(hint: 'Tarih seçin'),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _lastCleaningDate == null
                                  ? 'Tarih seçin'
                                  : formatTurkishDate(_lastCleaningDate!),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: _lastCleaningDate == null
                                    ? HealthUi.muted.withValues(alpha: 0.7)
                                    : HealthUi.titleInk,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: HealthUi.muted.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Temizlik Sıklığı',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: HealthUi.titleInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kum kabını ne sıklıkla tamamen temizliyorsun?',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: HealthUi.muted.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _frequencyOptions.map((opt) {
                    final selected = _frequencyDays == opt.days;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: opt.days == 28 ? 0 : 8,
                        ),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _frequencyDays = opt.days),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? HealthUi.accentPink
                                    : HealthUi.fieldBorder,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  opt.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? HealthUi.accentPink
                                        : HealthUi.titleInk,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected
                                        ? HealthUi.accentPink
                                            .withValues(alpha: 0.9)
                                        : HealthUi.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
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
