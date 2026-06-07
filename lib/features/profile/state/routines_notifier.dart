import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/routine.dart';
import '../../history/data/workout_record.dart';

import 'package:flutter/services.dart' show rootBundle;

class RoutinesNotifier extends StateNotifier<List<Routine>> {
  RoutinesNotifier() : super([]) {
    _loadRoutines();
  }

  static const String _keyRoutines = 'user_workout_routines';

  Future<void> _loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_keyRoutines);
    final defaultRoutines = await _loadDefaultRoutinesFromJson();

    List<Routine> routines;
    if (jsonStr == null) {
      routines = defaultRoutines;
    } else {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
        routines = decoded
            .map((item) => Routine.fromJson(item as Map<String, dynamic>))
            .toList();

        // MIGRACIÓN / RESET: Siempre forzamos a que las rutinas por defecto se actualicen con el contenido del JSON
        routines = routines.map((r) {
          if (r.isDefault || r.id.startsWith('default_')) {
            final targetId = r.id == 'default_arnold' ? 'default_arnold_split' : r.id;
            final matchingDefault = defaultRoutines.firstWhere(
              (dr) => dr.id == targetId,
              orElse: () => r,
            );
            // Aseguramos que conserve isDefault como true
            return matchingDefault.copyWith(isDefault: true);
          }
          return r;
        }).toList();
      } catch (e) {
        routines = defaultRoutines;
      }
    }

    final synced = await _syncOrphanExercises(routines);
    state = synced;
    await _saveToPrefsRaw(synced);
  }

  Future<List<Routine>> _loadDefaultRoutinesFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/default_routines.json');
      final Map<String, dynamic> parsed = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final List<Routine> list = [];
      parsed.forEach((key, val) {
        final data = val as Map<String, dynamic>;
        final List<dynamic> exercisesJson = data['exercises'] as List<dynamic>;
        final exercises = exercisesJson.map((e) {
          final m = e as Map<String, dynamic>;
          return RoutineExercise(
            name: m['name'] as String,
            sets: m['sets'] as int,
            reps: m['reps'] as int,
            dayGroup: m['dayGroup'] as String,
          );
        }).toList();

        list.add(
          Routine(
            id: key,
            name: data['name'] as String,
            exercises: exercises,
            dateCreated: DateTime.now(),
            isDefault: true,
          ),
        );
      });
      return list;
    } catch (e) {
      // Fallback estático en caso de que falle la lectura del asset
      return [
        Routine(
          id: 'default_push_pull',
          name: 'Rutina Empuje y Jalón',
          exercises: [
            RoutineExercise(name: 'Press de banca con barra', sets: 4, reps: 8, dayGroup: 'Empuje A (Enfoque fuerza)'),
            RoutineExercise(name: 'Press militar (hombros)', sets: 3, reps: 10, dayGroup: 'Empuje A (Enfoque fuerza)'),
            RoutineExercise(name: 'Fondos en paralelas (o máquina)', sets: 3, reps: 12, dayGroup: 'Empuje A (Enfoque fuerza)'),
            RoutineExercise(name: 'Extensiones de tríceps en polea', sets: 3, reps: 15, dayGroup: 'Empuje A (Enfoque fuerza)'),
            RoutineExercise(name: 'Press inclinado con mancuernas', sets: 4, reps: 12, dayGroup: 'Empuje B (Enfoque hipertrofia)'),
            RoutineExercise(name: 'Elevaciones laterales (hombros)', sets: 4, reps: 15, dayGroup: 'Empuje B (Enfoque hipertrofia)'),
            RoutineExercise(name: 'Press máquina o aperturas con poleas', sets: 3, reps: 15, dayGroup: 'Empuje B (Enfoque hipertrofia)'),
            RoutineExercise(name: 'Press francés (tríceps con barra Z)', sets: 3, reps: 12, dayGroup: 'Empuje B (Enfoque hipertrofia)'),
            RoutineExercise(name: 'Dominadas (o jalón al pecho en polea)', sets: 4, reps: 10, dayGroup: 'Jalón A (Enfoque fuerza/amplitud)'),
            RoutineExercise(name: 'Remo con barra (agarre supino o prono)', sets: 4, reps: 10, dayGroup: 'Jalón A (Enfoque fuerza/amplitud)'),
            RoutineExercise(name: 'Face pulls (hombro posterior)', sets: 3, reps: 15, dayGroup: 'Jalón A (Enfoque fuerza/amplitud)'),
            RoutineExercise(name: 'Curl de bíceps con barra', sets: 3, reps: 12, dayGroup: 'Jalón A (Enfoque fuerza/amplitud)'),
            RoutineExercise(name: 'Remo en polea baja (agarre cerrado)', sets: 4, reps: 12, dayGroup: 'Jalón B (Enfoque grosor/detalle)'),
            RoutineExercise(name: 'Jalón al pecho (agarre neutro)', sets: 3, reps: 12, dayGroup: 'Jalón B (Enfoque grosor/detalle)'),
            RoutineExercise(name: 'Pájaros con mancuernas (hombro posterior)', sets: 3, reps: 15, dayGroup: 'Jalón B (Enfoque grosor/detalle)'),
            RoutineExercise(name: 'Curl de bíceps martillo (con mancuernas)', sets: 3, reps: 12, dayGroup: 'Jalón B (Enfoque grosor/detalle)'),
          ],
          dateCreated: DateTime.now(),
          isDefault: true,
        ),
        Routine(
          id: 'default_arnold_split',
          name: 'Rutina Arnold Split',
          exercises: [
            RoutineExercise(name: 'Press de Banca', sets: 4, reps: 10, dayGroup: 'Día A (Pecho/Espalda)'),
            RoutineExercise(name: 'Aperturas Planas', sets: 3, reps: 12, dayGroup: 'Día A (Pecho/Espalda)'),
            RoutineExercise(name: 'Dominadas', sets: 4, reps: 8, dayGroup: 'Día A (Pecho/Espalda)'),
            RoutineExercise(name: 'Remo con Mancuerna', sets: 4, reps: 10, dayGroup: 'Día A (Pecho/Espalda)'),
            RoutineExercise(name: 'Press Militar con Mancuernas', sets: 4, reps: 10, dayGroup: 'Día B (Hombros/Brazos)'),
            RoutineExercise(name: 'Elevaciones Laterales', sets: 4, reps: 15, dayGroup: 'Día B (Hombros/Brazos)'),
            RoutineExercise(name: 'Curl de Bíceps Inclinado', sets: 3, reps: 12, dayGroup: 'Día B (Hombros/Brazos)'),
            RoutineExercise(name: 'Copa de Tríceps', sets: 3, reps: 12, dayGroup: 'Día B (Hombros/Brazos)'),
            RoutineExercise(name: 'Sentadilla Hacka o Prensa', sets: 4, reps: 10, dayGroup: 'Día C (Piernas)'),
          ],
          dateCreated: DateTime.now(),
          isDefault: true,
        ),
      ];
    }
  }

  Future<List<Routine>> _syncOrphanExercises(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    final String? recordsJsonStr = prefs.getString('workout_records_list');
    final List<String> allHistoryExercises = [];
    if (recordsJsonStr != null) {
      try {
        final decoded = jsonDecode(recordsJsonStr) as List<dynamic>;
        for (var item in decoded) {
          final name = (item as Map<String, dynamic>)['exerciseName'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            allHistoryExercises.add(name.trim());
          }
        }
      } catch (_) {}
    }

    final allRoutineExercises = routines
        .where((r) => r.id != 'routine_others')
        .expand((r) => r.exercises.map((e) => e.name.trim().toLowerCase()))
        .toSet();

    final orphanNames = allHistoryExercises
        .where((e) => !allRoutineExercises.contains(e.toLowerCase()))
        .toSet()
        .toList();

    final List<RoutineExercise> otherExercises = orphanNames.map((name) => RoutineExercise(
      name: name,
      sets: 4,
      reps: 10,
      dayGroup: 'Otros',
    )).toList();

    final List<Routine> updatedRoutines = List.from(routines);
    final othersIndex = updatedRoutines.indexWhere((r) => r.id == 'routine_others');

    if (othersIndex != -1) {
      if (otherExercises.isEmpty) {
        updatedRoutines.removeAt(othersIndex);
      } else {
        updatedRoutines[othersIndex] = updatedRoutines[othersIndex].copyWith(exercises: otherExercises);
      }
    } else if (otherExercises.isNotEmpty) {
      updatedRoutines.add(Routine(
        id: 'routine_others',
        name: 'Otros',
        exercises: otherExercises,
        dateCreated: DateTime.now(),
        isDefault: false,
      ));
    }

    return updatedRoutines;
  }

  Future<void> _saveToPrefsRaw(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(routines.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRoutines, jsonStr);
  }

  Future<void> _saveToPrefs(List<Routine> routines) async {
    final synced = await _syncOrphanExercises(routines);
    state = synced;
    await _saveToPrefsRaw(synced);
  }

  Future<void> addRoutine(String name, List<RoutineExercise> exercises) async {
    final newRoutine = Routine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      exercises: exercises,
      dateCreated: DateTime.now(),
    );

    final updated = [...state, newRoutine];
    state = updated;
    await _saveToPrefs(updated);
  }

  Future<void> deleteRoutine(String id) async {
    final routineToDelete = state.firstWhere((r) => r.id == id, orElse: () => Routine(id: '', name: '', exercises: [], dateCreated: DateTime.now()));
    if (routineToDelete.id.isEmpty) return;

    final updated = state.where((r) => r.id != id).toList();
    
    // Check if any exercises from the deleted routine are now orphans
    final allRemainingExercises = updated.expand((r) => r.exercises.map((e) => e.name.trim().toLowerCase())).toSet();
    final List<RoutineExercise> newlyOrphaned = [];

    for (var ex in routineToDelete.exercises) {
      if (!allRemainingExercises.contains(ex.name.trim().toLowerCase())) {
        newlyOrphaned.add(ex.copyWith(dayGroup: 'Día A'));
      }
    }

    if (newlyOrphaned.isNotEmpty) {
      // Find or create 'Otro' routine to place these orphaned exercises
      final existingOtroIdx = updated.indexWhere((r) => r.name.toLowerCase() == 'otro' || r.name.toLowerCase() == 'otros');
      if (existingOtroIdx != -1) {
        final existingOtro = updated[existingOtroIdx];
        final currentExercises = existingOtro.exercises.map((e) => e.name.toLowerCase().trim()).toSet();
        final List<RoutineExercise> toAdd = [];
        for (var ex in newlyOrphaned) {
          if (!currentExercises.contains(ex.name.toLowerCase().trim())) {
            toAdd.add(ex);
          }
        }
        if (toAdd.isNotEmpty) {
          updated[existingOtroIdx] = existingOtro.copyWith(exercises: [...existingOtro.exercises, ...toAdd]);
        }
      } else {
        final newRoutine = Routine(
          id: 'routine_otro_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Otro',
          exercises: newlyOrphaned,
          dateCreated: DateTime.now(),
        );
        updated.add(newRoutine);
      }
    }

    state = updated;
    await _saveToPrefs(updated);
  }

  Future<void> addExerciseToRoutine(String routineId, String exerciseName, {int sets = 4, int reps = 10, String dayGroup = 'Día A'}) async {
    final cleanName = exerciseName.trim();
    if (cleanName.isEmpty) return;

    state = state.map((routine) {
      if (routine.id == routineId) {
        final contains = routine.exercises.any((e) => e.name.toLowerCase() == cleanName.toLowerCase());
        if (!contains) {
          final updatedExercises = [
            ...routine.exercises,
            RoutineExercise(name: cleanName, sets: sets, reps: reps, dayGroup: dayGroup.trim().isEmpty ? 'Día A' : dayGroup.trim()),
          ];
          return routine.copyWith(exercises: updatedExercises);
        }
      }
      return routine;
    }).toList();

    await _saveToPrefs(state);
  }

  Future<void> removeExerciseFromRoutine(String routineId, String exerciseName) async {
    state = state.map((routine) {
      if (routine.id == routineId) {
        final updatedExercises = routine.exercises.where((e) => e.name != exerciseName).toList();
        return routine.copyWith(exercises: updatedExercises);
      }
      return routine;
    }).toList();

    await _saveToPrefs(state);
  }

  Future<void> removeExerciseFromRoutineForDay(String routineId, String exerciseName, String dayGroup) async {
    state = state.map((routine) {
      if (routine.id == routineId) {
        final updatedExercises = routine.exercises.where((e) => !(e.name == exerciseName && e.dayGroup == dayGroup)).toList();
        return routine.copyWith(exercises: updatedExercises);
      }
      return routine;
    }).toList();

    await _saveToPrefs(state);
  }

  Future<void> updateExerciseSetsReps(String routineId, String exerciseName, int sets, int reps, {String? dayGroup}) async {
    state = state.map((routine) {
      if (routine.id == routineId) {
        final updatedExercises = routine.exercises.map((e) {
          if (e.name == exerciseName) {
            return e.copyWith(
              sets: sets,
              reps: reps,
              dayGroup: dayGroup ?? e.dayGroup,
            );
          }
          return e;
        }).toList();
        return routine.copyWith(exercises: updatedExercises);
      }
      return routine;
    }).toList();

    await _saveToPrefs(state);
  }

  Future<void> syncOrphanExercises(List<WorkoutRecord> history) async {
    if (history.isEmpty) return;
    
    final allHistoryExercises = history.map((r) => r.exerciseName.trim()).toSet();
    final allRoutineExercises = state.expand((r) => r.exercises.map((e) => e.name.trim())).toSet();
    
    final orphanExercises = allHistoryExercises.where((e) => !allRoutineExercises.contains(e)).toList();
    if (orphanExercises.isEmpty) return;

    final existingOtroIdx = state.indexWhere((r) => r.name.toLowerCase() == 'otro' || r.name.toLowerCase() == 'otros');
    
    if (existingOtroIdx != -1) {
      final existingOtro = state[existingOtroIdx];
      final currentExercises = existingOtro.exercises.map((e) => e.name.toLowerCase().trim()).toSet();
      final newExercisesToAdd = orphanExercises
          .where((name) => !currentExercises.contains(name.toLowerCase().trim()))
          .map((name) => RoutineExercise(name: name, sets: 4, reps: 10, dayGroup: 'Día A'))
          .toList();
      
      if (newExercisesToAdd.isNotEmpty) {
        final updatedExercises = [...existingOtro.exercises, ...newExercisesToAdd];
        state = state.map((r) => r.id == existingOtro.id ? r.copyWith(exercises: updatedExercises) : r).toList();
        await _saveToPrefs(state);
      }
    } else {
      final newRoutineExercises = orphanExercises
          .map((name) => RoutineExercise(name: name, sets: 4, reps: 10, dayGroup: 'Día A'))
          .toList();
      
      final newRoutine = Routine(
        id: 'routine_otro_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Otro',
        exercises: newRoutineExercises,
        dateCreated: DateTime.now(),
      );
      
      state = [...state, newRoutine];
      await _saveToPrefs(state);
    }
  }

  Future<void> reorderExercise(String routineId, String dayGroup, int oldIndex, int newIndex) async {
    state = state.map((routine) {
      if (routine.id == routineId) {
        final groupExercises = routine.exercises.where((e) => e.dayGroup == dayGroup).toList();
        
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        
        if (oldIndex >= 0 && oldIndex < groupExercises.length && newIndex >= 0 && newIndex <= groupExercises.length) {
          final item = groupExercises.removeAt(oldIndex);
          groupExercises.insert(newIndex, item);
        }
        
        final List<RoutineExercise> updatedExercises = [];
        for (var ex in routine.exercises) {
          if (ex.dayGroup == dayGroup) {
            if (!updatedExercises.any((e) => e.dayGroup == dayGroup)) {
              updatedExercises.addAll(groupExercises);
            }
          } else {
            updatedExercises.add(ex);
          }
        }
        
        return routine.copyWith(exercises: updatedExercises);
      }
      return routine;
    }).toList();
    
    await _saveToPrefs(state);
  }
}

final routinesProvider = StateNotifierProvider<RoutinesNotifier, List<Routine>>((ref) {
  return RoutinesNotifier();
});
