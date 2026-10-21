import 'package:intl/intl.dart';

/// Money is kept in whole kopecks: floating-point rubles drift, and a daily
/// limit that is off by a kopeck never adds back up to the balance.
typedef Kopecks = int;

final _whole = NumberFormat.decimalPattern('ru');

/// "1 250 ₽", or "1 250,50 ₽" when there are kopecks. Negative → "−300 ₽".
/// Spaces are non-breaking, so "1 500 ₽" never splits across two lines.
String formatRub(Kopecks k) {
  final sign = k < 0 ? '−' : '';
  final abs = k.abs();
  final rub = _whole.format(abs ~/ 100).replaceAll(RegExp(r'[\s,]'), ' ');
  final kop = abs % 100;
  return kop == 0 ? '$sign$rub ₽' : '$sign$rub,${kop.toString().padLeft(2, '0')} ₽';
}

/// Daily shares are shown in whole rubles, rounded down — "599 ₽", not
/// "599,33 ₽"; the kopecks stay in the maths.
String formatShare(Kopecks k) => formatRub(k - k % 100);

/// Parses what people type: "350", "1 250", "99,9", "1250.50 ₽".
Kopecks? parseRub(String input) {
  final cleaned = input.replaceAll(RegExp(r'[\s ₽]|руб\.?'), '').replaceAll(',', '.');
  final m = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (m == null) return null;
  final k = int.parse(m[1]!) * 100 + int.parse((m[2] ?? '').padRight(2, '0'));
  return k > 0 ? k : null;
}
