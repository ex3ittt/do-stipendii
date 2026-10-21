import 'money.dart';

/// Calendar day without time, so "today" doesn't shift at 23:59 → 00:01 math.
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

int daysBetween(DateTime a, DateTime b) => dayOf(b).difference(dayOf(a)).inHours ~/ 24;

class Spend {
  const Spend({required this.id, required this.amount, required this.note, required this.at});

  final String id;
  final Kopecks amount;
  final String note;
  final DateTime at;

  Map<String, Object> toJson() => {'id': id, 'amount': amount, 'note': note, 'at': at.toIso8601String()};

  factory Spend.fromJson(Map<String, Object?> j) =>
      Spend(id: j['id'] as String, amount: j['amount'] as int, note: j['note'] as String, at: DateTime.parse(j['at'] as String));
}

enum DayState { under, over, today, ahead }

/// One tile of the strip from the start of the period to payday.
class Day {
  const Day({required this.date, required this.limit, required this.spent, required this.state});

  final DateTime date;
  final Kopecks limit;
  final Kopecks spent;
  final DayState state;
}

/// A period from now until the stipend: how much there is, how much is put
/// aside, and what has been spent. Everything else is computed.
class Plan {
  const Plan({required this.balance, required this.start, required this.payday, this.reserve = 0, this.spends = const []});

  /// Money at the start of the period.
  final Kopecks balance;

  /// Money that must still be there on payday (rent, a trip, savings).
  final Kopecks reserve;

  final DateTime start;

  /// The day the stipend arrives; spending on that day is the next period's.
  final DateTime payday;

  final List<Spend> spends;

  Plan copyWith({Kopecks? balance, Kopecks? reserve, DateTime? start, DateTime? payday, List<Spend>? spends}) => Plan(
        balance: balance ?? this.balance,
        reserve: reserve ?? this.reserve,
        start: start ?? this.start,
        payday: payday ?? this.payday,
        spends: spends ?? this.spends,
      );

  Map<String, Object> toJson() => {
        'balance': balance,
        'reserve': reserve,
        'start': dayOf(start).toIso8601String(),
        'payday': dayOf(payday).toIso8601String(),
        'spends': spends.map((s) => s.toJson()).toList(),
      };

  factory Plan.fromJson(Map<String, Object?> j) => Plan(
        balance: j['balance'] as int,
        reserve: (j['reserve'] as int?) ?? 0,
        start: DateTime.parse(j['start'] as String),
        payday: DateTime.parse(j['payday'] as String),
        spends: [for (final s in (j['spends'] as List? ?? const [])) Spend.fromJson((s as Map).cast<String, Object?>())],
      );

  Kopecks spentOn(DateTime day) => spends.where((s) => daysBetween(day, s.at) == 0).fold(0, (a, s) => a + s.amount);

  Kopecks spentBefore(DateTime day) => spends.where((s) => daysBetween(s.at, day) > 0).fold(0, (a, s) => a + s.amount);

  Kopecks get spentTotal => spends.fold(0, (a, s) => a + s.amount);

  /// Days left including [today]; never less than one.
  int daysLeft(DateTime today) => daysBetween(today, payday).clamp(1, 1 << 20);

  bool isOver(DateTime today) => daysBetween(today, payday) <= 0;

  /// The fair share for [day]: what was left that morning, split evenly over
  /// the days still to go. Overspend yesterday → a smaller share today, and
  /// a thrifty day makes the following ones a little roomier.
  Kopecks limitOn(DateTime day) {
    final left = balance - reserve - spentBefore(day);
    if (left <= 0) return 0;
    return left ~/ daysLeft(day);
  }

  /// What can still be spent today; negative when today's share is blown.
  Kopecks leftToday(DateTime today) => limitOn(today) - spentOn(today);

  /// Tomorrow's share if nothing more is spent today.
  Kopecks tomorrowIfStopNow(DateTime today) {
    if (daysLeft(today) <= 1) return 0;
    final left = balance - reserve - spentBefore(today) - spentOn(today);
    return left <= 0 ? 0 : left ~/ (daysLeft(today) - 1);
  }

  /// Money left for the period after everything spent so far.
  Kopecks remaining() => balance - reserve - spentTotal;

  List<Day> strip(DateTime today) {
    final days = <Day>[];
    final total = daysBetween(start, payday);
    for (var i = 0; i < total; i++) {
      final d = dayOf(start).add(Duration(days: i));
      final offset = daysBetween(today, d);
      final limit = offset <= 0 ? limitOn(d) : tomorrowIfStopNow(today);
      final spent = spentOn(d);
      final state = offset < 0
          ? (spent <= limit ? DayState.under : DayState.over)
          : offset == 0
              ? DayState.today
              : DayState.ahead;
      days.add(Day(date: d, limit: limit, spent: spent, state: state));
    }
    return days;
  }

  /// Consecutive finished days within the limit, counting back from yesterday.
  int streak(DateTime today) {
    var n = 0;
    for (final d in strip(today).reversed) {
      if (d.state == DayState.today || d.state == DayState.ahead) continue;
      if (d.state == DayState.over) break;
      n++;
    }
    return n;
  }
}
