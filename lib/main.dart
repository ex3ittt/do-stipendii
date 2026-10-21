import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'domain/budget.dart';
import 'domain/store.dart';
import 'ui/home.dart';
import 'ui/palette.dart';
import 'ui/setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  runApp(App(store: PlanStore()));
}

class App extends StatefulWidget {
  const App({super.key, required this.store, this.clock = DateTime.now});

  final PlanStore store;
  final DateTime Function() clock;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  Plan? _plan;
  bool _loaded = false;
  bool _editing = false;
  late DateTime _today = dayOf(widget.clock());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.load().then((p) => setState(() {
          _plan = p;
          _loaded = true;
        }));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back to the app the next morning should show the next day.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() => _today = dayOf(widget.clock()));
  }

  void _save(Plan plan) {
    setState(() {
      _plan = plan;
      _editing = false;
    });
    unawaited(widget.store.save(plan));
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    Widget screen;
    if (!_loaded) {
      screen = const Scaffold(body: SizedBox.shrink());
    } else if (plan == null || _editing || plan.isOver(_today)) {
      screen = SetupScreen(
        current: plan,
        today: _today,
        onDone: _save,
        onCancel: plan != null && !plan.isOver(_today) ? () => setState(() => _editing = false) : null,
      );
    } else {
      screen = HomeScreen(
        plan: plan,
        today: _today,
        onSpend: (amount, note) {
          final now = widget.clock();
          final id = '${now.microsecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
          _save(plan.copyWith(spends: [...plan.spends, Spend(id: id, amount: amount, note: note, at: now)]));
        },
        onRemove: (s) => _save(plan.copyWith(spends: plan.spends.where((x) => x.id != s.id).toList())),
        onEdit: () => setState(() => _editing = true),
      );
    }

    return MaterialApp(
      title: 'До стипендии',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Palette.light, Brightness.light),
      darkTheme: buildTheme(Palette.dark, Brightness.dark),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: KeyedSubtree(key: ValueKey(screen.runtimeType), child: screen)),
    );
  }
}
