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

String formatTurkishDateTime(DateTime dateTime) {
  final h = dateTime.hour.toString().padLeft(2, '0');
  final m = dateTime.minute.toString().padLeft(2, '0');
  return '${formatTurkishDate(dateTime)} - $h:$m';
}
