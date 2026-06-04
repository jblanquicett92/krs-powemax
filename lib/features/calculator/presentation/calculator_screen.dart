import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../settings/state/settings_notifier.dart';
import '../state/calculator_notifier.dart';
import '../../history/state/history_notifier.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calcState = ref.watch(calculatorProvider);
    final calcNotifier = ref.read(calculatorProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final historyNotifier = ref.read(historyProvider.notifier);

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
            const SizedBox(height: 20),

            // SELECCIÓN DE FÓRMULA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('calc_formula', ref),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    _buildFormulaChip(ref, 'Epley', 'epley', calcState.formula == 'epley', calcNotifier),
                    const SizedBox(width: 8),
                    _buildFormulaChip(ref, 'Brzycki', 'brzycki', calcState.formula == 'brzycki', calcNotifier),
                  ],
                ),
              ],
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
    final TextEditingController controller = TextEditingController();

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

                  // Chips de ejercicios guardados previamente
                  if (savedExercises.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      "Ejercicios guardados:",
                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: savedExercises.map((ex) {
                        return ActionChip(
                          label: Text(ex),
                          backgroundColor: AppTheme.darkCarbon,
                          side: const BorderSide(color: AppTheme.dividerColor),
                          labelStyle: const TextStyle(
                            color: AppTheme.electricCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          onPressed: () {
                            setStateDialog(() {
                              controller.text = ex;
                              // Posicionar cursor al final
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                            });
                          },
                        );
                      }).toList(),
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
                if (exercise.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ctx.tr('calc_error_empty', ref)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                historyNotifier.addRecord(
                  exerciseName: exercise,
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
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
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
