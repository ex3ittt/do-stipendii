import 'package:intl/intl.dart';

String plural(int n, String one, String few, String many) {
  final m10 = n % 10;
  final m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

String days(int n) => '$n ${plural(n, 'день', 'дня', 'дней')}';

final dayMonth = DateFormat('d MMMM', 'ru');
const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

/// intl can't format two-letter weekdays, so this is spelled out.
String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];
final time = DateFormat('HH:mm', 'ru');
