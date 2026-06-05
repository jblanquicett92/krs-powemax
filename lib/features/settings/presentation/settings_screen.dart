import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../state/settings_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

            // Selector de Idioma
            _buildSettingTile(
              context,
              icon: Icons.language,
              title: context.tr('settings_language', ref),
              trailing: DropdownButton<String>(
                value: settings.language,
                dropdownColor: AppTheme.midnightGrey,
                style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'es', child: Text("Español (ES)")),
                  DropdownMenuItem(value: 'en', child: Text("English (EN)")),
                  DropdownMenuItem(value: 'pt', child: Text("Português (PT)")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    settingsNotifier.setLanguage(val, ref);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

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
                    onTap: () => settingsNotifier.setWeightUnit('kg'),
                  ),
                  const SizedBox(width: 8),
                  _buildToggleOption(
                    ref,
                    label: "LBS",
                    value: 'lbs',
                    selectedValue: settings.weightUnit,
                    onTap: () => settingsNotifier.setWeightUnit('lbs'),
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
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            // Selector de Tiempo de Descanso
            _buildSettingTile(
              context,
              icon: Icons.timer_outlined,
              title: "Descanso entre ejercicios",
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
                  }
                },
              ),
            ),
            const SizedBox(height: 10),

            // Sonido de Pitido (Activar/Desactivar)
            _buildSettingTile(
              context,
              icon: Icons.volume_up_outlined,
              title: "Sonido del temporizador",
              trailing: Switch(
                value: settings.enableBeep,
                activeColor: AppTheme.voltYellow,
                onChanged: (val) {
                  settingsNotifier.setEnableBeep(val);
                },
              ),
            ),
            const SizedBox(height: 10),

            // Selector del tipo de pitido
            if (settings.enableBeep) ...[
              _buildSettingTile(
                context,
                icon: Icons.music_note_outlined,
                title: "Tipo de pitido",
                trailing: DropdownButton<int>(
                  value: settings.selectedBeepSound,
                  dropdownColor: AppTheme.midnightGrey,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("Sonido 1 (Bit Bit)")),
                    DropdownMenuItem(value: 2, child: Text("Sonido 2 (Campana)")),
                    DropdownMenuItem(value: 3, child: Text("Sonido 3 (Click)")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      settingsNotifier.setSelectedBeepSound(val);
                      _playPreviewSound(val);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
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
            const SizedBox(height: 32),

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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.voltYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt, color: AppTheme.voltYellow, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
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
                          const Text(
                            "Versión 1.0.0 (MVP)",
                            style: TextStyle(fontSize: 11, color: Colors.white38),
                          ),
                        ],
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
                ],
              ),
            ),
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

void _playPreviewSound(int soundId) async {
  String url;
  switch (soundId) {
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
    final player = AudioPlayer();
    player.setVolume(1.0).catchError((e) {
      debugPrint("Preview player error: $e");
      return null;
    });
    await player.play(UrlSource(url));
    Future.delayed(const Duration(seconds: 2), () {
      try {
        player.dispose();
      } catch (_) {}
    });
  } catch (_) {
    _fallbackPreviewBeep(soundId);
  }
}

void _fallbackPreviewBeep(int soundId) {
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
    switch (soundId) {
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
      if (soundId == 2) {
        Process.run('speaker-test', ['-t', 'sine', '-f', '800', '-l', '3']).catchError((_) => ProcessResult(0,0,null,null));
      } else if (soundId == 3) {
        Process.run('speaker-test', ['-t', 'sine', '-f', '400', '-l', '3']).catchError((_) => ProcessResult(0,0,null,null));
      } else {
        Process.run('speaker-test', ['-t', 'sine', '-f', '1000', '-l', '3']).catchError((_) => ProcessResult(0,0,null,null));
      }
    } catch (_) {}
    SystemSound.play(SystemSoundType.alert);
  }
}



