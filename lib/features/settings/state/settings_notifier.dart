import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';

class SettingsState {
  final String language; // 'es', 'en', 'pt'
  final String weightUnit; // 'kg', 'lbs'
  final String defaultFormula; // 'epley', 'brzycki'
  final double minWeight;
  final double maxWeight;

  SettingsState({
    required this.language,
    required this.weightUnit,
    required this.defaultFormula,
    required this.minWeight,
    required this.maxWeight,
  });

  SettingsState copyWith({
    String? language,
    String? weightUnit,
    String? defaultFormula,
    double? minWeight,
    double? maxWeight,
  }) {
    return SettingsState(
      language: language ?? this.language,
      weightUnit: weightUnit ?? this.weightUnit,
      defaultFormula: defaultFormula ?? this.defaultFormula,
      minWeight: minWeight ?? this.minWeight,
      maxWeight: maxWeight ?? this.maxWeight,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(language: 'es', weightUnit: 'kg', defaultFormula: 'epley', minWeight: 0.0, maxWeight: 300.0)) {
    _loadSettings();
  }

  static const String _keyLang = 'settings_lang';
  static const String _keyUnit = 'settings_unit';
  static const String _keyFormula = 'settings_formula';
  static const String _keyMinWeight = 'settings_min_weight';
  static const String _keyMaxWeight = 'settings_max_weight';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String lang = prefs.getString(_keyLang) ?? 'es';
    final String unit = prefs.getString(_keyUnit) ?? 'kg';
    final String formula = prefs.getString(_keyFormula) ?? 'epley';
    final double minW = prefs.getDouble(_keyMinWeight) ?? 0.0;
    final double maxW = prefs.getDouble(_keyMaxWeight) ?? 300.0;
    
    state = SettingsState(
      language: lang,
      weightUnit: unit,
      defaultFormula: formula,
      minWeight: minW,
      maxWeight: maxW,
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

  Future<void> setMinWeight(double minWeight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMinWeight, minWeight);
    state = state.copyWith(minWeight: minWeight);
  }

  Future<void> setMaxWeight(double maxWeight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMaxWeight, maxWeight);
    state = state.copyWith(maxWeight: maxWeight);
  }
}

// Proveedor global para leer y modificar la configuración
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
