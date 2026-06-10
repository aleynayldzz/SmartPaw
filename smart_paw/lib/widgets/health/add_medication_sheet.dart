import 'package:flutter/material.dart';
import 'dart:async';

import '../../models/health_record.dart';
import '../../utils/text_input_config.dart';
import '../../utils/turkish_date_format.dart';
import 'add_vaccine_sheet.dart';
import 'health_ui.dart';

/// İlaç ekleme / düzenleme — alt sayfa formu.
enum MedicationSheetMode { create, view, edit }

class AddMedicationSheet extends StatefulWidget {
  const AddMedicationSheet({
    super.key,
    required this.cats,
    this.initial,
    this.mode = MedicationSheetMode.create,
    this.defaultCatId,
  });

  final List<VaccineCatOption> cats;

  final MedicationRecord? initial;
  final MedicationSheetMode mode;

  /// Oluşturma modunda önceden seçili kedi (ilaç filtresinden gelir).
  final int? defaultCatId;

  bool get readOnly => mode == MedicationSheetMode.view;
  bool get isEditing => mode == MedicationSheetMode.edit;

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class MedicationDraft {
  const MedicationDraft({
    this.id,
    required this.catId,
    required this.name,
    required this.dosage,
    required this.frequencyKey,
    required this.startDate,
    required this.endDate,
    required this.notes,
  });

  final int? id;
  final int catId;
  final String name;
  final String dosage;
  final String frequencyKey; // daily|weekly|asNeeded
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  MedicationFrequency _frequency = MedicationFrequency.daily;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _catId;
  String? _validationMessage;
  Timer? _validationTimer;

  bool get _readOnly => widget.readOnly;

  String _catLabel(int? catId) {
    if (catId == null) return '—';
    for (final c in widget.cats) {
      if (c.catId == catId) return c.name;
    }
    return widget.initial?.catName ?? '—';
  }

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _catId = ini.catId;
      _nameCtrl.text = ini.name;
      _dosageCtrl.text = ini.dosage;
      _notesCtrl.text = ini.notes;
      _frequency = _frequencyFromKey(ini.frequency);
      _startDate = ini.startDate;
      _endDate = ini.endDate;
    } else if (widget.defaultCatId != null &&
        widget.cats.any((c) => c.catId == widget.defaultCatId)) {
      _catId = widget.defaultCatId;
    }
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showRequiredFieldsSnack() {
    setState(() => _validationMessage = 'Zorunlu alanları doldurunuz.');
    _validationTimer?.cancel();
    _validationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _validationMessage = null);
    });
  }

  Future<void> _pickDate({required bool isEnd}) async {
    if (_readOnly) return;
    final now = DateTime.now();
    final startDay = _startDate != null
        ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
        : null;
    final picked = await showDatePicker(
      context: context,
      initialDate: (isEnd ? _endDate : _startDate) ??
          (isEnd && startDay != null ? startDay : now),
      firstDate: isEnd && startDay != null ? startDay : DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
      locale: const Locale('tr'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isEnd) {
        _endDate = picked;
      } else {
        _startDate = picked;
        if (_endDate != null) {
          final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
          final start = DateTime(picked.year, picked.month, picked.day);
          if (end.isBefore(start)) {
            _endDate = null;
          }
        }
      }
    });
  }

  void _save() {
    if (_readOnly) return;
    final name = _nameCtrl.text.trim();
    final dosage = _dosageCtrl.text.trim();
    if (_catId == null ||
        _catId! <= 0 ||
        name.isEmpty ||
        dosage.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      _showRequiredFieldsSnack();
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
      MedicationDraft(
        id: widget.initial?.id,
        catId: _catId!,
        name: name,
        dosage: dosage,
        frequencyKey: _frequencyKey(_frequency),
        startDate: start,
        endDate: end,
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
                            switch (widget.mode) {
                              MedicationSheetMode.create => 'Yeni İlaç',
                              MedicationSheetMode.view => 'İlaç Kaydı',
                              MedicationSheetMode.edit => 'İlacı Düzenle',
                            },
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: HealthUi.titleInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            switch (widget.mode) {
                              MedicationSheetMode.create =>
                                'Kedinizin ilaç takibini düzenli tutun.',
                              MedicationSheetMode.view => 'Kayıtlı ilaç bilgileri.',
                              MedicationSheetMode.edit =>
                                'İlaç bilgilerini güncelleyin.',
                            },
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
                  label: 'Kedi',
                  child: _readOnly
                      ? _ReadOnlyField(value: _catLabel(_catId))
                      : DropdownButtonFormField<int>(
                          initialValue: _catId,
                          hint: const Text('Kedi seçin'),
                          items: widget.cats
                              .map(
                                (c) => DropdownMenuItem<int>(
                                  value: c.catId,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (v) => setState(() => _catId = v),
                          decoration: _inputDecoration(hint: 'Kedi seçin'),
                        ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'İlaç Adı',
                  child: _readOnly
                      ? _ReadOnlyField(value: _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim())
                      : UserTextField(
                          controller: _nameCtrl,
                          decoration: _inputDecoration(hint: 'Örn. Antibiyotik'),
                        ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Dozaj',
                  child: _readOnly
                      ? _ReadOnlyField(value: _dosageCtrl.text.trim().isEmpty ? '—' : _dosageCtrl.text.trim())
                      : UserTextField(
                          controller: _dosageCtrl,
                          decoration: _inputDecoration(hint: 'Örn. 250 mg'),
                        ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Sıklık',
                  child: _readOnly
                      ? _ReadOnlyField(value: _frequency.segmentTr)
                      : _FrequencySegments(
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
                          readOnly: _readOnly,
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
                          readOnly: _readOnly,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Notlar',
                  child: _readOnly
                      ? _ReadOnlyField(
                          value: _notesCtrl.text.trim().isEmpty ? '—' : _notesCtrl.text.trim(),
                          minLines: 3,
                        )
                      : UserTextField(
                          controller: _notesCtrl,
                          kind: UserTextInputKind.multiline,
                          minLines: 3,
                          maxLines: 5,
                          decoration: _inputDecoration(
                            hint: 'Örn. Tok karnına, ek bilgi (isteğe bağlı)',
                          ),
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
                if (!_readOnly) ...[
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.value,
    this.minLines = 1,
  });

  final String value;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _inputDecoration(hint: ''),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          maxLines: minLines > 1 ? minLines + 2 : 1,
          overflow: TextOverflow.visible,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: HealthUi.titleInk,
          ),
        ),
      ),
    );
  }
}

MedicationFrequency _frequencyFromKey(String key) {
  final k = key.trim();
  return switch (k) {
    'daily' => MedicationFrequency.daily,
    'weekly' => MedicationFrequency.weekly,
    'asNeeded' => MedicationFrequency.asNeeded,
    _ => MedicationFrequency.daily,
  };
}

String _frequencyKey(MedicationFrequency f) => switch (f) {
      MedicationFrequency.daily => 'daily',
      MedicationFrequency.weekly => 'weekly',
      MedicationFrequency.asNeeded => 'asNeeded',
    };

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
  const _DateField({
    required this.value,
    required this.onTap,
    this.readOnly = false,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: readOnly ? null : onTap,
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
            if (!readOnly) HealthUi.calendarIcon(),
          ],
        ),
      ),
    );
  }
}
