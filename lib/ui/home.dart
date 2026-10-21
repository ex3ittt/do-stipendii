import 'package:flutter/material.dart';

import '../domain/budget.dart';
import '../domain/money.dart';
import 'palette.dart';
import 'spend_sheet.dart';
import 'strip.dart';
import 'words.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.plan,
    required this.today,
    required this.onSpend,
    required this.onRemove,
    required this.onEdit,
  });

  final Plan plan;
  final DateTime today;
  final void Function(Kopecks amount, String note) onSpend;
  final void Function(Spend spend) onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final left = plan.leftToday(today);
    final limit = plan.limitOn(today);
    final daysLeft = plan.daysLeft(today);
    final streak = plan.streak(today);
    final todays = plan.spends.where((s) => daysBetween(today, s.at) == 0).toList().reversed.toList();
    final over = left < 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'До стипендии ${days(daysLeft)}',
                        style: TextStyle(fontSize: 16, color: p.muted, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(onPressed: onEdit, icon: const Icon(Icons.tune_rounded), tooltip: 'Пересчитать'),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 6),
                child: _BigAmount(value: left, over: over),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                child: Text(
                  over
                      ? 'Сегодняшние ${formatShare(limit)} уже потрачены. Если остановиться сейчас, завтра будет ${formatShare(plan.tomorrowIfStopNow(today))}.'
                      : left == limit
                          ? 'можно потратить сегодня'
                          : 'осталось на сегодня из ${formatShare(limit)}',
                  style: TextStyle(fontSize: over ? 16 : 18, color: over ? p.over : p.muted, height: 1.35),
                ),
              ),
            ),
            SliverToBoxAdapter(child: DayStrip(days: plan.strip(today))),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Text(
                  [
                    'На всё до стипендии ${formatRub(plan.remaining())}',
                    if (plan.reserve > 0) 'отложено ${formatRub(plan.reserve)}',
                    if (streak >= 2) '${days(streak)} подряд в лимите',
                  ].join(', '),
                  style: TextStyle(fontSize: 14, color: p.muted, height: 1.4),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Text('Сегодня', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ),
            if (todays.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Text('Трат пока нет. Записывай сразу, как заплатил, — так лимит будет честным.', style: TextStyle(color: p.muted, height: 1.4)),
                ),
              )
            else
              SliverList.builder(
                itemCount: todays.length,
                itemBuilder: (context, i) {
                  final s = todays[i];
                  return Dismissible(
                    key: ValueKey(s.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: p.over,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) => onRemove(s),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 52, child: Text(time.format(s.at), style: TextStyle(color: p.muted, fontFeatures: const [FontFeature.tabularFigures()]))),
                          Expanded(child: Text(s.note, style: const TextStyle(fontSize: 17))),
                          Text(formatRub(s.amount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: FilledButton(
          onPressed: () async {
            final r = await askSpend(context, leftToday: left);
            if (r != null) onSpend(r.$1, r.$2);
          },
          child: const Text('Записать трату'),
        ),
      ),
    );
  }
}

/// The day's money, set big. Counts to the new value when it changes so the
/// effect of a spend is visible, not just its result.
class _BigAmount extends StatelessWidget {
  const _BigAmount({required this.value, required this.over});

  final Kopecks value;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          formatRub((v / 100).round() * 100),
          style: TextStyle(
            fontSize: 76,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
            color: over ? p.over : p.ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
