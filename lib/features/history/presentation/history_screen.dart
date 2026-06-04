import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../state/history_notifier.dart';
import '../data/workout_record.dart';
import '../../settings/state/settings_notifier.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _selectedExercise = "Press de Banca"; // Ejercicio por defecto seleccionado para filtrar la gráfica

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(historyProvider);
    final historyNotifier = ref.read(historyProvider.notifier);
    final settings = ref.watch(settingsProvider);

    // Obtener lista única de ejercicios para los chips de filtro
    final List<String> exercises = records.map((r) => r.exerciseName).toSet().toList();
    if (!exercises.contains(_selectedExercise) && exercises.isNotEmpty) {
      // Ajustar selección si el ejercicio actual ya no existe en los registros
      _selectedExercise = exercises.first;
    }

    // Filtrar registros para la gráfica y la lista
    final filteredRecords = records.where((r) => r.exerciseName.toLowerCase() == _selectedExercise.toLowerCase()).toList();
    // Ordenar los de la gráfica ascendentemente por fecha para el gráfico lineal
    final chartRecords = List<WorkoutRecord>.from(filteredRecords);
    chartRecords.sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('history_title', ref),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: records.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FILTRO DE EJERCICIOS (Chips horizontales)
                  if (exercises.isNotEmpty) ...[
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final ex = exercises[index];
                          final isSelected = ex.toLowerCase() == _selectedExercise.toLowerCase();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(ex),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedExercise = ex;
                                  });
                                }
                              },
                              selectedColor: AppTheme.electricCyan,
                              backgroundColor: AppTheme.midnightGrey,
                              labelStyle: TextStyle(
                                color: isSelected ? AppTheme.darkCarbon : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.electricCyan : AppTheme.dividerColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // GRÁFICO DE PROGRESO DE FUERZA (1RM)
                  if (chartRecords.length >= 2) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      height: 260,
                      decoration: BoxDecoration(
                        color: AppTheme.midnightGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${context.tr('history_chart_title', ref)} - $_selectedExercise",
                            style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.electricCyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _buildProgressChart(chartRecords, settings.weightUnit),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // LISTADO CRONOLÓGICO DE MARCAS
                  Text(
                    "Marcas Registradas",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = filteredRecords[index];
                      return _buildRecordCard(context, ref, record, historyNotifier);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // Vista en caso de que no haya registros
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.midnightGrey,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: const Icon(
                Icons.fitness_center_outlined,
                size: 64,
                color: AppTheme.voltYellow,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Sin marcas registradas aún",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Ve a la pestaña de la calculadora, estima tu 1RM en algún ejercicio y guárdalo para ver tu historial y evolución.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Gráfico lineal del historial usando fl_chart
  Widget _buildProgressChart(List<WorkoutRecord> chartRecords, String unit) {
    // Generar puntos del gráfico
    List<FlSpot> spots = [];
    for (int i = 0; i < chartRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), chartRecords[i].oneRepMax));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int idx = val.toInt();
                if (idx >= 0 && idx < chartRecords.length) {
                  final date = chartRecords[idx].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                return Text(
                  "${val.toInt()} $unit",
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                );
              },
              reservedSize: 45,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (chartRecords.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.electricCyan,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.electricCyan.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de levantamiento individual
  Widget _buildRecordCard(
    BuildContext context,
    WidgetRef ref,
    WorkoutRecord record,
    HistoryNotifier notifier,
  ) {
    final String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(record.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info del levantamiento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$formattedDate • Fórmula: ${record.formula.toUpperCase()}",
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRecordTag(
                      "Levantado",
                      "${record.weight} ${record.unit}",
                      AppTheme.voltYellow,
                    ),
                    const SizedBox(width: 8),
                    _buildRecordTag(
                      "Reps",
                      "${record.reps}",
                      Colors.orangeAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // R1RM Calculado y Botón Borrar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${record.oneRepMax} ${record.unit}",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.electricCyan,
                ),
              ),
              const Text(
                "1RM Estimado",
                style: TextStyle(fontSize: 10, color: Colors.white38),
              ),
              const SizedBox(height: 12),
              IconButton(
                onPressed: () => notifier.deleteRecord(record.id),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mini etiqueta informativa
  Widget _buildRecordTag(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
