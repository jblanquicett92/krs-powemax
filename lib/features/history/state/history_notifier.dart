import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/workout_record.dart';

class HistoryNotifier extends StateNotifier<List<WorkoutRecord>> {
  HistoryNotifier() : super([]) {
    _loadRecords();
  }

  static const String _keyRecords = 'workout_records_list';

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_keyRecords);
    if (jsonStr == null) {
      state = [];
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      final records = decoded
          .map((item) => WorkoutRecord.fromJson(item as Map<String, dynamic>))
          .toList();
      // Ordenar por fecha descendente (más recientes primero)
      records.sort((a, b) => b.date.compareTo(a.date));
      state = records;
    } catch (e) {
      state = [];
    }
  }

  Future<void> addRecord({
    required String exerciseName,
    required double weight,
    required int reps,
    required double oneRepMax,
    required String unit,
    required String formula,
    DateTime? customDate,
  }) async {
    final newRecord = WorkoutRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_' + exerciseName.hashCode.toString(),
      exerciseName: exerciseName.trim(),
      weight: weight,
      reps: reps,
      oneRepMax: oneRepMax,
      date: customDate ?? DateTime.now(),
      unit: unit,
      formula: formula,
    );

    final updated = [newRecord, ...state];
    state = updated;
    await _saveToPrefs(updated);
  }

  Future<void> deleteRecord(String id) async {
    final updated = state.where((record) => record.id != id).toList();
    state = updated;
    await _saveToPrefs(updated);
  }

  Future<void> _saveToPrefs(List<WorkoutRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRecords, jsonStr);
  }
}

// Proveedor global para el historial de marcas
final historyProvider = StateNotifierProvider<HistoryNotifier, List<WorkoutRecord>>((ref) {
  return HistoryNotifier();
});
