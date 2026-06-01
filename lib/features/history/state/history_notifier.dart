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
      // Iniciar con datos de ejemplo ficticios para que el prototipo no se vea vacío y la gráfica tenga aspecto premium
      final mockRecords = [
        WorkoutRecord(
          id: '1',
          exerciseName: 'Press de Banca',
          weight: 70.0,
          reps: 8,
          oneRepMax: 88.6,
          date: DateTime.now().subtract(const Duration(days: 20)),
          unit: 'kg',
          formula: 'epley',
        ),
        WorkoutRecord(
          id: '2',
          exerciseName: 'Press de Banca',
          weight: 75.0,
          reps: 6,
          oneRepMax: 90.0,
          date: DateTime.now().subtract(const Duration(days: 10)),
          unit: 'kg',
          formula: 'epley',
        ),
        WorkoutRecord(
          id: '3',
          exerciseName: 'Press de Banca',
          weight: 80.0,
          reps: 5,
          oneRepMax: 93.3,
          date: DateTime.now().subtract(const Duration(days: 2)),
          unit: 'kg',
          formula: 'epley',
        ),
      ];
      state = mockRecords;
      _saveToPrefs(mockRecords);
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
  }) async {
    final newRecord = WorkoutRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseName: exerciseName.trim(),
      weight: weight,
      reps: reps,
      oneRepMax: oneRepMax,
      date: DateTime.now(),
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
