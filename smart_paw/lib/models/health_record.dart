/// Sağlık sekmesi için yerel kayıt modelleri (frontend; API sonra bağlanabilir).

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
    required this.visitDateTime,
    required this.doctorName,
    required this.clinicName,
    required this.reason,
    this.doctorNotes = '',
    this.nextVisitDate,
  });

  final DateTime visitDateTime;
  final String doctorName;
  final String clinicName;
  final String reason;
  final String doctorNotes;
  final DateTime? nextVisitDate;
}

enum MedicationFrequency { daily, weekly, asNeeded }

class MedicationRecord {
  MedicationRecord({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    this.stillUsing = true,
    this.notes = '',
  });

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
}
