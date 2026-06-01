import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
            const SizedBox(height: 32),

            // SECCIÓN 2: ACERCA DE LA APLICACIÓN
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
