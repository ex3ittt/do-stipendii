import 'package:flutter/material.dart';

import '../domain/budget.dart';
import '../domain/money.dart';
import 'palette.dart';
import 'words.dart';

/// First launch and «новый период»: how much money, when the stipend comes,
/// what to leave untouched.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, this.current, required this.today, required this.onDone, this.onCancel});

  final Plan? current;
  final DateTime today;
  final ValueChanged<Plan> onDone;
  final VoidCallback? onCancel;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final _balance = TextEditingController(text: widget.current == null ? '' : _plain(widget.current!.remaining() + widget.current!.reserve));
  late final _reserve = TextEditingController(text: (widget.current?.reserve ?? 0) > 0 ? _plain(widget.current!.reserve) : '');
  late DateTime _payday = _defaultPayday();
  String? _error;

  static String _plain(Kopecks k) => (k % 100 == 0 ? '${k ~/ 100}' : (k / 100).toStringAsFixed(2)).replaceAll('.', ',');

  DateTime _defaultPayday() {
    final cur = widget.current;
    if (cur != null && daysBetween(widget.today, cur.payday) > 0) return dayOf(cur.payday);
    // Same date next month is a reasonable first guess; the user picks the real one.
    final t = widget.today;
    return DateTime(t.year, t.month + 1, t.day.clamp(1, 28));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _payday,
      firstDate: widget.today.add(const Duration(days: 1)),
      lastDate: widget.today.add(const Duration(days: 120)),
      helpText: 'Когда придёт стипендия',
    );
    if (picked != null) setState(() => _payday = picked);
  }

  void _done() {
    final balance = parseRub(_balance.text);
    final reserve = _reserve.text.trim().isEmpty ? 0 : parseRub(_reserve.text);
    setState(() {
      if (balance == null) {
        _error = 'Напиши сумму, например 6 500';
      } else if (reserve == null) {
        _error = 'Отложенную сумму не получается прочитать';
      } else if (reserve >= balance) {
        _error = 'Отложить можно меньше, чем есть сейчас';
      } else {
        _error = null;
      }
    });
    if (_error != null) return;
    final today = dayOf(widget.today);
    // Spends made today stay, so the daily picture isn't lost on edit.
    final todays = widget.current?.spends.where((s) => daysBetween(today, s.at) == 0).toList() ?? const <Spend>[];
    final spentToday = todays.fold(0, (a, s) => a + s.amount);
    widget.onDone(Plan(balance: balance! + spentToday, reserve: reserve!, start: today, payday: _payday, spends: todays));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final left = daysBetween(widget.today, _payday);
    return Scaffold(
      appBar: widget.onCancel == null
          ? null
          : AppBar(backgroundColor: p.paper, leading: IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel, tooltip: 'Закрыть')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text(widget.current == null ? 'До стипендии' : 'Пересчитать', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.05)),
            const SizedBox(height: 10),
            Text(
              'Скажи, сколько денег есть и когда придёт стипендия. Я поделю их по дням и буду пересчитывать после каждой траты.',
              style: TextStyle(fontSize: 16, color: p.muted, height: 1.4),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _balance,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(labelText: 'Сколько денег сейчас', suffixText: '₽'),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Когда стипендия'),
                child: Text('${dayMonth.format(_payday)}, через ${days(left)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reserve,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(labelText: 'Отложить и не трогать', hintText: 'например, на проездной', suffixText: '₽'),
            ),
            SizedBox(height: 40, child: _error == null ? null : Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: TextStyle(color: p.over)))),
            FilledButton(onPressed: _done, child: const Text('Посчитать')),
          ],
        ),
      ),
    );
  }
}
