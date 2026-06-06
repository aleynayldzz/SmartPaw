/// API'den gelen tarih — saat dilimi kayması olmadan takvim günü olarak parse edilir.
DateTime? parseApiCalendarDate(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;

  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
  if (m != null) {
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  try {
    final parsed = DateTime.parse(s);
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  } catch (_) {
    return null;
  }
}

const _turkishMonths = <String>[
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String formatTurkishDate(DateTime date) {
  return '${date.day} ${_turkishMonths[date.month - 1]} ${date.year}';
}

const _turkishMonthsShort = <String>[
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

/// Kısa ay adı — örn. "1 May 2024"
String formatTurkishDateShort(DateTime date) {
  return '${date.day} ${_turkishMonthsShort[date.month - 1]} ${date.year}';
}

/// Gün + ay — örn. "15 Haziran"
String formatTurkishDayMonth(DateTime date) {
  return '${date.day} ${_turkishMonths[date.month - 1]}';
}

String formatTurkishDateTime(DateTime dateTime) {
  final h = dateTime.hour.toString().padLeft(2, '0');
  final m = dateTime.minute.toString().padLeft(2, '0');
  return '${formatTurkishDate(dateTime)} - $h:$m';
}
