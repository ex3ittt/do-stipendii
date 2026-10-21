import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'budget.dart';

class PlanStore {
  static const _key = 'plan:v1';

  Future<Plan?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Plan.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } on Object {
      return null; // a broken save shouldn't brick the app — start over
    }
  }

  Future<void> save(Plan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(plan.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
