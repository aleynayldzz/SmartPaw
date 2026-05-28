import 'package:flutter/material.dart';

import '../../models/health_record.dart';
import '../../utils/turkish_date_format.dart';
import 'health_ui.dart';

/// İlaç ekleme / düzenleme — alt sayfa formu.
class AddMedicationSheet extends StatefulWidget {
  const AddMedicationSheet({super.key, this.initial});

  final MedicationRecord? initial;

  bool get isEditing => initial != null;

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  MedicationFrequency _frequency = MedicationFrequency.daily;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _stillUsing = true;

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _nameCtrl.text = ini.name;
      _dosageCtrl.text = ini.dosage;
      _notesCtrl.text = ini.notes;
      _frequency = ini.frequency;
      _startDate = ini.startDate;
      _endDate = ini.endDate;
      _stillUsing = ini.stillUsing;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isEnd}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isEnd ? _endDate : _startDate) ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      locale: const Locale('tr'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isEnd) {
        _endDate = picked;
      } else {
        _startDate = picked;
      }
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlaç adını girin.')),
      );
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlangıç tarihini seçin.')),
      );
      return;
    }
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş tarihini seçin.')),
      );
      return;
    }
    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitiş tarihi başlangıçtan önce olamaz.')),
      );
      return;
    }

    Navigator.pop(
      context,
      MedicationRecord(
        id: widget.initial?.id,
        name: name,
        dosage: _dosageCtrl.text.trim(),
        frequency: _frequency,
        startDate: start,
        endDate: end,
        stillUsing: _stillUsing,
        notes: _notesCtrl.text.trim(),
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
                        Icons.medication_outlined,
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
                                ? 'İlacı Düzenle'
                                : 'Yeni İlaç',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: HealthUi.titleInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isEditing
                                ? 'İlaç bilgilerini güncelleyin.'
                                : 'Kedinizin ilaç takibini düzenli tutun.',
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
                  label: 'İlaç Adı',
                  child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(hint: 'Örn. Antibiyotik'),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Dozaj',
                  child: TextField(
                    controller: _dosageCtrl,
                    decoration: _inputDecoration(hint: 'Örn. 250 mg'),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Sıklık',
                  child: _FrequencySegments(
                    selected: _frequency,
                    onChanged: (f) => setState(() => _frequency = f),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Başlangıç Tarihi',
                        child: _DateField(
                          value: _startDate,
                          onTap: () => _pickDate(isEnd: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledField(
                        label: 'Bitiş Tarihi',
                        child: _DateField(
                          value: _endDate,
                          onTap: () => _pickDate(isEnd: true),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hâlâ kullanıyor mu?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: HealthUi.titleInk,
                        ),
                      ),
                    ),
                    Switch(
                      value: _stillUsing,
                      onChanged: (v) => setState(() => _stillUsing = v),
                      activeTrackColor: HealthUi.accentPink.withValues(alpha: 0.5),
                      activeThumbColor: HealthUi.accentPink,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Notlar',
                  child: TextField(
                    controller: _notesCtrl,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      hint: 'Örn. Tok karnına, ek bilgi (isteğe bağlı)',
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

class _FrequencySegments extends StatelessWidget {
  const _FrequencySegments({
    required this.selected,
    required this.onChanged,
  });

  final MedicationFrequency selected;
  final ValueChanged<MedicationFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HealthUi.iconTileBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HealthUi.fieldBorder),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: MedicationFrequency.values.map((f) {
          final isSel = f == selected;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: isSel ? HealthUi.accentPink : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => onChanged(f),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      f.segmentTr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSel ? Colors.white : HealthUi.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
