import 'package:flutter/material.dart';

import '../../data/vet_visit_reasons.dart';
import '../../models/health_record.dart';
import '../../utils/turkish_date_format.dart';
import 'health_ui.dart';

/// Veteriner randevusu ekleme / düzenleme — alt sayfa formu.
class AddVetAppointmentSheet extends StatefulWidget {
  const AddVetAppointmentSheet({super.key, this.initial});

  /// Dolu ise düzenleme modu.
  final VetAppointmentRecord? initial;

  bool get isEditing => initial != null;

  @override
  State<AddVetAppointmentSheet> createState() => _AddVetAppointmentSheetState();
}

class _AddVetAppointmentSheetState extends State<AddVetAppointmentSheet> {
  final _notesCtrl = TextEditingController();

  DateTime? _visitDate;
  String? _selectedReason;
  DateTime? _nextVisitDate;

  List<String> get _reasonOptions {
    final reason = widget.initial?.reason;
    if (reason != null &&
        reason.isNotEmpty &&
        !kVetVisitReasonOptions.contains(reason)) {
      return [reason, ...kVetVisitReasonOptions];
    }
    return kVetVisitReasonOptions;
  }

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _visitDate = ini.visitDate;
      _selectedReason = ini.reason;
      _nextVisitDate = ini.nextVisitDate;
      _notesCtrl.text = ini.doctorNotes;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required bool isNext,
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      locale: const Locale('tr'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isNext) {
        _nextVisitDate = picked;
      } else {
        _visitDate = picked;
      }
    });
  }

  void _save() {
    if (_visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ziyaret tarihini seçin.')),
      );
      return;
    }
    final reason = _selectedReason;
    if (reason == null || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ziyaret nedenini seçin.')),
      );
      return;
    }

    Navigator.pop(
      context,
      VetAppointmentRecord(
        id: widget.initial?.id,
        visitDate: _visitDate!,
        reason: reason,
        doctorNotes: _notesCtrl.text.trim(),
        nextVisitDate: _nextVisitDate,
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
                        Icons.medical_services_outlined,
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
                            widget.isEditing
                                ? 'Veteriner Randevusunu Düzenle'
                                : 'Yeni Veteriner Randevusu',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: HealthUi.titleInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isEditing
                                ? 'Randevu bilgilerini güncelleyin.'
                                : 'Randevu ve ziyaret bilgilerinizi kaydedin.',
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
                  label: 'Ziyaret Tarihi',
                  child: _DateField(
                    value: _visitDate,
                    onTap: () => _pickDate(isNext: false, initial: _visitDate),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Ziyaret Nedeni',
                  child: InputDecorator(
                    decoration: _inputDecoration(hint: 'Neden seçin'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedReason,
                        isExpanded: true,
                        hint: Text(
                          'Neden seçin',
                          style: TextStyle(
                            color: HealthUi.muted.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: HealthUi.muted.withValues(alpha: 0.8),
                        ),
                        items: _reasonOptions
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: HealthUi.titleInk,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedReason = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Doktor Notları',
                  child: TextField(
                    controller: _notesCtrl,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(hint: 'Ek bilgi (isteğe bağlı)'),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Sonraki Ziyaret Tarihi',
                  child: _DateField(
                    value: _nextVisitDate,
                    onTap: () => _pickDate(
                      isNext: true,
                      initial: _nextVisitDate ?? _visitDate,
                    ),
                  ),
                ),
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

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(hint: 'Tarih seçin'),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? formatTurkishDate(value!) : 'Tarih seçin',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: value != null ? HealthUi.titleInk : HealthUi.muted,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: HealthUi.muted.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
