import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../history/state/history_notifier.dart';
import '../state/routines_notifier.dart';
import '../data/routine.dart';
import '../../settings/state/settings_notifier.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  final _routineNameController = TextEditingController();
  final _newExerciseController = TextEditingController();
  final _setsController = TextEditingController(text: '4');
  final _repsController = TextEditingController(text: '10');
  String? _expandedRoutineId;

  @override
  void dispose() {
    _routineNameController.dispose();
    _newExerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _showCreateRoutineDialog() {
    _routineNameController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.midnightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          title: Text(
            'Crear Rutina Personalizada',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOMBRE DE LA RUTINA',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.voltYellow,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _routineNameController,
                autofocus: true,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ej. Día de Pierna, Torso, etc.',
                  hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.voltYellow),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.spaceGrotesk(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _routineNameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(routinesProvider.notifier).addRoutine(name, []);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡Rutina "$name" creada! Agrega ejercicios abajo.'),
                      backgroundColor: AppTheme.voltYellow,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.voltYellow,
                foregroundColor: AppTheme.darkCarbon,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Crear',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddExerciseDialog(String routineId) {
    _newExerciseController.clear();
    _setsController.text = '4';
    _repsController.text = '10';
    bool isBodyweight = false;

    final history = ref.read(historyProvider);
    final routines = ref.read(routinesProvider);
    final currentRoutine = routines.firstWhere((r) => r.id == routineId);

    final defaultDay = '';

    final allHistoryExercises = history.map((r) => r.exerciseName.trim()).toSet();
    final allRoutineExercises = routines.expand((r) => r.exercises.map((e) => e.name.trim())).toSet();
    
    // Ejercicios con marca pero sin ninguna rutina asociada
    final orphanExercises = allHistoryExercises.where((e) => !allRoutineExercises.contains(e)).toSet();

    // Ejercicios en el historial que no están en la rutina actual
    final currentRoutineExercises = currentRoutine.exercises.map((e) => e.name.trim()).toSet();
    final otherHistoryExercises = allHistoryExercises.where((e) => !currentRoutineExercises.contains(e)).toSet();

    final commonGymExercises = {
      'Press de Banca',
      'Sentadilla',
      'Peso Muerto',
      'Press Militar',
      'Dominadas',
      'Remo con Barra',
      'Curl de Bíceps',
      'Copa de Tríceps',
      'Fondos de Tríceps',
      'Elevaciones Laterales',
      'Zancadas',
      'Prensa de Piernas',
    }.where((e) => !currentRoutineExercises.contains(e)).toSet();

    final customDayController = TextEditingController(text: defaultDay);
    final existingDays = currentRoutine.exercises
        .map((e) => e.dayGroup.trim())
        .where((d) => d.isNotEmpty)
        .toSet();
    final List<String> allDayOptions;
    if (existingDays.isEmpty) {
      allDayOptions = [
        'Día A',
        'Día B',
        'Día C',
        'Día D',
        'Empuje',
        'Jalón',
        'Pierna',
        'Torso',
        'Extremidades',
      ]..sort();
    } else {
      allDayOptions = existingDays.toList()..sort();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.midnightGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.dividerColor),
              ),
              title: Text(
                'Agregar Ejercicio',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOMBRE DEL EJERCICIO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.voltYellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.toLowerCase().trim();
                        final Set<String> allOptions = {
                          ...orphanExercises,
                          ...otherHistoryExercises,
                          ...commonGymExercises,
                        };
                        if (query.isEmpty) {
                          return allOptions;
                        }
                        return allOptions.where((option) => option.toLowerCase().contains(query));
                      },
                      onSelected: (String selection) {
                        _newExerciseController.text = selection;
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        textEditingController.text = _newExerciseController.text;
                        textEditingController.addListener(() {
                          _newExerciseController.text = textEditingController.text;
                        });
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ej. Press de Banca, Peso Muerto...',
                            hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.voltYellow),
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            color: AppTheme.midnightGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.dividerColor),
                            ),
                            child: Container(
                              width: 250,
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  final isOrphan = orphanExercises.contains(option);
                                  final isHistory = allHistoryExercises.contains(option);

                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      option,
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13),
                                    ),
                                    subtitle: isOrphan
                                        ? Text(
                                            "Marca registrada sin rutina",
                                            style: GoogleFonts.spaceGrotesk(
                                              color: AppTheme.voltYellow,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : isHistory
                                            ? Text(
                                                "Con marca de 1RM",
                                                style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 10),
                                              )
                                            : null,
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Inputs para Series y Repeticiones con flechas/botones de incremento
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SERIES',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.voltYellow,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.voltYellow, size: 20),
                                    onPressed: () {
                                      final current = int.tryParse(_setsController.text) ?? 0;
                                      if (current > 1) {
                                        setStateDialog(() {
                                          _setsController.text = (current - 1).toString();
                                        });
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _setsController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.voltYellow, size: 20),
                                    onPressed: () {
                                      final current = int.tryParse(_setsController.text) ?? 0;
                                      setStateDialog(() {
                                        _setsController.text = (current + 1).toString();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'REPETICIONES',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.voltYellow,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.voltYellow, size: 20),
                                    onPressed: () {
                                      final current = int.tryParse(_repsController.text) ?? 0;
                                      if (current > 1) {
                                        setStateDialog(() {
                                          _repsController.text = (current - 1).toString();
                                        });
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _repsController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.voltYellow, size: 20),
                                    onPressed: () {
                                      final current = int.tryParse(_repsController.text) ?? 0;
                                      setStateDialog(() {
                                        _repsController.text = (current + 1).toString();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: Text(
                        "Es peso corporal",
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Text(
                        "Calcula RM basado en reps",
                        style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 10),
                      ),
                      value: isBodyweight,
                      activeColor: AppTheme.voltYellow,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setStateDialog(() {
                          isBodyweight = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selector de Grupo/Día de Rutina (Personalizable)
                    Text(
                      'ORGANIZACIÓN (DÍA)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.voltYellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final query = textEditingValue.text.toLowerCase().trim();
                        if (query.isEmpty) {
                          return allDayOptions;
                        }
                        return allDayOptions.where((option) => option.toLowerCase().contains(query));
                      },
                      onSelected: (String selection) {
                        customDayController.text = selection;
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        textEditingController.text = customDayController.text;
                        textEditingController.addListener(() {
                          customDayController.text = textEditingController.text;
                        });
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ej. Día A, Empuje, Piernas...',
                            hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.voltYellow),
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            color: AppTheme.midnightGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.dividerColor),
                            ),
                            child: Container(
                              width: 250,
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      option,
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13),
                                    ),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Sección de sugerencias rápidas de marcas sin rutina
                    if (orphanExercises.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'SUGERIDOS (SIN RUTINA):',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.voltYellow,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: orphanExercises.map((exercise) {
                          return InkWell(
                            onTap: () {
                              _newExerciseController.text = exercise;
                              final s = int.tryParse(_setsController.text) ?? 4;
                              final r = int.tryParse(_repsController.text) ?? 10;
                              final finalDay = customDayController.text.trim().isNotEmpty 
                                  ? customDayController.text.trim() 
                                  : 'Día A';
                              ref.read(routinesProvider.notifier).addExerciseToRoutine(
                                    routineId,
                                    exercise,
                                    sets: s,
                                    reps: r,
                                    dayGroup: finalDay,
                                  );
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.voltYellow.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.voltYellow.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 12, color: AppTheme.voltYellow),
                                  const SizedBox(width: 4),
                                  Text(
                                    exercise,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white60),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = _newExerciseController.text.trim();
                    final s = int.tryParse(_setsController.text) ?? 4;
                    final r = int.tryParse(_repsController.text) ?? 10;
                    final finalDay = customDayController.text.trim().isNotEmpty 
                        ? customDayController.text.trim() 
                        : 'Día A';
                    if (name.isNotEmpty) {
                      ref.read(routinesProvider.notifier).addExerciseToRoutine(
                            routineId,
                            name,
                            sets: s,
                            reps: r,
                            dayGroup: finalDay,
                            isBodyweight: isBodyweight,
                          );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.voltYellow,
                    foregroundColor: AppTheme.darkCarbon,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Agregar',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSetsRepsDialog(String routineId, RoutineExercise exercise) {
    final setsController = TextEditingController(text: exercise.sets.toString());
    final repsController = TextEditingController(text: exercise.reps.toString());
    final customDayController = TextEditingController(text: exercise.dayGroup);
    bool isBodyweight = exercise.isBodyweight;

    final routines = ref.read(routinesProvider);

    // No prepopulated options needed as the suggestions list is removed.

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.midnightGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.dividerColor),
              ),
              title: Text(
                'Editar Ejercicio',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SERIES',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.voltYellow,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.voltYellow, size: 20),
                                    onPressed: () {
                                      final current = int.tryParse(setsController.text) ?? 0;
                                      if (current > 1) {
                                        setStateDialog(() {
                                          setsController.text = (current - 1).toString();
                                        });
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: setsController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.voltYellow, size: 20),
                                    onPressed: () {
                                      final current = int.tryParse(setsController.text) ?? 0;
                                      setStateDialog(() {
                                        setsController.text = (current + 1).toString();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'REPETICIONES',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.voltYellow,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.voltYellow, size: 20),
                                    onPressed: () {
                                      final current = int.tryParse(repsController.text) ?? 0;
                                      if (current > 1) {
                                        setStateDialog(() {
                                          repsController.text = (current - 1).toString();
                                        });
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: repsController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.voltYellow, size: 20),
                                    onPressed: () {
                                      final current = int.tryParse(repsController.text) ?? 0;
                                      setStateDialog(() {
                                        repsController.text = (current + 1).toString();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: Text(
                        "Es peso corporal",
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13),
                      ),
                      subtitle: Text(
                        "Calcula RM basado en reps",
                        style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 10),
                      ),
                      value: isBodyweight,
                      activeColor: AppTheme.voltYellow,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setStateDialog(() {
                          isBodyweight = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Selector de Grupo/Día de Rutina (Personalizable)
                    Text(
                      'ORGANIZACIÓN (DÍA)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.voltYellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: customDayController,
                      style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ej. Día A, Empuje, Piernas...',
                        hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white30, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white60),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final s = int.tryParse(setsController.text) ?? exercise.sets;
                    final r = int.tryParse(repsController.text) ?? exercise.reps;
                    final finalDay = customDayController.text.trim().isNotEmpty
                        ? customDayController.text.trim()
                        : exercise.dayGroup;
                    ref.read(routinesProvider.notifier).updateExerciseSetsReps(
                          routineId,
                          exercise.name,
                          s,
                          r,
                          dayGroup: finalDay,
                          isBodyweight: isBodyweight,
                        );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.voltYellow,
                    foregroundColor: AppTheme.darkCarbon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Guardar',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(routinesProvider);
    final history = ref.watch(historyProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mis Rutinas",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: routines.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 64, color: Colors.white30),
                  const SizedBox(height: 16),
                  Text(
                    "No tienes rutinas",
                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.white60),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                final isExpanded = _expandedRoutineId == routine.id;
                final isSelected = settings.selectedRoutineId == routine.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: AppTheme.midnightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? AppTheme.voltYellow : AppTheme.dividerColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    onLongPress: () {
                      if (isSelected) {
                        ref.read(settingsProvider.notifier).setSelectedRoutineId('');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Se ha desactivado la rutina activa.',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppTheme.darkCarbon,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ref.read(settingsProvider.notifier).setSelectedRoutineId(routine.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('¡"${routine.name}" seleccionada como Rutina del Día!'),
                            backgroundColor: AppTheme.voltYellow,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  routine.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.voltYellow.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.voltYellow),
                                  ),
                                  child: Text(
                                    "ACTIVA",
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppTheme.voltYellow,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "${routine.exercises.length} ejercicios asociados • Presiona largo para activar",
                              style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 12),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!routine.isDefault && 
                                  routine.name.toLowerCase() != 'otro' && 
                                  routine.name.toLowerCase() != 'otros')
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    ref.read(routinesProvider.notifier).deleteRoutine(routine.id);
                                  },
                                ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: AppTheme.voltYellow,
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _expandedRoutineId = isExpanded ? null : routine.id;
                            });
                          },
                        ),
                        if (isExpanded) ...[
                          const Divider(color: AppTheme.dividerColor, height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (routine.exercises.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                                    child: Text(
                                      "No hay ejercicios en esta rutina. ¡Agrega uno abajo!",
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white30,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else ..._buildGroupedExercisesView(routine, history),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddExerciseDialog(routine.id),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Agregar Ejercicio'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.voltYellow.withOpacity(0.12),
                                    foregroundColor: AppTheme.voltYellow,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(color: AppTheme.voltYellow, width: 0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoutineDialog,
        backgroundColor: AppTheme.voltYellow,
        foregroundColor: AppTheme.darkCarbon,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildGroupedExercisesView(Routine routine, List<dynamic> history) {
    final Map<String, List<RoutineExercise>> grouped = {};
    for (var ex in routine.exercises) {
      grouped.putIfAbsent(ex.dayGroup, () => []).add(ex);
    }

    final sortedDays = grouped.keys.toList()..sort();
    final List<Widget> widgets = [];

    for (var day in sortedDays) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
          child: Text(
            day.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.voltYellow,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );

      final exercises = grouped[day]!;
      widgets.add(
        ReorderableListView.builder(
          buildDefaultDragHandles: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercises.length,
          onReorder: (oldIndex, newIndex) {
            ref.read(routinesProvider.notifier).reorderExercise(
              routine.id,
              day,
              oldIndex,
              newIndex,
            );
          },
          itemBuilder: (context, exIndex) {
            final exercise = exercises[exIndex];
            final matches = history.where((r) =>
                r.exerciseName.trim().toLowerCase() ==
                exercise.name.trim().toLowerCase());
            final latestRecord = matches.isEmpty ? null : matches.first;

            return Container(
              key: ValueKey('${exercise.name}_${day}_$exIndex'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.darkCarbon,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ReorderableDragStartListener(
                    index: exIndex,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Icon(Icons.drag_indicator, size: 22, color: Colors.white38),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showEditSetsRepsDialog(routine.id, exercise),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.voltYellow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${exercise.sets}x${exercise.reps}",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: AppTheme.voltYellow,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          latestRecord != null
                              ? "Último 1RM: ${latestRecord.oneRepMax.toStringAsFixed(1)} ${latestRecord.unit}"
                              : "Sin registros de 1RM aún",
                          style: GoogleFonts.spaceGrotesk(
                            color: latestRecord != null ? AppTheme.voltYellow : Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                    onPressed: () {
                      ref.read(routinesProvider.notifier).removeExerciseFromRoutine(routine.id, exercise.name);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return widgets;
  }
}
