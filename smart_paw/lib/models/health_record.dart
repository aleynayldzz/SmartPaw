// Sağlık sekmesi için yerel kayıt modelleri (frontend; API sonra bağlanabilir).

class VaccineRecord {
  VaccineRecord({
    String? id,
    required this.name,
    required this.vaccinationDate,
    this.nextVaccinationDate,
    this.reminderEnabled = false,
    this.notes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final String name;
  final DateTime vaccinationDate;
  final DateTime? nextVaccinationDate;
  final bool reminderEnabled;
  final String notes;
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
