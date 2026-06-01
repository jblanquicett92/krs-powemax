import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/state/settings_notifier.dart';

class TrainingZone {
  final int percentage;
  final double calculatedWeight;
  final String categoryKey; // key de traducción para la UI ('zone_warmup', 'zone_hypertrophy', etc.)

  TrainingZone({
    required this.percentage,
    required this.calculatedWeight,
    required this.categoryKey,
  });
}

class CalculatorState {
  final double weight;
  final int reps;
  final String formula; // 'epley', 'brzycki'
  final double calculated1RM;
  final List<TrainingZone> trainingZones;

  CalculatorState({
    required this.weight,
    required this.reps,
    required this.formula,
    required this.calculated1RM,
    required this.trainingZones,
  });

  CalculatorState copyWith({
    double? weight,
    int? reps,
    String? formula,
    double? calculated1RM,
    List<TrainingZone>? trainingZones,
  }) {
    return CalculatorState(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      formula: formula ?? this.formula,
      calculated1RM: calculated1RM ?? this.calculated1RM,
      trainingZones: trainingZones ?? this.trainingZones,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  final Ref ref;

  CalculatorNotifier(this.ref)
      : super(CalculatorState(
          weight: 60.0,
          reps: 5,
          formula: 'epley',
          calculated1RM: 0.0,
          trainingZones: [],
        )) {
    // Al iniciar, sintoniza la fórmula por defecto desde settings
    final defaultFormula = ref.read(settingsProvider).defaultFormula;
    state = state.copyWith(formula: defaultFormula);
    calculate();
  }

  void updateWeight(double newWeight) {
    state = state.copyWith(weight: newWeight);
    calculate();
  }

  void updateReps(int newReps) {
    state = state.copyWith(reps: newReps);
    calculate();
  }

  void updateFormula(String newFormula) {
    state = state.copyWith(formula: newFormula);
    calculate();
  }

  void calculate() {
    double r1rm = 0.0;
    final w = state.weight;
    final r = state.reps;

    if (w <= 0 || r <= 0) {
      state = state.copyWith(calculated1RM: 0.0, trainingZones: []);
      return;
    }

    if (r == 1) {
      // 1 repetición es directamente el 1RM
      r1rm = w;
    } else {
      if (state.formula == 'epley') {
        r1rm = w * (1 + r / 30.0);
      } else {
        // Brzycki (segura hasta unas 10-12 reps)
        double divisor = 1.0278 - (0.0278 * r);
        if (divisor > 0) {
          r1rm = w / divisor;
        } else {
          r1rm = w * (1 + r / 30.0); // Respaldo
        }
      }
    }

    // Redondear a 1 decimal
    r1rm = double.parse(r1rm.toStringAsFixed(1));

    // Generar zonas de entrenamiento
    final List<TrainingZone> zones = [];
    for (int pct = 100; pct >= 50; pct -= 5) {
      final double zoneW = double.parse((r1rm * (pct / 100.0)).toStringAsFixed(1));
      
      String category = 'zone_warmup';
      if (pct >= 85) {
        category = 'zone_strength';
      } else if (pct >= 70) {
        category = 'zone_hypertrophy';
      } else if (pct >= 60) {
        category = 'zone_power';
      }

      zones.add(TrainingZone(
        percentage: pct,
        calculatedWeight: zoneW,
        categoryKey: category,
      ));
    }

    state = state.copyWith(
      calculated1RM: r1rm,
      trainingZones: zones,
    );
  }
}

// Proveedor global de la calculadora
final calculatorProvider = StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier(ref);
});
