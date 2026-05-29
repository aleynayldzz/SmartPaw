import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/vaccine_names.dart';
import '../../models/health_record.dart';
import '../../utils/turkish_date_format.dart';
import 'health_ui.dart';

/// Kediler listesi — kullanıcının kayıtlı kedileri (yalnızca isim).
class VaccineCatOption {
  const VaccineCatOption({required this.catId, required this.name});

  final int catId;
  final String name;
}

enum VaccineSheetMode { create, view, edit }

/// Aşı kaydı ekleme / görüntüleme / düzenleme — alt sayfa formu.
class AddVaccineSheet extends StatefulWidget {
  const AddVaccineSheet({
    super.key,
    required this.cats,
    this.initial,
    this.mode = VaccineSheetMode.create,
  });

  final List<VaccineCatOption> cats;
  final VaccineRecord? initial;
  final VaccineSheetMode mode;

  bool get readOnly => mode == VaccineSheetMode.view;

  @override
  State<AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<AddVaccineSheet> {
  final _notesCtrl = TextEditingController();

  int? _selectedCatId;
  String? _selectedVaccine;
  DateTime? _vaccinationDate;
  DateTime? _nextVaccinationDate;
  bool _reminderEnabled = true;
  String? _validationMessage;
  Timer? _validationTimer;

  bool get _readOnly => widget.readOnly;

  String get _title {
    return switch (widget.mode) {
      VaccineSheetMode.create => 'Yeni Aşı Kaydı',
      VaccineSheetMode.view => 'Aşı Kaydı',
      VaccineSheetMode.edit => 'Aşı Kaydını Düzenle',
    };
  }

  String get _subtitle {
    return switch (widget.mode) {
      VaccineSheetMode.create =>
        'Hangi kedi için kayıt oluşturduğunuzu seçin.',
      VaccineSheetMode.view => 'Kayıtlı aşı bilgileri.',
      VaccineSheetMode.edit => 'Bilgileri güncelleyip kaydedin.',
    };
  }

  List<String> get _vaccineOptions {
    final current = _selectedVaccine ?? widget.initial?.name;
    if (current != null &&
        current.isNotEmpty &&
        !kVaccineNameOptions.contains(current)) {
      return [current, ...kVaccineNameOptions];
    }
    return kVaccineNameOptions;
  }

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _selectedCatId = ini.catId;
      _selectedVaccine = ini.name;
      _vaccinationDate = ini.vaccinationDate;
      _nextVaccinationDate = ini.nextVaccinationDate;
      _reminderEnabled = ini.reminderEnabled;
      _notesCtrl.text = ini.notes;
      _syncReminderForNextDate();
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Gelecek aşı tarihi bugünden önceyse hatırlatıcı kapatılır.
  void _syncReminderForNextDate() {
    final next = _nextVaccinationDate;
    if (next == null) return;
    final nextDay = DateTime(next.year, next.month, next.day);
    if (nextDay.isBefore(_today)) {
      _reminderEnabled = false;
    }
  }

  bool get _nextDateIsPast {
    final next = _nextVaccinationDate;
    if (next == null) return false;
    final nextDay = DateTime(next.year, next.month, next.day);
    return nextDay.isBefore(_today);
  }

  bool get _effectiveReminderEnabled =>
      _nextDateIsPast ? false : _reminderEnabled;

  @override
  void dispose() {
    _validationTimer?.cancel();
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

  bool _hasRequiredFields() {
    return _selectedCatId != null &&
        _selectedCatId! > 0 &&
        _selectedVaccine != null &&
        _selectedVaccine!.isNotEmpty &&
        _vaccinationDate != null;
  }

  Future<void> _pickDate({
    required bool isNext,
    DateTime? initial,
  }) async {
    if (_readOnly) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    late final DateTime firstDate;
    late final DateTime lastDate;

    if (isNext) {
      final admin = _vaccinationDate ?? today;
      firstDate = DateTime(admin.year, admin.month, admin.day).add(
        const Duration(days: 1),
      );
      lastDate = DateTime(now.year + 10);
    } else {
      firstDate = DateTime(now.year - 10);
      lastDate = today;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _clampDate(
        initial ?? (isNext ? firstDate : today),
        firstDate,
        lastDate,
      ),
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('tr'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isNext) {
        _nextVaccinationDate = picked;
        _syncReminderForNextDate();
      } else {
        _vaccinationDate = picked;
        if (_nextVaccinationDate != null) {
          final admin = DateTime(picked.year, picked.month, picked.day);
          final next = DateTime(
            _nextVaccinationDate!.year,
            _nextVaccinationDate!.month,
            _nextVaccinationDate!.day,
          );
          if (!next.isAfter(admin)) {
            _nextVaccinationDate = null;
          }
        }
        _syncReminderForNextDate();
      }
    });
  }

  DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
    if (value.isBefore(min)) return min;
    if (value.isAfter(max)) return max;
    return value;
  }

  void _save() {
    if (_readOnly) return;

    if (!_hasRequiredFields()) {
      _showRequiredFieldsSnack();
      return;
    }

    final admin = _vaccinationDate!;
    final adminDay = DateTime(admin.year, admin.month, admin.day);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    if (adminDay.isAfter(todayDay)) {
      _showRequiredFieldsSnack();
      return;
    }

    final next = _nextVaccinationDate;
    if (next != null) {
      final nextDay = DateTime(next.year, next.month, next.day);
      if (!nextDay.isAfter(adminDay)) {
        setState(
          () => _validationMessage =
              'Sonraki aşı tarihi, aşılanma tarihinden sonra olmalıdır.',
        );
        _validationTimer?.cancel();
        _validationTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _validationMessage = null);
        });
        return;
      }
    }

    var reminderEnabled = _reminderEnabled;
    if (next != null) {
      final nextDay = DateTime(next.year, next.month, next.day);
      if (nextDay.isBefore(_today)) {
        reminderEnabled = false;
      }
    }

    Navigator.pop(
      context,
      VaccineRecord(
        id: widget.initial?.id,
        catId: _selectedCatId!,
        name: _selectedVaccine!,
        vaccinationDate: admin,
        nextVaccinationDate: next,
        reminderEnabled: reminderEnabled,
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
                            _title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: HealthUi.titleInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitle,
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
                  label: 'Kedi Adı',
                  child: _readOnly
                      ? _ReadOnlyField(
                          value: _catLabel(_selectedCatId),
                        )
                      : InputDecorator(
                          decoration: _inputDecoration(hint: 'Kedi seçin'),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedCatId,
                              isExpanded: true,
                              hint: Text(
                                'Kedi seçin',
                                style: TextStyle(
                                  color: HealthUi.muted.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: HealthUi.muted.withValues(alpha: 0.8),
                              ),
                              items: widget.cats
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.catId,
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: HealthUi.titleInk,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCatId = v),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Aşı Adı',
                  child: _readOnly
                      ? _ReadOnlyField(value: _selectedVaccine ?? '—')
                      : InputDecorator(
                          decoration: _inputDecoration(hint: 'Aşı seçin'),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedVaccine,
                              isExpanded: true,
                              hint: Text(
                                'Aşı seçin',
                                style: TextStyle(
                                  color: HealthUi.muted.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: HealthUi.muted.withValues(alpha: 0.8),
                              ),
                              items: _vaccineOptions
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: HealthUi.titleInk,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedVaccine = v),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Aşılanma Tarihi',
                  child: _DateField(
                    value: _vaccinationDate,
                    readOnly: _readOnly,
                    onTap: () =>
                        _pickDate(isNext: false, initial: _vaccinationDate),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'Gelecek Aşı Tarihi',
                        child: _DateField(
                          value: _nextVaccinationDate,
                          readOnly: _readOnly,
                          emptyLabel: 'Belirtilmedi',
                          onTap: () {
                            if (_vaccinationDate == null) {
                              _showRequiredFieldsSnack();
                              return;
                            }
                            _pickDate(
                              isNext: true,
                              initial: _nextVaccinationDate,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hatırlatıcı',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: HealthUi.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AbsorbPointer(
                          absorbing: _readOnly,
                          child: Switch(
                            value: _effectiveReminderEnabled,
                            onChanged: (v) {
                              if (v && _nextDateIsPast) return;
                              setState(() => _reminderEnabled = v);
                            },
                            activeTrackColor:
                                HealthUi.accentPink.withValues(alpha: 0.5),
                            activeThumbColor: HealthUi.accentPink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Notlar',
                  child: _readOnly
                      ? _ReadOnlyField(
                          value: _notesCtrl.text.trim().isEmpty
                              ? '—'
                              : _notesCtrl.text.trim(),
                          minLines: 3,
                        )
                      : TextField(
                          controller: _notesCtrl,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                            hint: 'Ek bilgi (isteğe bağlı)',
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

  String _catLabel(int? catId) {
    if (catId == null) return '—';
    for (final c in widget.cats) {
      if (c.catId == catId) return c.name;
    }
    return widget.initial?.catName ?? '—';
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
    this.emptyLabel = 'Tarih seçin',
  });

  final DateTime? value;
  final VoidCallback onTap;
  final bool readOnly;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final label =
        value != null ? formatTurkishDate(value!) : emptyLabel;

    return InkWell(
      onTap: readOnly ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _inputDecoration(hint: emptyLabel),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: value != null ? HealthUi.titleInk : HealthUi.muted,
                ),
              ),
            ),
            if (!readOnly)
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
