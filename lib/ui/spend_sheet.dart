import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/money.dart';
import 'palette.dart';

const quickNotes = ['Столовая', 'Проезд', 'Продукты', 'Кофе', 'Связь', 'Другое'];

/// Returns (amount, note) or null when dismissed.
Future<(Kopecks, String)?> askSpend(BuildContext context, {required Kopecks leftToday}) {
  return showModalBottomSheet<(Kopecks, String)>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.palette.paper,
    builder: (_) => _SpendSheet(leftToday: leftToday),
  );
}

class _SpendSheet extends StatefulWidget {
  const _SpendSheet({required this.leftToday});

  final Kopecks leftToday;

  @override
  State<_SpendSheet> createState() => _SpendSheetState();
}

class _SpendSheetState extends State<_SpendSheet> {
  final _amount = TextEditingController();
  String _note = quickNotes.first;

  Kopecks? get _value => parseRub(_amount.text);

  void _submit() {
    final v = _value;
    if (v == null) return;
    HapticFeedback.lightImpact();
    Navigator.pop(context, (v, _note));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = _value;
    final after = v == null ? null : widget.leftToday - v;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Сколько потрачено', style: TextStyle(fontSize: 15, color: p.muted)),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700, letterSpacing: -1),
            decoration: const InputDecoration(hintText: '0', suffixText: '₽', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          SizedBox(
            height: 22,
            child: after == null
                ? null
                : Text(
                    after >= 0 ? 'На сегодня останется ${formatShare(after)}' : 'Это больше сегодняшнего на ${formatShare(-after)}',
                    style: TextStyle(color: after >= 0 ? p.muted : p.over),
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in quickNotes)
                ChoiceChip(
                  label: Text(n),
                  selected: _note == n,
                  showCheckmark: false,
                  selectedColor: p.ink,
                  labelStyle: TextStyle(color: _note == n ? p.paper : p.ink, fontWeight: FontWeight.w500),
                  side: BorderSide(color: _note == n ? p.ink : p.line),
                  backgroundColor: p.paper,
                  onSelected: (_) => setState(() => _note = n),
                ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(onPressed: v == null ? null : _submit, child: const Text('Записать')),
        ],
      ),
    );
  }
}
