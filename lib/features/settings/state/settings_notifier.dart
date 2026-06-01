import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';

class SettingsState {
  final String language; // 'es', 'en', 'pt'
  final String weightUnit; // 'kg', 'lbs'
  final String defaultFormula; // 'epley', 'brzycki'

  SettingsState({
    required this.language,
    required this.weightUnit,
    required this.defaultFormula,
  });

  SettingsState copyWith({
    String? language,
    String? weightUnit,
    String? defaultFormula,
  }) {
    return SettingsState(
      language: language ?? this.language,
      weightUnit: weightUnit ?? this.weightUnit,
      defaultFormula: defaultFormula ?? this.defaultFormula,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(language: 'es', weightUnit: 'kg', defaultFormula: 'epley')) {
    _loadSettings();
  }

  static const String _keyLang = 'settings_lang';
  static const String _keyUnit = 'settings_unit';
  static const String _keyFormula = 'settings_formula';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String lang = prefs.getString(_keyLang) ?? 'es';
    final String unit = prefs.getString(_keyUnit) ?? 'kg';
    final String formula = prefs.getString(_keyFormula) ?? 'epley';
    
    state = SettingsState(
      language: lang,
      weightUnit: unit,
      defaultFormula: formula,
    );
  }

  Future<void> setLanguage(String lang, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang);
    state = state.copyWith(language: lang);
    
    // Sincroniza con el localeProvider de localización
    ref.read(localeProvider.notifier).state = lang;
  }

  Future<void> setWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUnit, unit);
    state = state.copyWith(weightUnit: unit);
  }

  Future<void> setDefaultFormula(String formula) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFormula, formula);
    state = state.copyWith(defaultFormula: formula);
  }
}

// Proveedor global para leer y modificar la configuración
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
