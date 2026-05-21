import 'package:flutter/material.dart';

import '../../data/vaccine_names.dart';
import '../../models/health_record.dart';
import '../../utils/turkish_date_format.dart';
import 'health_ui.dart';

/// Yeni aşı kaydı — alt sayfa formu.
class AddVaccineSheet extends StatefulWidget {
  const AddVaccineSheet({super.key});

  @override
  State<AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<AddVaccineSheet> {
  final _notesCtrl = TextEditingController();

  String? _selectedVaccine;
  DateTime? _vaccinationDate;
  DateTime? _nextVaccinationDate;
  bool _reminderEnabled = true;

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
        _nextVaccinationDate = picked;
      } else {
        _vaccinationDate = picked;
      }
    });
  }

  void _save() {
    final name = _selectedVaccine;
    if (name == null || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aşı seçin.')),
      );
      return;
    }
    if (_vaccinationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aşılanma tarihini seçin.')),
      );
      return;
    }

    Navigator.pop(
      context,
      VaccineRecord(
        name: name,
        vaccinationDate: _vaccinationDate!,
        nextVaccinationDate: _nextVaccinationDate,
        reminderEnabled: _reminderEnabled,
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
                          const Text(
                            'Yeni Aşı Kaydı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: HealthUi.titleInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kedinizin aşı geçmişini düzenli tutun.',
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
                  label: 'Aşı Adı',
                  child: InputDecorator(
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
                        items: kVaccineNameOptions
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
                        onChanged: (v) => setState(() => _selectedVaccine = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'Aşılanma Tarihi',
                  child: _DateField(
                    value: _vaccinationDate,
                    onTap: () => _pickDate(isNext: false, initial: _vaccinationDate),
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
                          onTap: () => _pickDate(
                            isNext: true,
                            initial: _nextVaccinationDate ?? _vaccinationDate,
                          ),
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
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (v) => setState(() => _reminderEnabled = v),
                          activeTrackColor: HealthUi.accentPink.withValues(alpha: 0.5),
                          activeThumbColor: HealthUi.accentPink,
                        ),
                      ],
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
                    decoration: _inputDecoration(hint: 'Ek bilgi (isteğe bağlı)'),
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
            Icon(Icons.calendar_today_outlined, size: 20, color: HealthUi.muted.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}
