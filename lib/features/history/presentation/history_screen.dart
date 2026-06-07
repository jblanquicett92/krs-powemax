import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../state/history_notifier.dart';
import '../data/workout_record.dart';
import '../../profile/state/routines_notifier.dart';
import '../../profile/data/routine.dart';
import '../../settings/state/settings_notifier.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _expandedSessionExerciseKey;
  DateTime _viewedWeekDate = DateTime.now();
  DateTime _selectedCalendarDay = DateTime.now();

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat("D").format(date));
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      return 52;
    } else if (woy > 53) {
      return 1;
    }
    return woy;
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(historyProvider);
    final settings = ref.watch(settingsProvider);

    final monday = _getMonday(_viewedWeekDate);
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    
    // Formato de rango de fechas de la semana
    final weekStartStr = DateFormat('d MMM', 'es').format(monday);
    final weekEndStr = DateFormat('d MMM, yyyy', 'es').format(weekDays.last);
    final weekNum = _getWeekNumber(_viewedWeekDate);

    // Obtener los registros del día seleccionado
    final selectedDayRecords = records.where((r) =>
        r.date.year == _selectedCalendarDay.year &&
        r.date.month == _selectedCalendarDay.month &&
        r.date.day == _selectedCalendarDay.day
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('history_title', ref),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CONTROLES DE NAVEGACIÓN SEMANAL
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.midnightGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _viewedWeekDate = _viewedWeekDate.subtract(const Duration(days: 7));
                      });
                    },
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "SEMANA $weekNum DEL AÑO",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.voltYellow,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$weekStartStr - $weekEndStr",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _viewedWeekDate = _viewedWeekDate.add(const Duration(days: 7));
                      });
                    },
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // GRILLA DE DIAS (LUNES A DOMINGO)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (idx) {
                final dayDate = weekDays[idx];
                
                final hasWorkout = records.any((r) =>
                    r.date.year == dayDate.year &&
                    r.date.month == dayDate.month &&
                    r.date.day == dayDate.day);
                    
                final isSelected = dayDate.year == _selectedCalendarDay.year &&
                    dayDate.month == _selectedCalendarDay.month &&
                    dayDate.day == _selectedCalendarDay.day;
                    
                final dayNames = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
                final dayLabel = dayNames[idx];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCalendarDay = dayDate;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.voltYellow
                            : AppTheme.midnightGrey,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.voltYellow
                              : hasWorkout
                                  ? AppTheme.voltYellow.withOpacity(0.5)
                                  : AppTheme.dividerColor,
                          width: isSelected ? 1.2 : 0.6,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayLabel,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppTheme.darkCarbon
                                  : Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${dayDate.day}",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.darkCarbon : Colors.white,
                            ),
                          ),
                          if (hasWorkout) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.darkCarbon
                                    : AppTheme.voltYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // DETALLES DEL DÍA SELECCIONADO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.midnightGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'es').format(_selectedCalendarDay).toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.voltYellow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedDayRecords.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Text(
                            "No se registraron marcas de entrenamiento este día.",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showAddPastWorkoutSheet(context),
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('Registrar entrenamiento pasado'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.voltYellow.withOpacity(0.12),
                              foregroundColor: AppTheme.voltYellow,
                              side: BorderSide(color: AppTheme.voltYellow.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Builder(
                      builder: (context) {
                        final sortedRecords = List<WorkoutRecord>.from(selectedDayRecords)
                          ..sort((a, b) => a.date.compareTo(b.date));
                        final firstRecord = sortedRecords.first;
                        final lastRecord = sortedRecords.last;
                        final duration = lastRecord.date.difference(firstRecord.date);
                        final durationMin = selectedDayRecords.length <= 1 ? 0 : (duration.inMinutes == 0 ? 1 : duration.inMinutes);
                        final totalVolume = selectedDayRecords.fold<double>(0, (sum, r) => sum + (r.weight * r.reps));

                        // Agrupar por ejercicio
                        final Map<String, List<WorkoutRecord>> exerciseGroups = {};
                        for (var r in selectedDayRecords) {
                          exerciseGroups.putIfAbsent(r.exerciseName, () => []).add(r);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Duración: $durationMin min",
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fitness_center, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "Volumen: ${totalVolume.toStringAsFixed(0)} ${settings.weightUnit}",
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            ...exerciseGroups.entries.map((entry) {
                              final exName = entry.key;
                              final exRecords = entry.value;
                              final maxWeight = exRecords.map((r) => r.weight).reduce((a, b) => a > b ? a : b);
                              
                              final dateKey = "${_selectedCalendarDay.year}-${_selectedCalendarDay.month.toString().padLeft(2, '0')}-${_selectedCalendarDay.day.toString().padLeft(2, '0')}";
                              final isExpanded = _expandedSessionExerciseKey == "${dateKey}_$exName";
                              
                              final allExRecords = records
                                  .where((r) => r.exerciseName.trim().toLowerCase() == exName.trim().toLowerCase())
                                  .toList();
                                  
                              final Map<String, WorkoutRecord> bestByDay = {};
                              for (var r in allExRecords) {
                                final dayKey = "${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}";
                                final existing = bestByDay[dayKey];
                                if (existing == null || r.oneRepMax > existing.oneRepMax) {
                                  bestByDay[dayKey] = r;
                                }
                              }
                              
                              final sortedDaysList = bestByDay.values.toList()
                                ..sort((a, b) => a.date.compareTo(b.date));
                                
                              final selectedDayKey = "${_selectedCalendarDay.year}-${_selectedCalendarDay.month.toString().padLeft(2, '0')}-${_selectedCalendarDay.day.toString().padLeft(2, '0')}";
                              final selectedIdx = sortedDaysList.indexWhere((r) {
                                final rKey = "${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}";
                                return rKey == selectedDayKey;
                              });
                              
                              final List<WorkoutRecord> exerciseChartRecords = [];
                              if (selectedIdx != -1) {
                                final start = selectedIdx - 4 < 0 ? 0 : selectedIdx - 4;
                                for (int i = start; i <= selectedIdx; i++) {
                                  exerciseChartRecords.add(sortedDaysList[i]);
                                }
                              } else {
                                final start = sortedDaysList.length - 5 < 0 ? 0 : sortedDaysList.length - 5;
                                for (int i = start; i < sortedDaysList.length; i++) {
                                  exerciseChartRecords.add(sortedDaysList[i]);
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkCarbon,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.dividerColor),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedSessionExerciseKey = null;
                                          } else {
                                            _expandedSessionExerciseKey = "${dateKey}_$exName";
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                                    color: Colors.white38,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      exName,
                                                      style: GoogleFonts.spaceGrotesk(
                                                        color: AppTheme.electricCyan,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${exRecords.length} series • Máx: ${maxWeight.toStringAsFixed(0)} ${settings.weightUnit}",
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isExpanded) ...[
                                      const Divider(color: Colors.white10, height: 1),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              "Marcas de la sesión:",
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            ...List.generate(exRecords.length, (sIdx) {
                                              final record = exRecords[sIdx];
                                              return Container(
                                                margin: const EdgeInsets.symmetric(vertical: 4),
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.midnightGrey,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  "Serie ${sIdx + 1}: ${record.weight.toStringAsFixed(1)} ${record.unit} x ${record.reps} reps (1RM: ${record.oneRepMax.toStringAsFixed(1)} ${record.unit})",
                                                  style: GoogleFonts.spaceGrotesk(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              );
                                            }),
                                            const SizedBox(height: 12),
                                            Text(
                                              "Progreso del 1RM:",
                                              style: GoogleFonts.spaceGrotesk(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              height: 160,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppTheme.midnightGrey,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: exerciseChartRecords.length >= 2
                                                  ? _buildCompactProgressChart(exerciseChartRecords, settings.weightUnit)
                                                  : Center(
                                                      child: Text(
                                                        "Registra marcas en diferentes días para ver el progreso.",
                                                        style: GoogleFonts.spaceGrotesk(
                                                          color: Colors.white38,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      }
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactProgressChart(List<WorkoutRecord> chartRecords, String unit) {
    List<FlSpot> spots = [];
    for (int i = 0; i < chartRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), chartRecords[i].oneRepMax));
    }

    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (final spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }

    if (minY == maxY) {
      // Si todos los valores de 1RM son iguales (sin cambio), darle un margen hacia arriba y abajo
      minY = (minY - 10).clamp(0, double.infinity);
      maxY = maxY + 10;
    } else {
      // Si hay varianza, darle un margen del 10% para que no toque los bordes
      final range = maxY - minY;
      minY = (minY - range * 0.15).clamp(0, double.infinity);
      maxY = maxY + range * 0.15;
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
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(color: Colors.white38, fontSize: 9),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 18,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                return Text(
                  "${val.toInt()}",
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (chartRecords.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.electricCyan,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.electricCyan.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPastWorkoutSheet(BuildContext context) {
    final routines = ref.read(routinesProvider);
    final settings = ref.read(settingsProvider);

    if (routines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No tienes ninguna rutina creada. Ve a Perfil > Mis Rutinas."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.midnightGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                'REGISTRAR ENTRENAMIENTO: PASO 1',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.voltYellow,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona la rutina de entrenamiento:',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: routines.length,
                  itemBuilder: (context, idx) {
                    final routine = routines[idx];
                    return Card(
                      color: AppTheme.darkCarbon,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          routine.name,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "${routine.exercises.length} ejercicios registrados",
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.voltYellow),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showAddPastWorkoutDayGroupSheet(context, routine, settings.weightUnit);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddPastWorkoutDayGroupSheet(BuildContext context, Routine routine, String unit) {
    // Obtener los grupos de días únicos de la rutina seleccionada
    final Set<String> dayNames = routine.exercises.map((e) => e.dayGroup).toSet();
    final List<String> dayGroups = dayNames.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.midnightGrey,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                'REGISTRAR ENTRENAMIENTO: PASO 2',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.voltYellow,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona el día de la rutina "${routine.name}":',
                style: GoogleFonts.spaceGrotesk(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dayGroups.length,
                  itemBuilder: (context, idx) {
                    final day = dayGroups[idx];
                    return Card(
                      color: AppTheme.darkCarbon,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          day,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.voltYellow),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showFillPastExercisesDialog(context, routine, day, unit);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFillPastExercisesDialog(
    BuildContext context,
    Routine routine,
    String dayGroup,
    String unit,
  ) {
    // Filtrar los ejercicios de ese dayGroup
    final exercises = routine.exercises.where((e) => e.dayGroup == dayGroup).toList();
    if (exercises.isEmpty) return;

    // Controladores de peso para cada ejercicio
    final Map<String, TextEditingController> weightControllers = {};
    for (final ex in exercises) {
      weightControllers[ex.name] = TextEditingController(text: "30.0");
    }

    // Listado de ejercicios activos/incluidos
    final Set<String> excludedExercises = {};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.midnightGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.dividerColor),
              ),
              title: Text(
                "Registrar: $dayGroup",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: exercises.length,
                  itemBuilder: (context, idx) {
                    final ex = exercises[idx];
                    final isExcluded = excludedExercises.contains(ex.name);

                    return Opacity(
                      opacity: isExcluded ? 0.4 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            // Botón de habilitar/deshabilitar (Checkbox o Eliminar)
                            IconButton(
                              icon: Icon(
                                isExcluded ? Icons.add_circle : Icons.remove_circle,
                                color: isExcluded ? Colors.green : Colors.redAccent,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setDialogState(() {
                                  if (isExcluded) {
                                    excludedExercises.remove(ex.name);
                                  } else {
                                    excludedExercises.add(ex.name);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "${ex.sets} series x ${ex.reps} reps",
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              height: 38,
                              child: TextField(
                                controller: weightControllers[ex.name],
                                enabled: !isExcluded,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  suffixText: " $unit",
                                  suffixStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppTheme.dividerColor),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.white10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppTheme.voltYellow),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final historyNotifier = ref.read(historyProvider.notifier);
                    
                    // Guardar cada ejercicio con las series y repeticiones planificadas a esa fecha
                    int itemIndex = 0;
                    for (final ex in exercises) {
                      if (excludedExercises.contains(ex.name)) continue;

                      final weightStr = weightControllers[ex.name]?.text ?? "30.0";
                      final double weight = double.tryParse(weightStr.replaceAll(',', '.')) ?? 30.0;
                      
                      // Calcular 1RM estimado (fórmula por defecto Epley)
                      // 1RM = peso * (1 + reps/30)
                      final double oneRepMax = double.parse((weight * (1.0 + ex.reps / 30.0)).toStringAsFixed(1));

                      // Respetar las series planificadas: Guardar tantas filas (series) como indique el ejercicio
                      for (int setIdx = 0; setIdx < ex.sets; setIdx++) {
                        // Agregar desfase en minutos/segundos para preservar el orden cronológico
                        final historicalDate = DateTime(
                          _selectedCalendarDay.year,
                          _selectedCalendarDay.month,
                          _selectedCalendarDay.day,
                          12, // mediodía
                          itemIndex, // minuto desfasado por ejercicio
                          setIdx, // segundo desfasado por serie
                        );

                        historyNotifier.addRecord(
                          exerciseName: ex.name,
                          weight: weight,
                          reps: ex.reps,
                          oneRepMax: oneRepMax,
                          unit: unit,
                          formula: 'epley',
                          customDate: historicalDate,
                        );
                      }
                      itemIndex++;
                    }

                    Navigator.pop(ctx);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("¡Entrenamiento registrado correctamente en el pasado!"),
                        backgroundColor: AppTheme.voltYellow,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.voltYellow,
                    foregroundColor: AppTheme.darkCarbon,
                  ),
                  child: const Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
