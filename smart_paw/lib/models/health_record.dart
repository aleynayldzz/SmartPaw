// Sağlık sekmesi kayıt modelleri.

class VaccineRecord {
  VaccineRecord({
    this.id,
    required this.catId,
    required this.name,
    required this.vaccinationDate,
    this.nextVaccinationDate,
    this.catName,
    this.reminderEnabled = false,
    this.notes = '',
  });

  final int? id;
  final int catId;
  final String? catName;
  final String name;
  final DateTime vaccinationDate;
  final DateTime? nextVaccinationDate;
  final bool reminderEnabled;
  final String notes;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.parse(s.length <= 10 ? '${s}T12:00:00.000' : s);
  }

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _parseBool(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    return s == 'true' || s == '1';
  }

  factory VaccineRecord.fromJson(Map<String, dynamic> json) {
    return VaccineRecord(
      id: _parseId(json['vaccination_id']),
      catId: _parseId(json['cat_id']) ?? 0,
      catName: json['cat_name']?.toString(),
      name: json['vaccine_name']?.toString() ?? '',
      vaccinationDate: _parseDate(json['vaccination_date'])!,
      nextVaccinationDate: _parseDate(json['next_due_date']),
      reminderEnabled: _parseBool(json['reminder_enabled']),
      notes: json['notes']?.toString() ?? '',
    );
  }

  bool get isUpcoming {
    final next = nextVaccinationDate;
    if (next == null) return false;
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final due = DateTime(next.year, next.month, next.day);
    return !due.isBefore(end);
  }
}

class VetAppointmentRecord {
  VetAppointmentRecord({
    String? id,
    required this.visitDate,
    required this.reason,
    required this.weightKg,
    this.doctorNotes = '',
    this.nextVisitDate,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final DateTime visitDate;
  final String reason;
  final double weightKg;
  final String doctorNotes;
  final DateTime? nextVisitDate;
}

enum MedicationFrequency { daily, weekly, asNeeded }

extension MedicationFrequencyLabels on MedicationFrequency {
  String get labelTr => switch (this) {
        MedicationFrequency.daily => 'Günde 1 kez',
        MedicationFrequency.weekly => 'Haftada 1 kez',
        MedicationFrequency.asNeeded => 'Gerektiğinde',
      };

  String get segmentTr => switch (this) {
        MedicationFrequency.daily => 'Günlük',
        MedicationFrequency.weekly => 'Haftalık',
        MedicationFrequency.asNeeded => 'Gerektiğinde',
      };
}

class MedicationRecord {
  MedicationRecord({
    String? id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    this.stillUsing = true,
    this.notes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String name;
  final String dosage;
  final MedicationFrequency frequency;
  final DateTime startDate;
  final DateTime endDate;
  final bool stillUsing;
  final String notes;

  int get daysRemaining {
    final today = DateTime.now();
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final now = DateTime(today.year, today.month, today.day);
    return end.difference(now).inDays.clamp(0, 9999);
  }

  bool get isActive => stillUsing && daysRemaining > 0;

  String get displayTitle {
    final d = dosage.trim();
    if (d.isEmpty) return name;
    return '$name $d';
  }
}
