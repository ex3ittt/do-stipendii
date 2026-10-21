import 'package:do_stipendii/domain/budget.dart';
import 'package:do_stipendii/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 15);
  final payday = DateTime(2026, 10, 25); // 10 days: 15th..24th
  Spend spend(int rub, DateTime at, [String note = '']) => Spend(id: '$rub$at', amount: rub * 100, note: note, at: at);

  group('money', () {
    test('formats with spaces and kopecks only when needed', () {
      expect(formatRub(125000), '1\u00a0250\u00a0₽');
      expect(formatRub(125050), '1\u00a0250,50\u00a0₽');
      expect(formatRub(-30000), '−300\u00a0₽');
      expect(formatShare(59933), '599\u00a0₽');
    });

    test('parses what people type', () {
      expect(parseRub('350'), 35000);
      expect(parseRub('1 250'), 125000);
      expect(parseRub('99,9'), 9990);
      expect(parseRub('1250.50 ₽'), 125050);
      expect(parseRub('0'), null);
      expect(parseRub('abc'), null);
    });
  });

  group('daily limit', () {
    test('splits the balance evenly over the days left', () {
      final plan = Plan(balance: 500000, start: start, payday: payday);
      expect(plan.daysLeft(start), 10);
      expect(plan.limitOn(start), 50000);
    });

    test('keeps the reserve out of the daily money', () {
      final plan = Plan(balance: 500000, reserve: 100000, start: start, payday: payday);
      expect(plan.limitOn(start), 40000);
    });

    test('overspending today shrinks tomorrow, saving makes it roomier', () {
      final over = Plan(balance: 500000, start: start, payday: payday, spends: [spend(950, start)]);
      expect(over.leftToday(start), -45000);
      expect(over.limitOn(DateTime(2026, 10, 16)), 45000); // (5000-950)/9

      final thrifty = Plan(balance: 500000, start: start, payday: payday, spends: [spend(140, start)]);
      expect(thrifty.limitOn(DateTime(2026, 10, 16)), 54000); // (5000-140)/9 = 540
    });

    test('tomorrow if I stop now', () {
      final plan = Plan(balance: 500000, start: start, payday: payday, spends: [spend(200, start)]);
      expect(plan.tomorrowIfStopNow(start), (480000 / 9).floor());
    });

    test('the last day gets everything that is left', () {
      final plan = Plan(balance: 500000, start: start, payday: payday, spends: [spend(4000, start)]);
      expect(plan.limitOn(DateTime(2026, 10, 24)), 100000);
      expect(plan.tomorrowIfStopNow(DateTime(2026, 10, 24)), 0);
    });

    test('no negative limits when the money is gone', () {
      final plan = Plan(balance: 100000, start: start, payday: payday, spends: [spend(2000, start)]);
      expect(plan.limitOn(DateTime(2026, 10, 18)), 0);
    });

    test('a spend late at night still belongs to its day', () {
      final plan = Plan(balance: 500000, start: start, payday: payday, spends: [spend(100, DateTime(2026, 10, 15, 23, 59))]);
      expect(plan.spentOn(start), 10000);
      expect(plan.spentBefore(DateTime(2026, 10, 16)), 10000);
    });
  });

  group('strip and streak', () {
    final today = DateTime(2026, 10, 19);
    final plan = Plan(balance: 500000, start: start, payday: payday, spends: [
      spend(300, DateTime(2026, 10, 15)),
      spend(800, DateTime(2026, 10, 16)), // over
      spend(400, DateTime(2026, 10, 17)),
      spend(450, DateTime(2026, 10, 18)),
    ]);

    test('one tile per day until payday, with past, today and ahead', () {
      final days = plan.strip(today);
      expect(days, hasLength(10));
      expect(days.map((d) => d.state).toList(), [
        DayState.under,
        DayState.over,
        DayState.under,
        DayState.under,
        DayState.today,
        ...List.filled(5, DayState.ahead),
      ]);
    });

    test('streak counts days within the limit back from yesterday', () {
      expect(plan.streak(today), 2);
    });

    test('survives a round trip through JSON', () {
      final copy = Plan.fromJson(plan.toJson());
      expect(copy.limitOn(today), plan.limitOn(today));
      expect(copy.spends, hasLength(4));
    });

    test('knows when the period is over', () {
      expect(plan.isOver(payday), isTrue);
      expect(plan.isOver(today), isFalse);
    });
  });
}
