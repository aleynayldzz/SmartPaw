import '../utils/turkish_date_format.dart';

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
      vaccinationDate: parseApiCalendarDate(json['vaccination_date'])!,
      nextVaccinationDate: parseApiCalendarDate(json['next_due_date']),
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
    this.id,
    required this.catId,
    required this.visitDate,
    required this.reason,
    required this.weightKg,
    this.catName,
    this.doctorNotes = '',
    this.nextVisitDate,
  });

  final int? id;
  final int catId;
  final String? catName;
  final DateTime visitDate;
  final String reason;
  final double weightKg;
  final String doctorNotes;
  final DateTime? nextVisitDate;

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _parseWeight(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory VetAppointmentRecord.fromJson(Map<String, dynamic> json) {
    return VetAppointmentRecord(
      id: _parseId(json['visit_id']),
      catId: _parseId(json['cat_id']) ?? 0,
      catName: json['cat_name']?.toString(),
      visitDate: parseApiCalendarDate(json['visit_date'])!,
      reason: json['reason']?.toString() ?? '',
      weightKg: _parseWeight(json['weight']),
      doctorNotes: json['doctor_notes']?.toString() ?? '',
      nextVisitDate: parseApiCalendarDate(json['next_visit_date']),
    );
  }

  bool get isUpcoming {
    final next = nextVisitDate;
    if (next == null) return false;
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final due = DateTime(next.year, next.month, next.day);
    return !due.isBefore(end);
  }
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

class MedicationScheduleRecord {
  MedicationScheduleRecord({
    required this.scheduleId,
    required this.reminderTime,
    this.isActive = true,
    this.isTakenToday = false,
  });

  final int scheduleId;
  final String reminderTime; // HH:MM:SS
  final bool isActive;
  final bool isTakenToday;

  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == true) return true;
    if (value == false || value == null) return false;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    return s == 'true' || s == '1';
  }

  factory MedicationScheduleRecord.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleRecord(
      scheduleId: _parseId(json['schedule_id']),
      reminderTime: json['reminder_time']?.toString() ?? '00:00:00',
      isActive: _parseBool(json['is_active']),
      isTakenToday: _parseBool(json['is_taken_today']),
    );
  }
}

class MedicationRecord {
  MedicationRecord({
    this.id,
    required this.catId,
    this.catName,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    this.notes = '',
    this.isActive = true,
    this.schedules = const [],
  });

  final int? id;
  final int catId;
  final String? catName;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
  final bool isActive;
  // schedules are kept for backward compatibility; day-based tracking uses is_taken_today via schedule endpoint.
  final List<MedicationScheduleRecord> schedules;

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

  factory MedicationRecord.fromJson(Map<String, dynamic> json) {
    final schedRaw = json['schedules'];
    final schedules = (schedRaw is List)
        ? schedRaw
            .whereType<Map>()
            .map((e) =>
                MedicationScheduleRecord.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <MedicationScheduleRecord>[];

    return MedicationRecord(
      id: _parseId(json['medication_id']),
      catId: _parseId(json['cat_id']) ?? 0,
      catName: json['cat_name']?.toString(),
      name: json['medication_name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? '',
      startDate: parseApiCalendarDate(json['start_date']) ?? DateTime.now(),
      endDate: parseApiCalendarDate(json['end_date']) ?? DateTime.now(),
      notes: json['notes']?.toString() ?? '',
      isActive: _parseBool(json['is_active']),
      schedules: schedules,
    );
  }

  int get daysRemaining {
    final today = DateTime.now();
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final now = DateTime(today.year, today.month, today.day);
    return end.difference(now).inDays.clamp(0, 9999);
  }

  String get displayTitle {
    final d = dosage.trim();
    if (d.isEmpty) return name;
    return '$name $d';
  }
}
