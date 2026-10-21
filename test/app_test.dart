import 'package:do_stipendii/domain/budget.dart';
import 'package:do_stipendii/domain/store.dart';
import 'package:do_stipendii/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

class MemoryStore extends PlanStore {
  Plan? saved;

  @override
  Future<Plan?> load() async => saved;

  @override
  Future<void> save(Plan plan) async => saved = plan;
}

/// Matches text written with ordinary spaces against the app's non-breaking ones.
Finder rub(String text) => find.text(text.replaceAll(' ', '\u00a0'));

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('ru');
  });

  final now = DateTime(2026, 10, 15, 12, 30);

  testWidgets('first launch asks for money and payday, then shows the daily limit', (tester) async {
    final store = MemoryStore();
    await tester.pumpWidget(App(store: store, clock: () => now));
    await tester.pumpAndSettle();

    expect(find.text('До стипендии'), findsOneWidget);
    expect(find.textContaining('15 ноября, через 31 день'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '6 200');
    await tester.tap(find.text('Посчитать'));
    await tester.pumpAndSettle();

    expect(find.text('До стипендии 31 день'), findsOneWidget);
    expect(rub('200 ₽'), findsOneWidget); // 6200 / 31
    expect(find.text('можно потратить сегодня'), findsOneWidget);
    expect(store.saved?.balance, 620000);
  });

  testWidgets('a spend lowers today and warns when over', (tester) async {
    final store = MemoryStore()..saved = Plan(balance: 620000, start: DateTime(2026, 10, 15), payday: DateTime(2026, 11, 15));
    await tester.pumpWidget(App(store: store, clock: () => now));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Записать трату'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '150');
    await tester.pump();
    expect(find.text('На сегодня останется 50\u00a0₽'), findsOneWidget);
    await tester.tap(find.text('Записать'));
    await tester.pumpAndSettle();

    expect(rub('50 ₽'), findsOneWidget);
    expect(find.text('осталось на сегодня из 200\u00a0₽'), findsOneWidget);
    expect(find.text('Столовая'), findsOneWidget);

    await tester.tap(find.text('Записать трату'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '100');
    await tester.pump(); // the button enables only after the rebuild
    await tester.tap(find.text('Проезд'));
    await tester.pump();
    await tester.tap(find.text('Записать'));
    await tester.pumpAndSettle();

    expect(rub('−50 ₽'), findsOneWidget);
    expect(find.textContaining('Сегодняшние 200\u00a0₽ уже потрачены'), findsOneWidget);
    expect(store.saved?.spends, hasLength(2));
  });

  testWidgets('when payday has come it asks to start a new period', (tester) async {
    final store = MemoryStore()..saved = Plan(balance: 620000, start: DateTime(2026, 9, 15), payday: DateTime(2026, 10, 15));
    await tester.pumpWidget(App(store: store, clock: () => now));
    await tester.pumpAndSettle();
    expect(find.text('Пересчитать'), findsOneWidget);
    expect(find.byTooltip('Закрыть'), findsNothing);
  });
}
