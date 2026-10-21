import 'package:flutter/material.dart';

import '../domain/budget.dart';
import 'palette.dart';
import 'words.dart';

/// Every day of the period as a small column. A finished day fills up to the
/// share of its limit that was spent — green if it fit, red if it didn't.
/// Today is outlined; the days ahead are empty.
class DayStrip extends StatelessWidget {
  const DayStrip({super.key, required this.days});

  final List<Day> days;

  @override
  Widget build(BuildContext context) {
    final todayIndex = days.indexWhere((d) => d.state == DayState.today);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // Start scrolled so that today and most of the week behind it are in view.
        controller: ScrollController(initialScrollOffset: todayIndex > 6 ? (todayIndex - 6) * 42.0 : 0),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) => _Tile(day: days[i]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.day});

  final Day day;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isToday = day.state == DayState.today;
    final done = day.state == DayState.under || day.state == DayState.over;
    final share = day.limit <= 0 ? (day.spent > 0 ? 1.0 : 0.0) : (day.spent / day.limit).clamp(0.0, 1.0);
    final fill = day.state == DayState.over ? p.over : p.accentSoft;
    final weekend = day.date.weekday >= 6;

    return Semantics(
      label: '${dayMonth.format(day.date)}: ${switch (day.state) {
        DayState.under => 'в лимите',
        DayState.over => 'перерасход',
        DayState.today => 'сегодня',
        DayState.ahead => 'впереди',
      }}',
      child: SizedBox(
        width: 36,
        child: Column(
          children: [
            Text(
              weekdayShort(day.date),
              style: TextStyle(fontSize: 12, color: weekend ? p.ink : p.muted, fontWeight: weekend ? FontWeight.w600 : FontWeight.w400),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday ? p.ink : (done ? Colors.transparent : p.line),
                    width: isToday ? 2 : 1.5,
                  ),
                  color: done ? p.line.withValues(alpha: 0.55) : null,
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: isToday ? share : (done ? share : 0),
                  widthFactor: 1,
                  child: ColoredBox(color: isToday && day.spent > day.limit ? p.over : fill),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${day.date.day}',
              style: TextStyle(fontSize: 13, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500, color: isToday ? p.ink : p.muted),
            ),
          ],
        ),
      ),
    );
  }
}
