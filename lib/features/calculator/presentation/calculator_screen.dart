import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../settings/state/settings_notifier.dart';
import '../state/calculator_notifier.dart';
import '../../profile/state/routines_notifier.dart';
import '../../profile/data/routine.dart';
import '../../history/data/workout_record.dart';
import '../../history/state/history_notifier.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

final selectedRoutineIdProvider = StateProvider<String?>((ref) => null);
final currentExerciseNameProvider = StateProvider<String?>((ref) => null);
final selectedDayIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final pageControllerProvider = Provider.autoDispose<PageController>((ref) {
  final controller = PageController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calcState = ref.watch(calculatorProvider);
    final calcNotifier = ref.read(calculatorProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final historyNotifier = ref.read(historyProvider.notifier);
    final routines = ref.watch(routinesProvider);
    final history = ref.watch(historyProvider);
    final activeExercise = ref.watch(currentExerciseNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('app_title', ref),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Selector rápido de unidad de peso en la barra superior
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.midnightGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  _buildUnitButton(ref, 'kg', settings.weightUnit == 'kg'),
                  _buildUnitButton(ref, 'lbs', settings.weightUnit == 'lbs'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CARD DE RESULTADO DE 1RM
            _buildResultCard(context, ref, calcState, settings.weightUnit),
            const SizedBox(height: 24),

            // RUTINA DEL DÍA
            _buildRoutineSelectorCard(context, ref, routines, history, calcNotifier),
            const SizedBox(height: 24),

            // Indicador de Ejercicio Activo
            if (activeExercise != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.voltYellow.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.voltYellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: AppTheme.voltYellow, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Estimando para: $activeExercise",
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                      onPressed: () {
                        ref.read(currentExerciseNameProvider.notifier).state = null;
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // CONTROLES DE ENTRADA
            Text(
              context.tr('calc_weight', ref),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            WeightSelectorInput(
              value: calcState.weight,
              unit: settings.weightUnit,
              onChanged: calcNotifier.updateWeight,
              minWeight: settings.minWeight,
              maxWeight: settings.maxWeight,
            ),
            const SizedBox(height: 20),

            Text(
              context.tr('calc_reps', ref),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            RepsSelectorInput(
              value: calcState.reps,
              onChanged: calcNotifier.updateReps,
            ),
            const SizedBox(height: 24),

            // BOTÓN GUARDAR MARCA
            ElevatedButton.icon(
              onPressed: () => _showSaveDialog(context, ref, calcState, settings.weightUnit, historyNotifier),
              icon: const Icon(Icons.bookmark_outline),
              label: Text(context.tr('calc_save_btn', ref)),
            ),
            const SizedBox(height: 32),

            // TABLA DE PORCENTAJES / ZONAS DE ENTRENAMIENTO
            Text(
              "Zonas de Entrenamiento",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.voltYellow,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildTrainingZonesList(context, ref, calcState.trainingZones, settings.weightUnit),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Widget del botón rápido de unidades kg/lbs
  Widget _buildUnitButton(WidgetRef ref, String unit, bool isActive) {
    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).setWeightUnit(unit);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.voltYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          unit.toUpperCase(),
          style: TextStyle(
            color: isActive ? AppTheme.darkCarbon : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Tarjeta premium de visualización de 1RM
  Widget _buildResultCard(BuildContext context, WidgetRef ref, CalculatorState state, String unit) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.voltYellow.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.voltYellow.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            context.tr('calc_result_title', ref).toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.voltYellow,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                state.calculated1RM.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Selector interactivo de peso (TextField + Slider)


  // Chip de selección de fórmula
  Widget _buildFormulaChip(WidgetRef ref, String label, String value, bool isSelected, CalculatorNotifier notifier) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          notifier.updateFormula(value);
        }
      },
      selectedColor: AppTheme.voltYellow,
      backgroundColor: AppTheme.midnightGrey,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.darkCarbon : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? AppTheme.voltYellow : AppTheme.dividerColor),
      ),
    );
  }

  // Lista detallada de Zonas de entrenamiento
  Widget _buildTrainingZonesList(BuildContext context, WidgetRef ref, List<TrainingZone> zones, String unit) {
    if (zones.isEmpty) return const SizedBox.shrink();

    return Column(
      children: zones.map((zone) {
        // Asignar color dinámico según la zona
        Color zoneColor = AppTheme.textSecondary;
        if (zone.percentage >= 85) {
          zoneColor = AppTheme.voltYellow;
        } else if (zone.percentage >= 70) {
          zoneColor = AppTheme.electricCyan;
        } else if (zone.percentage >= 60) {
          zoneColor = Colors.orangeAccent;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.midnightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Porcentaje y categoría
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: zoneColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: zoneColor.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          "${zone.percentage}%",
                          style: TextStyle(
                            color: zoneColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(zone.categoryKey, ref),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _getZoneDescription(zone.percentage),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Peso correspondiente
              Text(
                "${zone.calculatedWeight} $unit",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getZoneDescription(int pct) {
    if (pct >= 90) return "1-3 reps (Fuerza explosiva)";
    if (pct >= 85) return "3-5 reps (Fuerza máxima)";
    if (pct >= 80) return "6-8 reps (Fuerza-Hipertrofia)";
    if (pct >= 70) return "8-12 reps (Hipertrofia óptima)";
    if (pct >= 60) return "12-15 reps (Potencia / Resistencia)";
    return "15+ reps (Calentamiento)";
  }

  // Diálogo para guardar marca con sugerencias inteligentes
  void _showSaveDialog(
    BuildContext context,
    WidgetRef ref,
    CalculatorState calcState,
    String unit,
    HistoryNotifier historyNotifier,
  ) {
    final activeExercise = ref.read(currentExerciseNameProvider);
    final TextEditingController controller = TextEditingController(text: activeExercise ?? '');

    // Obtener lista única de ejercicios ya guardados en el historial
    final records = ref.read(historyProvider);
    final List<String> savedExercises = records.map((r) => r.exerciseName).toSet().toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.midnightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          title: Text(
            ctx.tr('calc_save_btn', ref),
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeExercise != null) ...[
                    const Text(
                      "Ejercicio:",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeExercise,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.voltYellow,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    Text(
                      ctx.tr('calc_exercise_label', ref),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: ctx.tr('calc_exercise_hint', ref),
                        hintStyle: const TextStyle(color: Colors.white30),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("1RM Estimado:", style: TextStyle(color: Colors.white60, fontSize: 13)),
                      Text(
                        "${calcState.calculated1RM} $unit",
                        style: const TextStyle(color: AppTheme.voltYellow, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final String exercise = controller.text;
                final String actualName = activeExercise ?? exercise;
                if (actualName.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ctx.tr('calc_error_empty', ref)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                historyNotifier.addRecord(
                  exerciseName: actualName,
                  weight: calcState.weight,
                  reps: calcState.reps,
                  oneRepMax: calcState.calculated1RM,
                  unit: unit,
                  formula: calcState.formula,
                );

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ctx.tr('calc_success_save', ref)),
                    backgroundColor: AppTheme.voltYellow,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                final settings = ref.read(settingsProvider);
                _showRestTimerDialog(context, ref, settings.restTimeBetweenExercises);

                // Auto-advance to the next exercise if sets completed
                if (activeExercise != null) {
                  final settings = ref.read(settingsProvider);
                  final routines = ref.read(routinesProvider);
                  final selectedRoutine = routines.isEmpty || settings.selectedRoutineId.isEmpty
                      ? null
                      : routines.firstWhere((r) => r.id == settings.selectedRoutineId, orElse: () => routines.first);

                  if (selectedRoutine != null) {
                    final exercises = selectedRoutine.exercises;
                    final currentExIndex = exercises.indexWhere((e) => e.name.toLowerCase() == activeExercise.toLowerCase());
                    if (currentExIndex != -1) {
                      final currentExConfig = exercises[currentExIndex];
                      
                      final today = DateTime.now();
                      final currentHistory = ref.read(historyProvider);
                      final todayCount = currentHistory.where((r) =>
                          r.exerciseName.trim().toLowerCase() == actualName.trim().toLowerCase() &&
                          r.date.year == today.year &&
                          r.date.month == today.month &&
                          r.date.day == today.day
                      ).length + 1;

                      if (todayCount >= currentExConfig.sets) {
                        if (currentExIndex + 1 < exercises.length) {
                          final nextEx = exercises[currentExIndex + 1];
                          ref.read(currentExerciseNameProvider.notifier).state = nextEx.name;
                          ref.read(calculatorProvider.notifier).updateReps(nextEx.reps);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("¡Series completadas! Siguiente: ${nextEx.name}"),
                              backgroundColor: AppTheme.electricCyan,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  }
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoutineSelectorCard(
    BuildContext context,
    WidgetRef ref,
    List<Routine> routines,
    List<WorkoutRecord> history,
    CalculatorNotifier calcNotifier,
  ) {
    final settings = ref.watch(settingsProvider);
    final activeExercise = ref.watch(currentExerciseNameProvider);

    final selectedRoutine = routines.isEmpty || settings.selectedRoutineId.isEmpty
        ? null
        : routines.firstWhere((r) => r.id == settings.selectedRoutineId, orElse: () => routines.first);

    if (selectedRoutine == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.midnightGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "RUTINA ACTIVA DEL DÍA",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.voltYellow,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "No tienes una rutina activa asignada para hoy.\nVe a Perfil > Mis Rutinas y mantén presionada una rutina para activarla.",
              style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13),
            )
          ],
        ),
      );
    }

    if (selectedRoutine.exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.midnightGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "RUTINA ACTIVA DEL DÍA",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.voltYellow,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  selectedRoutine.name,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Esta rutina no tiene ejercicios agregados.",
              style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13),
            )
          ],
        ),
      );
    }

    final Map<String, List<RoutineExercise>> grouped = {};
    for (var ex in selectedRoutine.exercises) {
      grouped.putIfAbsent(ex.dayGroup, () => []).add(ex);
    }
    final sortedDays = grouped.keys.toList()..sort();
    final activeIndex = ref.watch(selectedDayIndexProvider);
    final pageController = ref.watch(pageControllerProvider);
    final safeIndex = activeIndex >= sortedDays.length ? 0 : activeIndex;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "RUTINA ACTIVA DEL DÍA",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.voltYellow,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                selectedRoutine.name,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sliding Days Selector (Horizontal scrolling chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(sortedDays.length, (idx) {
                final dayName = sortedDays[idx];
                final isSelected = safeIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(dayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedDayIndexProvider.notifier).state = idx;
                        pageController.animateToPage(
                          idx,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    selectedColor: AppTheme.voltYellow,
                    backgroundColor: AppTheme.darkCarbon,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.darkCarbon : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? AppTheme.voltYellow : AppTheme.dividerColor),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Slide View of Exercises
          SizedBox(
            height: 290,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (idx) {
                ref.read(selectedDayIndexProvider.notifier).state = idx;
              },
              itemCount: sortedDays.length,
              itemBuilder: (context, pageIdx) {
                final day = sortedDays[pageIdx];
                final exercises = grouped[day]!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: exercises.length,
                  itemBuilder: (context, exIdx) {
                    final exercise = exercises[exIdx];
                    final isSelected = activeExercise == exercise.name;
                    
                    final matches = history.where((r) =>
                        r.exerciseName.trim().toLowerCase() ==
                        exercise.name.trim().toLowerCase());
                    final latestRecord = matches.isEmpty ? null : matches.first;

                    final today = DateTime.now();
                    final todayRecords = history.where((r) =>
                        r.exerciseName.trim().toLowerCase() == exercise.name.trim().toLowerCase() &&
                        r.date.year == today.year &&
                        r.date.month == today.month &&
                        r.date.day == today.day
                    ).toList().reversed.toList();

                    final isCompleted = todayRecords.length >= exercise.sets;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.voltYellow.withOpacity(0.06)
                            : isCompleted
                                ? Colors.green.withOpacity(0.04)
                                : AppTheme.darkCarbon,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.voltYellow
                              : isCompleted
                                  ? Colors.green.withOpacity(0.3)
                                  : AppTheme.dividerColor,
                          width: isSelected ? 1 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
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
                                          color: isCompleted ? Colors.white38 : Colors.white,
                                          fontSize: 13,
                                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? Colors.green.withOpacity(0.1)
                                            : AppTheme.voltYellow.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "${exercise.sets}x${exercise.reps}",
                                        style: GoogleFonts.spaceGrotesk(
                                          color: isCompleted ? Colors.green : AppTheme.voltYellow,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  latestRecord != null
                                      ? "1RM Actual: ${latestRecord.oneRepMax.toStringAsFixed(1)} ${latestRecord.unit}"
                                      : "Sin 1RM registrado",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: isCompleted
                                        ? Colors.green.withOpacity(0.7)
                                        : latestRecord != null
                                            ? AppTheme.voltYellow
                                            : Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                if (todayRecords.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: List.generate(todayRecords.length, (idx) {
                                      final r = todayRecords[idx];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? Colors.green.withOpacity(0.1)
                                              : AppTheme.voltYellow.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                              color: isCompleted
                                                  ? Colors.green.withOpacity(0.3)
                                                  : AppTheme.voltYellow.withOpacity(0.3),
                                              width: 0.5),
                                        ),
                                        child: Text(
                                          "S${idx + 1}: ${r.weight.toStringAsFixed(0)}x${r.reps} (1RM: ${r.oneRepMax.toStringAsFixed(0)}${r.unit})",
                                          style: GoogleFonts.spaceGrotesk(
                                            color: isCompleted ? Colors.green : AppTheme.voltYellow,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              isCompleted
                                  ? Icons.check_circle_outline
                                  : isSelected
                                      ? Icons.check_circle
                                      : Icons.play_arrow,
                              color: isCompleted
                                  ? Colors.green
                                  : isSelected
                                      ? AppTheme.voltYellow
                                      : Colors.white60,
                              size: 20,
                            ),
                            onPressed: isCompleted
                                ? null
                                : () {
                                    ref.read(currentExerciseNameProvider.notifier).state = exercise.name;
                                    calcNotifier.updateReps(exercise.reps);
                                  },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Slide indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(sortedDays.length, (idx) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: safeIndex == idx ? 16 : 6,
                decoration: BoxDecoration(
                  color: safeIndex == idx ? AppTheme.voltYellow : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Widget de doble entrada para el peso (Input numérico + Slider)
class WeightSelectorInput extends StatefulWidget {
  final double value;
  final String unit;
  final ValueChanged<double> onChanged;
  final double minWeight;
  final double maxWeight;

  const WeightSelectorInput({
    super.key,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.minWeight = 0.0,
    this.maxWeight = 300.0,
  });

  @override
  State<WeightSelectorInput> createState() => _WeightSelectorInputState();
}

class _WeightSelectorInputState extends State<WeightSelectorInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant WeightSelectorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar controlador solo si cambia externamente y no está vacío o en edición rota
    final double? currentVal = double.tryParse(_controller.text);
    if (currentVal != widget.value) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Peso levantado",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(
                width: 100,
                height: 38,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixText: " ${widget.unit}",
                    suffixStyle: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.voltYellow),
                    ),
                  ),
                  onChanged: (val) {
                    final double? parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed != null && parsed >= widget.minWeight) {
                      widget.onChanged(parsed.clamp(widget.minWeight, widget.maxWeight));
                    }
                  },
                ),
              ),
            ],
          ),
          Slider(
            value: widget.value.clamp(widget.minWeight, widget.maxWeight),
            min: widget.minWeight,
            max: widget.maxWeight,
            divisions: ((widget.maxWeight - widget.minWeight) * 2).toInt().clamp(1, 1200),
            label: widget.value.toStringAsFixed(1),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

// Widget de doble entrada para repeticiones (Input numérico + Slider)
class RepsSelectorInput extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const RepsSelectorInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<RepsSelectorInput> createState() => _RepsSelectorInputState();
}

class _RepsSelectorInputState extends State<RepsSelectorInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant RepsSelectorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final int? currentVal = int.tryParse(_controller.text);
    if (currentVal != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Repeticiones",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(
                width: 90,
                height: 38,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    suffixText: " reps",
                    suffixStyle: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.voltYellow),
                    ),
                  ),
                  onChanged: (val) {
                    final int? parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0 && parsed <= 30) {
                      widget.onChanged(parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          Slider(
            value: widget.value.toDouble().clamp(1.0, 20.0),
            min: 1,
            max: 20,
            divisions: 19,
            label: widget.value.toString(),
            onChanged: (val) {
              widget.onChanged(val.toInt());
            },
          ),
        ],
      ),
    );
  }
}

void _showRestTimerDialog(BuildContext context, WidgetRef ref, int initialSeconds) {
  final settings = ref.read(settingsProvider);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return RestTimerDialog(
        initialSeconds: initialSeconds,
        enableBeep: settings.enableBeep,
        selectedBeepSound: settings.selectedBeepSound,
      );
    },
  );
}

class RestTimerDialog extends StatefulWidget {
  final int initialSeconds;
  final bool enableBeep;
  final int selectedBeepSound;

  const RestTimerDialog({
    super.key,
    required this.initialSeconds,
    required this.enableBeep,
    required this.selectedBeepSound,
  });

  @override
  State<RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<RestTimerDialog> {
  late int _secondsRemaining;
  Timer? _timer;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialSeconds;

    if (widget.enableBeep) {
      try {
        _audioPlayer = AudioPlayer();
        _audioPlayer?.setVolume(1.0).catchError((e) {
          debugPrint("AudioPlayer initialization error: $e");
          return null;
        });
      } catch (e) {
        debugPrint("AudioPlayer creation error: $e");
        _audioPlayer = null;
      }
    }

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        _playBeep();
        _timer?.cancel();
        Navigator.of(context).pop();
      } else {
        setState(() {
          _secondsRemaining--;
        });
        if (_secondsRemaining <= 3) {
          _playBeep();
        }
      }
    });
  }

  void _playBeep() async {
    if (!widget.enableBeep) return;

    String url;
    switch (widget.selectedBeepSound) {
      case 2:
        url = 'https://www.soundjay.com/buttons/sounds/button-3.mp3';
        break;
      case 3:
        url = 'https://www.soundjay.com/buttons/sounds/button-10.mp3';
        break;
      case 1:
      default:
        url = 'https://www.soundjay.com/buttons/sounds/button-09.mp3';
        break;
    }

    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.play(UrlSource(url));
      } else {
        _fallbackBeep();
      }
    } catch (_) {
      _fallbackBeep();
    }
  }

  void _fallbackBeep() {
    bool isWsl = false;
    try {
      final versionFile = File('/proc/version');
      if (versionFile.existsSync()) {
        final content = versionFile.readAsStringSync().toLowerCase();
        if (content.contains('microsoft') || content.contains('wsl')) {
          isWsl = true;
        }
      }
    } catch (_) {}

    if (isWsl) {
      String psCommand;
      switch (widget.selectedBeepSound) {
        case 2:
          // Sound 2: Melodia de campanas de 3 segundos (C5, E5, G5, C6, G5, C6)
          psCommand = '[console]::beep(523, 300); [console]::beep(659, 300); [console]::beep(784, 300); [console]::beep(1046, 600); Start-Sleep -m 200; [console]::beep(784, 300); [console]::beep(1046, 800)';
          break;
        case 3:
          // Sound 3: Clicks rítmicos de 3 segundos (8 clicks espaciados)
          psCommand = r'for ($i=0; $i -lt 8; $i++) { [console]::beep(350, 100); Start-Sleep -m 250 }';
          break;
        case 1:
        default:
          // Sound 1: Bit Bit repetido durante 3 segundos
          psCommand = r'for ($i=0; $i -lt 4; $i++) { [console]::beep(1000, 250); Start-Sleep -m 500 }';
          break;
      }
      Process.run('powershell.exe', ['-c', psCommand]).catchError((e) {
        debugPrint("WSL beep error: $e");
        return ProcessResult(0, 0, null, null);
      });
    } else {
      try {
        // Pure Linux: use speaker-test to generate 3 seconds of sound
        if (widget.selectedBeepSound == 2) {
          Process.run('speaker-test', ['-t', 'sine', '-f', '800', '-l', '3']).catchError((_) => ProcessResult(0,0,null,null));
        } else if (widget.selectedBeepSound == 3) {
          Process.run('speaker-test', ['-t', 'sine', '-f', '400', '-l', '3']).catchError((_) => ProcessResult(0,0,null,null));
        } else {
          Process.run('speaker-test', ['-t', 'sine', '-f', '1000', '-l', '3']).catchError((_) => ProcessResult(0,0,null,null));
        }
      } catch (_) {}
      SystemSound.play(SystemSoundType.alert);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      _audioPlayer?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double percent = widget.initialSeconds > 0 ? (_secondsRemaining / widget.initialSeconds) : 0.0;

    return AlertDialog(
      backgroundColor: AppTheme.midnightGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.dividerColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "TIEMPO DE DESCANSO",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.voltYellow,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.darkCarbon,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.voltYellow),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$_secondsRemaining",
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "segundos",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _secondsRemaining += 30;
                  });
                },
                icon: const Icon(Icons.add, size: 16, color: AppTheme.voltYellow),
                label: const Text(
                  "+30 s",
                  style: TextStyle(color: AppTheme.voltYellow, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _timer?.cancel();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkCarbon,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Saltar"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
