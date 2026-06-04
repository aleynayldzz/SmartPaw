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
