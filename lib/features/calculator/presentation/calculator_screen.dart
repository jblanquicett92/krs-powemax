import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../settings/state/settings_notifier.dart';
import '../state/calculator_notifier.dart';
import '../../profile/state/routines_notifier.dart';
import '../../profile/data/routine.dart';
import '../../profile/presentation/routines_screen.dart';
import '../../profile/presentation/avatar_helper.dart';
import '../../history/data/workout_record.dart';
import '../../history/state/history_notifier.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

final selectedRoutineIdProvider = StateProvider<String?>((ref) => null);
final currentExerciseNameProvider = StateProvider<String?>((ref) => null);
final selectedDayIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

// Override de sets/reps solo para la sesión actual (no persiste en la rutina)
// Clave: nombre del ejercicio, Valor: (sets, reps)
final sessionOverridesProvider =
    StateProvider<Map<String, ({int sets, int reps})>>((ref) => {});

// Ejercicios extra agregados solo para la sesión actual (clave = dayGroup)
final sessionExtraExercisesProvider =
    StateProvider<Map<String, List<RoutineExercise>>>((ref) => {});


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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: buildAvatarWidget(
              path: settings.profileImagePath,
              radius: 18,
              fallbackColor: AppTheme.voltYellow,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              minReps: settings.minReps,
              maxReps: settings.maxReps,
              onChanged: calcNotifier.updateReps,
            ),
            const SizedBox(height: 24),

            // BOTÓN GUARDAR MARCA
            ElevatedButton.icon(
              onPressed: settings.selectedRoutineId.isEmpty
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debes seleccionar o activar una rutina antes de guardar marcas.'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : () => _showSaveDialog(context, ref, calcState, settings.weightUnit, historyNotifier),
              icon: const Icon(Icons.bookmark_outline),
              label: Text(context.tr('calc_save_btn', ref)),
              style: settings.selectedRoutineId.isEmpty
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white24,
                    )
                  : null,
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
            _buildTrainingZonesList(context, ref, calcState, settings.weightUnit),
            const SizedBox(height: 24),
          ],
        ),
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
  Widget _buildTrainingZonesList(BuildContext context, WidgetRef ref, CalculatorState calcState, String unit) {
    final zones = calcState.trainingZones;
    if (zones.isEmpty) return const SizedBox.shrink();

    // Calcular el porcentaje aproximado del usuario para destacar su zona activa
    final double userPct = calcState.calculated1RM > 0 
        ? (calcState.weight / calcState.calculated1RM) * 100 
        : 0.0;
    final int targetPct = (userPct / 5).round() * 5;
    final int activePct = targetPct.clamp(50, 100);

    return Column(
      children: zones.map((zone) {
        final bool is1RM = zone.percentage == 100;
        final bool isTargetZone = zone.percentage == activePct;
        
        // Asignar color dinámico según la zona
        Color zoneColor = AppTheme.textSecondary;
        if (is1RM) {
          zoneColor = AppTheme.voltYellow;
        } else if (zone.percentage >= 85) {
          zoneColor = Colors.orangeAccent;
        } else if (zone.percentage >= 70) {
          zoneColor = AppTheme.electricCyan;
        } else if (zone.percentage >= 60) {
          zoneColor = Colors.lightGreenAccent;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: isTargetZone ? 16 : 12),
          decoration: BoxDecoration(
            color: isTargetZone
                ? AppTheme.electricCyan.withOpacity(0.08)
                : AppTheme.midnightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTargetZone
                  ? AppTheme.electricCyan.withOpacity(0.8)
                  : AppTheme.dividerColor,
              width: isTargetZone ? 1.5 : 1.0,
            ),
            boxShadow: isTargetZone
                ? [
                    BoxShadow(
                      color: AppTheme.electricCyan.withOpacity(0.03),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
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
                          is1RM ? "1RM" : "${zone.percentage}%",
                          style: TextStyle(
                            color: zoneColor,
                            fontWeight: FontWeight.bold,
                            fontSize: is1RM ? 12 : 14,
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
                            is1RM ? "1RM Estimado" : context.tr(zone.categoryKey, ref),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: is1RM ? 15 : 14,
                              fontWeight: FontWeight.bold,
                              color: isTargetZone
                                  ? AppTheme.electricCyan
                                  : (is1RM ? AppTheme.voltYellow : Colors.white),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            is1RM ? "100% de tu fuerza máxima estimada" : _getZoneDescription(zone.percentage),
                            style: TextStyle(
                              fontSize: 11,
                              color: is1RM ? Colors.white70 : Colors.white38,
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
                  fontSize: isTargetZone ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: isTargetZone
                      ? AppTheme.electricCyan
                      : (is1RM ? AppTheme.voltYellow : Colors.white),
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
                      ).length;

                      if (todayCount >= currentExConfig.sets) {
                        if (currentExIndex + 1 < exercises.length) {
                          final nextEx = exercises[currentExIndex + 1];
                          ref.read(currentExerciseNameProvider.notifier).state = nextEx.name;
                          final historyList = ref.read(historyProvider);
                          final nextExRecords = historyList.where((r) =>
                              r.exerciseName.trim().toLowerCase() == nextEx.name.trim().toLowerCase());
                          if (nextExRecords.isNotEmpty) {
                            final lastRecord = nextExRecords.first;
                            ref.read(calculatorProvider.notifier).updateWeight(lastRecord.weight);
                            ref.read(calculatorProvider.notifier).updateReps(lastRecord.reps);
                          } else {
                            ref.read(calculatorProvider.notifier).updateReps(nextEx.reps);
                          }

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
    final today = DateTime.now();
    final todayRecords = history.where((r) =>
        r.date.year == today.year &&
        r.date.month == today.month &&
        r.date.day == today.day
    ).toList();

    final selectedRoutine = routines.isEmpty || settings.selectedRoutineId.isEmpty
        ? null
        : routines.firstWhere((r) => r.id == settings.selectedRoutineId, orElse: () => routines.first);

    if (selectedRoutine == null) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoutinesScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
                "RUTINA",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.voltYellow,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                routines.isEmpty
                    ? "No tienes rutinas creadas aún.\nPresiona aquí para ir a Mis Rutinas y crear tu primera rutina."
                    : "No tienes una rutina activa asignada para hoy.\nPresiona aquí para ir a tus rutinas y activar una.",
                style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 13),
              )
            ],
          ),
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
                  "RUTINA",
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
                "RUTINA",
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

          // Day Selector — collapsed pill with bottom sheet
          Builder(
            builder: (context) {
              final currentDayName = sortedDays[safeIndex];
              final isLocked = activeExercise != null;

              return GestureDetector(
                onTap: isLocked || sortedDays.length <= 1
                    ? null
                    : () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            return Container(
                              decoration: const BoxDecoration(
                                color: AppTheme.midnightGrey,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Handle bar
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'SELECCIONAR DÍA',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.voltYellow,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(sortedDays.length, (idx) {
                                    final dayName = sortedDays[idx];
                                    final isActive = safeIndex == idx;
                                    return InkWell(
                                      onTap: () {
                                        ref.read(selectedDayIndexProvider.notifier).state = idx;
                                        Navigator.pop(ctx);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? AppTheme.voltYellow.withOpacity(0.1)
                                              : AppTheme.darkCarbon,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isActive ? AppTheme.voltYellow : AppTheme.dividerColor,
                                            width: isActive ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isActive
                                                  ? Icons.radio_button_checked
                                                  : Icons.radio_button_off,
                                              size: 18,
                                              color: isActive ? AppTheme.voltYellow : Colors.white38,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                dayName,
                                                style: GoogleFonts.spaceGrotesk(
                                                  fontSize: 14,
                                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                                  color: isActive ? AppTheme.voltYellow : Colors.white70,
                                                ),
                                              ),
                                            ),
                                            if (isActive)
                                              const Icon(Icons.check, size: 16, color: AppTheme.voltYellow),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        );
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? AppTheme.darkCarbon.withOpacity(0.6)
                        : AppTheme.voltYellow.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLocked
                          ? AppTheme.dividerColor
                          : AppTheme.voltYellow.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLocked ? Icons.lock_outline : Icons.calendar_today_outlined,
                        size: 14,
                        color: isLocked ? Colors.white38 : AppTheme.voltYellow,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentDayName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? Colors.white38 : Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isLocked && sortedDays.length > 1) ...[ 
                        const SizedBox(width: 6),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.voltYellow.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),


          // Session status summary (Active or Completed)
          if (todayRecords.isNotEmpty) ...[
            Builder(
              builder: (context) {
                final dayName = sortedDays[safeIndex];
                
                // Solo mostrar la sesión activa/completada si el usuario ha registrado algún ejercicio
                // que pertenece al grupo de día seleccionado en esta pestaña
                bool isThisDayGroupTrained = false;
                for (final record in todayRecords) {
                  final dayExercises = grouped[dayName] ?? [];
                  final matchesExercise = dayExercises.any((ex) =>
                      ex.name.trim().toLowerCase() == record.exerciseName.trim().toLowerCase());
                  if (matchesExercise) {
                    isThisDayGroupTrained = true;
                    break;
                  }
                }
                
                if (!isThisDayGroupTrained) {
                  return const SizedBox.shrink();
                }

                final sortedToday = List<WorkoutRecord>.from(todayRecords)..sort((a, b) => a.date.compareTo(b.date));
                final firstRecordTime = sortedToday.first.date;
                final lastRecordTime = sortedToday.last.date;
                
                final dayExercises = grouped[dayName]!;
                final isAllCompleted = dayExercises.every((ex) {
                  final exTodayRecords = todayRecords.where((r) =>
                    r.exerciseName.trim().toLowerCase() == ex.name.trim().toLowerCase()
                  );
                  return exTodayRecords.length >= ex.sets;
                });

                final duration = lastRecordTime.difference(firstRecordTime);
                final durationMin = todayRecords.length <= 1 ? 0 : (duration.inMinutes == 0 ? 1 : duration.inMinutes);
                final todayVolume = todayRecords.fold<double>(0, (sum, r) => sum + (r.weight * r.reps));

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAllCompleted ? Colors.green.withOpacity(0.1) : AppTheme.darkCarbon,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAllCompleted ? Colors.green : AppTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAllCompleted ? Colors.green : AppTheme.voltYellow,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAllCompleted ? "¡SESIÓN COMPLETADA!" : "SESIÓN ACTIVA",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAllCompleted ? Colors.green : AppTheme.voltYellow,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Duración: $durationMin min | Volumen: ${todayVolume.toStringAsFixed(0)} ${settings.weightUnit}",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ],

          // Exercise list for selected day (fixed height, scrollable)
          Builder(
            builder: (context) {
              final day = sortedDays[safeIndex];
              final sessionOverrides = ref.watch(sessionOverridesProvider);
              final sessionExtras = ref.watch(sessionExtraExercisesProvider);
              final routineExercises = grouped[day]!;
              final extraExercises = sessionExtras[day] ?? [];
              final today = DateTime.now();

              // Combinar rutina + extras de sesión
              final allExercises = [...routineExercises, ...extraExercises];

              // Separar pendientes y completados para ordenar completados al final
              final pendingExercises = allExercises.where((ex) {
                final override = sessionOverrides[ex.name];
                final effectiveSets = override?.sets ?? ex.sets;
                final todayCount = history.where((r) =>
                    r.exerciseName.trim().toLowerCase() == ex.name.trim().toLowerCase() &&
                    r.date.year == today.year &&
                    r.date.month == today.month &&
                    r.date.day == today.day).length;
                return todayCount < effectiveSets;
              }).toList();

              final completedExercises = allExercises.where((ex) {
                final override = sessionOverrides[ex.name];
                final effectiveSets = override?.sets ?? ex.sets;
                final todayCount = history.where((r) =>
                    r.exerciseName.trim().toLowerCase() == ex.name.trim().toLowerCase() &&
                    r.date.year == today.year &&
                    r.date.month == today.month &&
                    r.date.day == today.day).length;
                return todayCount >= effectiveSets;
              }).toList();

              final exercises = [...pendingExercises, ...completedExercises];

              return SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: exercises.length,
                    onReorder: (oldIndex, newIndex) {
                      // Solo reordenar ejercicios de la rutina original (no extras de sesión)
                      final isOldInRoutine = oldIndex < routineExercises.length;
                      final isNewInRoutine = newIndex <= routineExercises.length;
                      if (isOldInRoutine && isNewInRoutine) {
                        ref.read(routinesProvider.notifier).reorderExercise(
                          selectedRoutine.id,
                          day,
                          oldIndex,
                          newIndex,
                        );
                      }
                    },
                itemBuilder: (context, exIdx) {
                  final exercise = exercises[exIdx];
                  final isSelected = activeExercise == exercise.name;

                  final matches = history.where((r) =>
                      r.exerciseName.trim().toLowerCase() ==
                      exercise.name.trim().toLowerCase());
                  final latestRecord = matches.isEmpty ? null : matches.first;

                  final today = DateTime.now();
                  final todayExRecords = history.where((r) =>
                      r.exerciseName.trim().toLowerCase() == exercise.name.trim().toLowerCase() &&
                      r.date.year == today.year &&
                      r.date.month == today.month &&
                      r.date.day == today.day
                  ).toList().reversed.toList();

                  final sessionOverrides = ref.watch(sessionOverridesProvider);
                  final sessionOverride = sessionOverrides[exercise.name];
                  final effectiveSets = sessionOverride?.sets ?? exercise.sets;
                  final effectiveReps = sessionOverride?.reps ?? exercise.reps;
                  final isCompleted = todayExRecords.length >= effectiveSets;

                  return Dismissible(
                    key: ValueKey('dismiss_calc_ex_${exercise.name}_$exIdx'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            backgroundColor: AppTheme.midnightGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppTheme.dividerColor),
                            ),
                            title: Text(
                              "¿Quitar ejercicio?",
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              "¿Realmente deseas eliminar '${exercise.name}' de este día de la rutina?",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Cancelar", style: TextStyle(color: Colors.white60)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("Quitar", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          );
                        },
                      ) ?? false;
                    },
                    onDismissed: (direction) {
                      final isExtra = extraExercises.any((e) => e.name == exercise.name);
                      if (isExtra) {
                        final extras = Map<String, List<RoutineExercise>>.from(ref.read(sessionExtraExercisesProvider));
                        final dayList = List<RoutineExercise>.from(extras[day] ?? []);
                        dayList.removeWhere((e) => e.name == exercise.name);
                        extras[day] = dayList;
                        ref.read(sessionExtraExercisesProvider.notifier).state = extras;
                      } else {
                        ref.read(routinesProvider.notifier).removeExerciseFromRoutineForDay(
                          selectedRoutine.id,
                          exercise.name,
                          day,
                        );
                      }
                      
                      if (ref.read(currentExerciseNameProvider) == exercise.name) {
                        ref.read(currentExerciseNameProvider.notifier).state = null;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${exercise.name}" de la rutina hoy eliminado'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: GestureDetector(
                      key: ValueKey('calc_ex_${exercise.name}_$exIdx'),
                      onTap: isCompleted
                          ? null
                          : () {
                              // Seleccionar o deseleccionar
                              if (isSelected) {
                                ref.read(currentExerciseNameProvider.notifier).state = null;
                              } else {
                                ref.read(currentExerciseNameProvider.notifier).state = exercise.name;
                                final historyList = ref.read(historyProvider);
                                final exRecords = historyList.where((r) =>
                                    r.exerciseName.trim().toLowerCase() ==
                                    exercise.name.trim().toLowerCase());
                                if (exRecords.isNotEmpty) {
                                  calcNotifier.updateWeight(exRecords.first.weight);
                                  calcNotifier.updateReps(exRecords.first.reps);
                                } else {
                                  calcNotifier.updateReps(effectiveReps);
                                }
                              }
                            },
                      onLongPress: () => _showSessionEditDialog(
                        context,
                        ref,
                        exercise,
                        effectiveSets,
                        effectiveReps,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Drag handle
                            ReorderableDragStartListener(
                              index: exIdx,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                                child: Icon(
                                  Icons.drag_indicator,
                                  size: 18,
                                  color: Colors.white24,
                                ),
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
                                            color: isCompleted
                                                ? Colors.white38
                                                : isSelected
                                                    ? AppTheme.voltYellow
                                                    : Colors.white,
                                            fontSize: 13,
                                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Badge sets×reps: muestra override si lo hay
                                      GestureDetector(
                                        onTap: () => _showSessionEditDialog(
                                          context, ref, exercise, effectiveSets, effectiveReps),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: sessionOverride != null
                                                ? AppTheme.electricCyan.withOpacity(0.12)
                                                : isCompleted
                                                    ? Colors.green.withOpacity(0.1)
                                                    : AppTheme.voltYellow.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(
                                              color: sessionOverride != null
                                                  ? AppTheme.electricCyan.withOpacity(0.4)
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (sessionOverride != null)
                                                const Padding(
                                                  padding: EdgeInsets.only(right: 3),
                                                  child: Icon(Icons.edit_rounded,
                                                      size: 9, color: AppTheme.electricCyan),
                                                ),
                                              Text(
                                                '${effectiveSets}×${effectiveReps}',
                                                style: GoogleFonts.spaceGrotesk(
                                                  color: sessionOverride != null
                                                      ? AppTheme.electricCyan
                                                      : isCompleted
                                                          ? Colors.green
                                                          : AppTheme.voltYellow,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Botón cambiar ejercicio (solo si no completado)
                                      if (!isCompleted)
                                        GestureDetector(
                                          onTap: () => _showSwapExerciseSheet(
                                            context, ref, selectedRoutine, exercise, calcNotifier),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.swap_horiz_rounded,
                                                size: 16, color: Colors.white24),
                                          ),
                                        ),
                                      // Indicador completado
                                      if (isCompleted)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 2),
                                          child: Icon(Icons.check_circle,
                                              size: 16, color: Colors.green),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    latestRecord != null
                                        ? '1RM Actual: ${latestRecord.oneRepMax.toStringAsFixed(1)} ${latestRecord.unit}'
                                        : 'Sin 1RM registrado',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: isCompleted
                                          ? Colors.green.withOpacity(0.7)
                                          : latestRecord != null
                                              ? AppTheme.voltYellow
                                              : Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (todayExRecords.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: List.generate(todayExRecords.length, (idx) {
                                        final r = todayExRecords[idx];
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
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            '${r.weight.toStringAsFixed(0)}×${r.reps}  1RM: ${r.oneRepMax.toStringAsFixed(0)} ${r.unit}',
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
                          ],
                        ),
                      ),
                    ),
                  );
                },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Botón + agregar ejercicio a la sesión (sin tocar la rutina)
          Builder(
            builder: (context) {
              final day = sortedDays[safeIndex];
              final sessionExtras = ref.watch(sessionExtraExercisesProvider);
              final routineExercises = grouped[day]!;
              final extraExercises = sessionExtras[day] ?? [];
              final allNames = [...routineExercises, ...extraExercises]
                  .map((e) => e.name.toLowerCase())
                  .toSet();
              return GestureDetector(
                onTap: () => _showAddSessionExerciseSheet(
                    context, ref, day, allNames),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCarbon,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.dividerColor,
                        width: 0.5,
                        style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 16, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(
                        'Agregar ejercicio a la sesión',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Day indicator dots
          if (sortedDays.length > 1)
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

  // ─────────────────────────────────────────────────────────────────────────
  // Di\u00e1logo para editar sets/reps de sesi\u00f3n (NO modifica la rutina original)
  // ─────────────────────────────────────────────────────────────────────────
  void _showSessionEditDialog(
    BuildContext context,
    WidgetRef ref,
    RoutineExercise exercise,
    int currentSets,
    int currentReps,
  ) {
    int tempSets = currentSets;
    int tempReps = currentReps;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.midnightGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.dividerColor),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AJUSTE DE SESI\u00d3N',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.electricCyan,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exercise.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Plan original: ${exercise.sets}\u00d7${exercise.reps} \u2014 Solo afecta esta sesi\u00f3n',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Series
              _buildStepRow(
                label: 'Series',
                value: tempSets,
                min: 1,
                max: 20,
                onDecrement: () => setDialogState(() {
                  if (tempSets > 1) tempSets--;
                }),
                onIncrement: () => setDialogState(() {
                  if (tempSets < 20) tempSets++;
                }),
              ),
              const SizedBox(height: 16),
              // Repeticiones
              _buildStepRow(
                label: 'Repeticiones',
                value: tempReps,
                min: 1,
                max: 50,
                onDecrement: () => setDialogState(() {
                  if (tempReps > 1) tempReps--;
                }),
                onIncrement: () => setDialogState(() {
                  if (tempReps < 50) tempReps++;
                }),
              ),
            ],
          ),
          actions: [
            // Restaurar plan original
            TextButton(
              onPressed: () {
                final overrides =
                    Map<String, ({int sets, int reps})>.from(
                        ref.read(sessionOverridesProvider));
                overrides.remove(exercise.name);
                ref.read(sessionOverridesProvider.notifier).state =
                    overrides;
                Navigator.pop(ctx);
              },
              child: const Text('Restaurar',
                  style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                final overrides =
                    Map<String, ({int sets, int reps})>.from(
                        ref.read(sessionOverridesProvider));
                overrides[exercise.name] =
                    (sets: tempSets, reps: tempReps);
                ref.read(sessionOverridesProvider.notifier).state =
                    overrides;
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: AppTheme.darkCarbon,
              ),
              child: const Text('Aplicar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Row(
          children: [
            _stepBtn(Icons.remove, onDecrement, value <= min),
            const SizedBox(width: 12),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _stepBtn(Icons.add, onIncrement, value >= max),
          ],
        ),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: disabled
              ? AppTheme.darkCarbon
              : AppTheme.electricCyan.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled
                ? AppTheme.dividerColor
                : AppTheme.electricCyan.withOpacity(0.4),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: disabled ? Colors.white24 : AppTheme.electricCyan,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom-sheet para reemplazar un ejercicio durante la sesi\u00f3n
  // ─────────────────────────────────────────────────────────────────────────
  void _showSwapExerciseSheet(
    BuildContext context,
    WidgetRef ref,
    Routine routine,
    RoutineExercise exercise,
    CalculatorNotifier calcNotifier,
  ) {
    final TextEditingController searchCtrl = TextEditingController();
    final history = ref.read(historyProvider);
    final routines = ref.read(routinesProvider);

    // Nombres ya existentes en el día (para validar duplicados)
    final Map<String, List<RoutineExercise>> grouped2 = {};
    for (var ex in routine.exercises) {
      grouped2.putIfAbsent(ex.dayGroup, () => []).add(ex);
    }
    final existingNamesInDay = (grouped2[exercise.dayGroup] ?? [])
        .map((e) => e.name.toLowerCase())
        .toSet();

    // Universo completo: historial + todos los de todas las rutinas
    final Set<String> allKnown = {};
    for (final r in history) {
      allKnown.add(r.exerciseName.trim());
    }
    for (final r in routines) {
      for (final ex in r.exercises) {
        allKnown.add(ex.name.trim());
      }
    }

    // Ejercicios únicos del historial + rutinas, excluyendo los que ya están en el día de hoy
    final List<String> universeExercises = allKnown
        .where((n) => !existingNamesInDay.contains(n.toLowerCase()))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? universeExercises
                : universeExercises
                    .where((n) => n.toLowerCase().contains(query))
                    .toList();
            final bool queryIsNew = query.isNotEmpty &&
                !universeExercises
                    .any((n) => n.toLowerCase() == query);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.midnightGrey,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Título
                    Text(
                      'CAMBIAR EJERCICIO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.voltYellow,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reemplazando: ${exercise.name}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Buscador
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar o escribir nombre nuevo…',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white38, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppTheme.voltYellow),
                        ),
                        filled: true,
                        fillColor: AppTheme.darkCarbon,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => setSheet(() {}),
                    ),
                    const SizedBox(height: 12),
                    // Lista de sugerencias + opción "nuevo"
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Opción crear nuevo si no existe en historial
                          if (queryIsNew)
                            _swapOption(
                              ctx: ctx,
                              ref: ref,
                              icon: Icons.add_circle_outline,
                              iconColor: AppTheme.electricCyan,
                              label: 'Nuevo: "${searchCtrl.text.trim()}"',
                              sublabel: 'Agregar ejercicio nuevo',
                              routine: routine,
                              oldExercise: exercise,
                              newName: searchCtrl.text.trim(),
                              calcNotifier: calcNotifier,
                              blocked: false,
                            ),
                          ...filtered.map(
                            (name) => _swapOption(
                              ctx: ctx,
                              ref: ref,
                              icon: Icons.fitness_center,
                              iconColor: Colors.white38,
                              label: name,
                              sublabel: 'Del historial/rutinas',
                              routine: routine,
                              oldExercise: exercise,
                              newName: name,
                              calcNotifier: calcNotifier,
                              blocked: false,
                            ),
                          ),
                          if (filtered.isEmpty && !queryIsNew)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'Escribe el nombre del ejercicio nuevo',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white38, fontSize: 13),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _swapOption({
    required BuildContext ctx,
    required WidgetRef ref,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    required Routine routine,
    required RoutineExercise oldExercise,
    required String newName,
    required CalculatorNotifier calcNotifier,
    bool blocked = false,
  }) {
    return InkWell(
      onTap: blocked ? null : () async {
        final routinesNotifier = ref.read(routinesProvider.notifier);
        // 1. Eliminar el ejercicio viejo
        await routinesNotifier.removeExerciseFromRoutine(
            routine.id, oldExercise.name);
        // 2. Insertar el nuevo con los mismos sets/reps/dayGroup
        await routinesNotifier.addExerciseToRoutine(
          routine.id,
          newName.trim(),
          sets: oldExercise.sets,
          reps: oldExercise.reps,
          dayGroup: oldExercise.dayGroup,
        );
        // 3. Si el ejercicio activo era el que cambiamos, actualizar el estado
        if (ref.read(currentExerciseNameProvider) == oldExercise.name) {
          ref.read(currentExerciseNameProvider.notifier).state = newName.trim();
          final historyList = ref.read(historyProvider);
          final exRecords = historyList.where((r) =>
              r.exerciseName.trim().toLowerCase() ==
              newName.trim().toLowerCase());
          if (exRecords.isNotEmpty) {
            calcNotifier.updateWeight(exRecords.first.weight);
            calcNotifier.updateReps(exRecords.first.reps);
          } else {
            calcNotifier.updateReps(oldExercise.reps);
          }
        }
        if (ctx.mounted) Navigator.pop(ctx);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content:
                  Text('"${oldExercise.name}" reemplazado por "$newName"'),
              backgroundColor: AppTheme.electricCyan,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCarbon,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.dividerColor, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom-sheet para AGREGAR un ejercicio extra a la sesi\u00f3n (sin tocar rutina)
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddSessionExerciseSheet(
    BuildContext context,
    WidgetRef ref,
    String dayGroup,
    Set<String> existingNamesLower,
  ) {
    final TextEditingController searchCtrl = TextEditingController();
    final history = ref.read(historyProvider);
    final routines = ref.read(routinesProvider);

    // Universo completo: ejercicios del historial + todos los de todas las rutinas
    final Set<String> allKnown = {};
    for (final r in history) {
      allKnown.add(r.exerciseName.trim());
    }
    for (final routine in routines) {
      for (final ex in routine.exercises) {
        allKnown.add(ex.name.trim());
      }
    }

    final List<String> historyExercises = allKnown
        .where((n) => !existingNamesLower.contains(n.toLowerCase()))
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? historyExercises
                : historyExercises
                    .where((n) => n.toLowerCase().contains(query))
                    .toList();
            final bool queryIsNew = query.isNotEmpty &&
                !historyExercises.any((n) => n.toLowerCase() == query);
            final bool queryDuplicate = query.isNotEmpty &&
                existingNamesLower.contains(query);

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.midnightGrey,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'AGREGAR A LA SESI\u00d3N',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11, fontWeight: FontWeight.bold,
                        color: AppTheme.electricCyan, letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No modifica tu rutina original',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, color: Colors.white38),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar o escribir nombre nuevo\u2026',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white38, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: queryDuplicate
                                ? Colors.red
                                : AppTheme.electricCyan,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.darkCarbon,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        suffixIcon: queryDuplicate
                            ? const Icon(Icons.warning_amber_rounded,
                                color: Colors.red, size: 18)
                            : null,
                      ),
                      onChanged: (_) => setSheet(() {}),
                    ),
                    if (queryDuplicate) ...[
                      const SizedBox(height: 6),
                      Text(
                        '\u26a0 Este ejercicio ya est\u00e1 en el d\u00eda',
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.35),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          if (queryIsNew && !queryDuplicate)
                            _addSessionOption(
                              ctx: ctx,
                              ref: ref,
                              icon: Icons.add_circle_outline,
                              iconColor: AppTheme.electricCyan,
                              label:
                                  'Nuevo: "${searchCtrl.text.trim()}"',
                              sublabel: 'Agregar ejercicio nuevo',
                              name: searchCtrl.text.trim(),
                              dayGroup: dayGroup,
                            ),
                          ...filtered.map(
                            (name) => _addSessionOption(
                              ctx: ctx,
                              ref: ref,
                              icon: Icons.fitness_center,
                              iconColor: Colors.white38,
                              label: name,
                              sublabel: 'Del historial',
                              name: name,
                              dayGroup: dayGroup,
                            ),
                          ),
                          if (filtered.isEmpty && !queryIsNew)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'Escribe el nombre del ejercicio a agregar',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white38, fontSize: 13),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _addSessionOption({
    required BuildContext ctx,
    required WidgetRef ref,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    required String name,
    required String dayGroup,
  }) {
    return InkWell(
      onTap: () {
        final extras = Map<String, List<RoutineExercise>>.from(
            ref.read(sessionExtraExercisesProvider));
        final dayList = List<RoutineExercise>.from(extras[dayGroup] ?? []);
        dayList.add(RoutineExercise(
          name: name.trim(),
          sets: 3,
          reps: 10,
          dayGroup: dayGroup,
        ));
        extras[dayGroup] = dayList;
        ref.read(sessionExtraExercisesProvider.notifier).state = extras;
        if (ctx.mounted) Navigator.pop(ctx);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('"$name" agregado a la sesi\u00f3n'),
              backgroundColor: AppTheme.electricCyan,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCarbon,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.dividerColor, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(sublabel,
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
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
  final int minReps;
  final int maxReps;
  final ValueChanged<int> onChanged;

  const RepsSelectorInput({
    super.key,
    required this.value,
    required this.minReps,
    required this.maxReps,
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
                    if (parsed != null && parsed >= widget.minReps && parsed <= widget.maxReps) {
                      widget.onChanged(parsed);
                    }
                  },
                ),
              ),
            ],
          ),
          Slider(
            value: widget.value.toDouble().clamp(widget.minReps.toDouble(), widget.maxReps.toDouble()),
            min: widget.minReps.toDouble(),
            max: widget.maxReps.toDouble(),
            divisions: (widget.maxReps - widget.minReps).clamp(1, 100),
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

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.initialSeconds;
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

  void _playBeep() {
    if (!widget.enableBeep) return;
    _fallbackBeep();
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
