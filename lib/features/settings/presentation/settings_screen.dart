import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../state/settings_notifier.dart';
import '../../../core/constants/version.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;
  bool _isDeveloperModeEnabled = false;

  void _handleVersionTap() {
    setState(() {
      _versionTapCount++;
      debugPrint("[SettingsScreen] Version tapped. Current count: $_versionTapCount/7");
      
      // Enviar log también a Crashlytics por si ocurre un crash mientras intentan activar el modo
      try {
        FirebaseCrashlytics.instance.log("Developer mode tap count: $_versionTapCount/7");
      } catch (_) {}

      if (_versionTapCount >= 7) {
        if (!_isDeveloperModeEnabled) {
          _isDeveloperModeEnabled = true;
          debugPrint("[SettingsScreen] 🔥 Developer Mode unlocked!");
          _showSuccessSnackBar(context, "¡Ahora eres un desarrollador! 🔥 Mode Debug activado");
        }
      } else if (_versionTapCount > 2) {
        final remaining = 7 - _versionTapCount;
        debugPrint("[SettingsScreen] Taps remaining to unlock developer mode: $remaining");
        _showSuccessSnackBar(
          context, 
          "Estás a $remaining toques de activar el modo desarrollador"
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('settings_title', ref),
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
            // SECCIÓN 1: AJUSTES PREFERIDOS
            _buildSectionHeader(context, "Preferencias Generales"),
            const SizedBox(height: 8),



            // Selector de Unidades
            _buildSettingTile(
              context,
              icon: Icons.scale,
              title: context.tr('settings_units', ref),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleOption(
                    ref,
                    label: "KG",
                    value: 'kg',
                    selectedValue: settings.weightUnit,
                    onTap: () {
                      settingsNotifier.setWeightUnit('kg');
                      _showSuccessSnackBar(context, "Unidad cambiada a KG");
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildToggleOption(
                    ref,
                    label: "LBS",
                    value: 'lbs',
                    selectedValue: settings.weightUnit,
                    onTap: () {
                      settingsNotifier.setWeightUnit('lbs');
                      _showSuccessSnackBar(context, "Unidad cambiada a LBS");
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Selector de Fórmula por defecto
            _buildSettingTile(
              context,
              icon: Icons.functions,
              title: context.tr('settings_default_formula', ref),
              trailing: DropdownButton<String>(
                value: settings.defaultFormula,
                dropdownColor: AppTheme.midnightGrey,
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'epley', child: Text("Epley")),
                  DropdownMenuItem(value: 'brzycki', child: Text("Brzycki")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    settingsNotifier.setDefaultFormula(val);
                    _showSuccessSnackBar(context, "Fórmula por defecto actualizada");
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            // Selector de Tiempo de Descanso
            _buildSettingTile(
              context,
              icon: Icons.timer_outlined,
              title: "Descansos",
              trailing: DropdownButton<int>(
                value: settings.restTimeBetweenExercises,
                dropdownColor: AppTheme.midnightGrey,
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 30, child: Text("30 s")),
                  DropdownMenuItem(value: 60, child: Text("60 s")),
                  DropdownMenuItem(value: 90, child: Text("90 s")),
                  DropdownMenuItem(value: 120, child: Text("2 min")),
                  DropdownMenuItem(value: 150, child: Text("2:30 min")),
                  DropdownMenuItem(value: 180, child: Text("3 min")),
                  DropdownMenuItem(value: 240, child: Text("4 min")),
                  DropdownMenuItem(value: 300, child: Text("5 min")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    settingsNotifier.setRestTime(val);
                    _showSuccessSnackBar(context, "Tiempo de descanso actualizado");
                  }
                },
              ),
            ),
            const SizedBox(height: 22),



            // SECCIÓN 2: RANGO DEL SELECTOR DE PESO
            _buildSectionHeader(context, "Rango de Peso"),
            const SizedBox(height: 8),

            _WeightRangeTile(
              minWeight: settings.minWeight,
              maxWeight: settings.maxWeight,
              onMinChanged: (v) => settingsNotifier.setMinWeight(v),
              onMaxChanged: (v) => settingsNotifier.setMaxWeight(v),
            ),
            const SizedBox(height: 22),

            _buildSectionHeader(context, "Rango de Repeticiones"),
            const SizedBox(height: 8),

            _RepsRangeTile(
              minReps: settings.minReps,
              maxReps: settings.maxReps,
              onMinChanged: (v) => settingsNotifier.setMinReps(v),
              onMaxChanged: (v) => settingsNotifier.setMaxReps(v),
            ),
            const SizedBox(height: 22),


            // SECCIÓN 3: ACERCA DE LA APLICACIÓN
            _buildSectionHeader(context, context.tr('settings_about', ref)),
            const SizedBox(height: 8),

            Container(
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
                    children: [
                      Image.asset(
                        'assets/logo_no_background.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "PowerMax 1RM",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: _handleVersionTap,
                              behavior: HitTestBehavior.opaque,
                              child: ref.watch(appVersionProvider).when(
                                data: (version) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    "Versión $version",
                                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                                  ),
                                ),
                                loading: () => const Text(
                                  "Versión ...",
                                  style: TextStyle(fontSize: 11, color: Colors.white38),
                                ),
                                error: (err, __) => Text(
                                  "Versión no disponible ($err)",
                                  style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('settings_about_desc', ref),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppTheme.dividerColor),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse('https://koresis.com/');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.code_rounded, color: AppTheme.voltYellow, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Desarrollado por Koresis",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.voltYellow,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new_rounded, color: AppTheme.voltYellow, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isDeveloperModeEnabled) ...[
              // ── SECCIÓN DEBUG: CRASHLYTICS ──────────────────────────────
              _buildSectionHeader(context, "🔥 Crashlytics Debug"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.midnightGrey,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usa estos botones para verificar que Crashlytics '
                    'recibe datos. Los crashes fatales se envían al '
                    'siguiente arranque de la app.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón 1: Log de prueba
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        try {
                          FirebaseCrashlytics.instance.log(
                            'Test log from settings screen at ${DateTime.now()}',
                          );
                          FirebaseCrashlytics.instance.setCustomKey(
                            'test_key', 'settings_debug',
                          );
                          _showSuccessSnackBar(
                            context,
                            '✅ Log y custom key enviados a Crashlytics',
                          );
                        } catch (e) {
                          _showSuccessSnackBar(
                            context,
                            '❌ Error: Firebase no está disponible',
                          );
                        }
                      },
                      icon: const Icon(Icons.note_add, size: 16),
                      label: const Text('Enviar log de prueba'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.electricCyan,
                        side: const BorderSide(color: AppTheme.electricCyan),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón 2: Error no-fatal
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        try {
                          throw Exception(
                            'Test non-fatal error from PowerMax 1RM settings',
                          );
                        } catch (e, stack) {
                          try {
                            FirebaseCrashlytics.instance.recordError(
                              e,
                              stack,
                              reason: 'Non-fatal test from settings',
                              fatal: false,
                            );
                            _showSuccessSnackBar(
                              context,
                              '⚠️ Error no-fatal enviado a Crashlytics',
                            );
                          } catch (ex) {
                            _showSuccessSnackBar(
                              context,
                              '❌ Error: Firebase no está disponible',
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.warning_amber, size: 16),
                      label: const Text('Enviar error no-fatal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.voltYellow,
                        side: const BorderSide(color: AppTheme.voltYellow),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón 3: Crash fatal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.midnightGrey,
                            title: Text(
                              '⚠️ Crash de prueba',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              '¡Esto cerrará la app inmediatamente!\n\n'
                              'El crash se reportará a Firebase Crashlytics '
                              'cuando la app se abra de nuevo.\n\n'
                              '¿Continuar?',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'Cancelar',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  try {
                                    FirebaseCrashlytics.instance.crash();
                                  } catch (e) {
                                    Navigator.pop(ctx);
                                    _showSuccessSnackBar(
                                      context,
                                      '❌ Error: Firebase no está activo',
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: Text(
                                  'Sí, provocar crash',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.dangerous, size: 16),
                      label: const Text('Provocar crash fatal (test)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ], // Cierra Column children del Container
              ), // Cierra Column del Container
            ), // Cierra Container
          ], // Cierra conditional spread operator
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.voltYellow,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    WidgetRef ref, {
    required String label,
    required String value,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
    final bool isSelected = value == selectedValue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.voltYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.voltYellow : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.darkCarbon : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// Widget aislado para editar el rango de peso mínimo y máximo
class _WeightRangeTile extends StatefulWidget {
  final double minWeight;
  final double maxWeight;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;

  const _WeightRangeTile({
    required this.minWeight,
    required this.maxWeight,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  @override
  State<_WeightRangeTile> createState() => _WeightRangeTileState();
}

class _WeightRangeTileState extends State<_WeightRangeTile> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.minWeight.toStringAsFixed(1));
    _maxController = TextEditingController(text: widget.maxWeight.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _WeightRangeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minWeight != widget.minWeight) {
      _minController.text = widget.minWeight.toStringAsFixed(1);
    }
    if (oldWidget.maxWeight != widget.maxWeight) {
      _maxController.text = widget.maxWeight.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _validate() {
    final double? minVal = double.tryParse(_minController.text.replaceAll(',', '.'));
    final double? maxVal = double.tryParse(_maxController.text.replaceAll(',', '.'));

    if (minVal == null || maxVal == null) {
      setState(() => _errorMsg = 'Ingresa valores numéricos válidos.');
      return;
    }
    if (minVal < 0) {
      setState(() => _errorMsg = 'El mínimo no puede ser negativo.');
      return;
    }
    if (maxVal <= minVal) {
      setState(() => _errorMsg = 'El máximo debe ser mayor que el mínimo.');
      return;
    }
    if (maxVal > 1000) {
      setState(() => _errorMsg = 'El máximo no puede superar 1000.');
      return;
    }

    setState(() => _errorMsg = null);
    widget.onMinChanged(minVal);
    widget.onMaxChanged(maxVal);
    _showSuccessSnackBar(context, "Rango de peso aplicado correctamente");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción
          Text(
            'Define el rango del selector de peso en la calculadora.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Fila de inputs
          Row(
            children: [
              // Mínimo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÍNIMO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.voltYellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _minController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'kg/lbs',
                        suffixStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                        ),
                      ),
                      onSubmitted: (_) => _validate(),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward, color: Colors.white24, size: 20),
              ),
              // Máximo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÁXIMO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.electricCyan,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _maxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'kg/lbs',
                        suffixStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.electricCyan),
                        ),
                      ),
                      onSubmitted: (_) => _validate(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Botón Aplicar + error
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _validate,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Aplicar rango'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      backgroundColor: AppTheme.midnightGrey,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppTheme.electricCyan, width: 0.8),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

// Widget aislado para editar el rango de repeticiones mínimo y máximo
class _RepsRangeTile extends StatefulWidget {
  final int minReps;
  final int maxReps;
  final ValueChanged<int> onMinChanged;
  final ValueChanged<int> onMaxChanged;

  const _RepsRangeTile({
    required this.minReps,
    required this.maxReps,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  @override
  State<_RepsRangeTile> createState() => _RepsRangeTileState();
}

class _RepsRangeTileState extends State<_RepsRangeTile> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.minReps.toString());
    _maxController = TextEditingController(text: widget.maxReps.toString());
  }

  @override
  void didUpdateWidget(covariant _RepsRangeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minReps != widget.minReps) {
      _minController.text = widget.minReps.toString();
    }
    if (oldWidget.maxReps != widget.maxReps) {
      _maxController.text = widget.maxReps.toString();
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _validate() {
    final int? minVal = int.tryParse(_minController.text);
    final int? maxVal = int.tryParse(_maxController.text);

    if (minVal == null || maxVal == null) {
      setState(() => _errorMsg = 'Ingresa valores numéricos válidos.');
      return;
    }
    if (minVal < 1) {
      setState(() => _errorMsg = 'El mínimo no puede ser menor a 1.');
      return;
    }
    if (maxVal <= minVal) {
      setState(() => _errorMsg = 'El máximo debe ser mayor que el mínimo.');
      return;
    }
    if (maxVal > 100) {
      setState(() => _errorMsg = 'El máximo no puede superar 100.');
      return;
    }

    setState(() => _errorMsg = null);
    widget.onMinChanged(minVal);
    widget.onMaxChanged(maxVal);
    _showSuccessSnackBar(context, "Rango de repeticiones aplicado correctamente");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.midnightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción
          Text(
            'Define el rango del selector de repeticiones en la calculadora.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Fila de inputs
          Row(
            children: [
              // Mínimo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÍNIMO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.voltYellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _minController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'reps',
                        suffixStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                        ),
                      ),
                      onSubmitted: (_) => _validate(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Máximo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÁXIMO',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.voltYellow,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _maxController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        suffixText: 'reps',
                        suffixStyle: const TextStyle(color: Colors.white38, fontSize: 10),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.voltYellow),
                        ),
                      ),
                      onSubmitted: (_) => _validate(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Botón Aplicar + error
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _validate,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Aplicar rango'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}





