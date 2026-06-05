import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_localizations.dart';

class SettingsState {
  final String language; // 'es', 'en', 'pt'
  final String weightUnit; // 'kg', 'lbs'
  final String defaultFormula; // 'epley', 'brzycki'
  final double minWeight;
  final double maxWeight;
  final double userHeight; // in cm
  final double userWeight; // in weightUnit
  final String userName;
  final int userAge;
  final String userGoal;
  final bool enableBeep;
  final int selectedBeepSound; // 1, 2, 3
  final int restTimeBetweenExercises; // in seconds
  final String selectedRoutineId; // new: selected routine of the day

  SettingsState({
    required this.language,
    required this.weightUnit,
    required this.defaultFormula,
    required this.minWeight,
    required this.maxWeight,
    required this.userHeight,
    required this.userWeight,
    required this.userName,
    required this.userAge,
    required this.userGoal,
    required this.enableBeep,
    required this.selectedBeepSound,
    required this.restTimeBetweenExercises,
    required this.selectedRoutineId,
  });

  SettingsState copyWith({
    String? language,
    String? weightUnit,
    String? defaultFormula,
    double? minWeight,
    double? maxWeight,
    double? userHeight,
    double? userWeight,
    String? userName,
    int? userAge,
    String? userGoal,
    bool? enableBeep,
    int? selectedBeepSound,
    int? restTimeBetweenExercises,
    String? selectedRoutineId,
  }) {
    return SettingsState(
      language: language ?? this.language,
      weightUnit: weightUnit ?? this.weightUnit,
      defaultFormula: defaultFormula ?? this.defaultFormula,
      minWeight: minWeight ?? this.minWeight,
      maxWeight: maxWeight ?? this.maxWeight,
      userHeight: userHeight ?? this.userHeight,
      userWeight: userWeight ?? this.userWeight,
      userName: userName ?? this.userName,
      userAge: userAge ?? this.userAge,
      userGoal: userGoal ?? this.userGoal,
      enableBeep: enableBeep ?? this.enableBeep,
      selectedBeepSound: selectedBeepSound ?? this.selectedBeepSound,
      restTimeBetweenExercises: restTimeBetweenExercises ?? this.restTimeBetweenExercises,
      selectedRoutineId: selectedRoutineId ?? this.selectedRoutineId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(
          language: 'es',
          weightUnit: 'kg',
          defaultFormula: 'epley',
          minWeight: 0.0,
          maxWeight: 300.0,
          userHeight: 0.0,
          userWeight: 0.0,
          userName: '',
          userAge: 0,
          userGoal: '',
          enableBeep: true,
          selectedBeepSound: 1,
          restTimeBetweenExercises: 90,
          selectedRoutineId: '',
        )) {
    _loadSettings();
  }

  static const String _keyLang = 'settings_lang';
  static const String _keyUnit = 'settings_unit';
  static const String _keyFormula = 'settings_formula';
  static const String _keyMinWeight = 'settings_min_weight';
  static const String _keyMaxWeight = 'settings_max_weight';
  static const String _keyUserHeight = 'settings_user_height';
  static const String _keyUserWeight = 'settings_user_weight';
  static const String _keyUserName = 'settings_user_name';
  static const String _keyUserAge = 'settings_user_age';
  static const String _keyUserGoal = 'settings_user_goal';
  static const String _keyEnableBeep = 'settings_enable_beep';
  static const String _keyBeepSound = 'settings_beep_sound';
  static const String _keyRestTime = 'settings_rest_time';
  static const String _keySelectedRoutine = 'settings_selected_routine';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String lang = prefs.getString(_keyLang) ?? 'es';
    final String unit = prefs.getString(_keyUnit) ?? 'kg';
    final String formula = prefs.getString(_keyFormula) ?? 'epley';
    final double minW = prefs.getDouble(_keyMinWeight) ?? 0.0;
    final double maxW = prefs.getDouble(_keyMaxWeight) ?? 300.0;
    final double userH = prefs.getDouble(_keyUserHeight) ?? 0.0;
    final double userW = prefs.getDouble(_keyUserWeight) ?? 0.0;
    final String userN = prefs.getString(_keyUserName) ?? '';
    final int userA = prefs.getInt(_keyUserAge) ?? 0;
    final String userG = prefs.getString(_keyUserGoal) ?? '';
    final bool enableB = prefs.getBool(_keyEnableBeep) ?? true;
    final int beepS = prefs.getInt(_keyBeepSound) ?? 1;
    final int restT = prefs.getInt(_keyRestTime) ?? 90;
    final String selRoutine = prefs.getString(_keySelectedRoutine) ?? '';
    
    state = SettingsState(
      language: lang,
      weightUnit: unit,
      defaultFormula: formula,
      minWeight: minW,
      maxWeight: maxW,
      userHeight: userH,
      userWeight: userW,
      userName: userN,
      userAge: userA,
      userGoal: userG,
      enableBeep: enableB,
      selectedBeepSound: beepS,
      restTimeBetweenExercises: restT,
      selectedRoutineId: selRoutine,
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

  Future<void> setUserHeight(double userHeight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyUserHeight, userHeight);
    state = state.copyWith(userHeight: userHeight);
  }

  Future<void> setUserWeight(double userWeight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyUserWeight, userWeight);
    state = state.copyWith(userWeight: userWeight);
  }

  Future<void> setUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, userName.trim());
    state = state.copyWith(userName: userName.trim());
  }

  Future<void> setUserAge(int userAge) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserAge, userAge);
    state = state.copyWith(userAge: userAge);
  }

  Future<void> setUserGoal(String userGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserGoal, userGoal.trim());
    state = state.copyWith(userGoal: userGoal.trim());
  }

  Future<void> setEnableBeep(bool enableBeep) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableBeep, enableBeep);
    state = state.copyWith(enableBeep: enableBeep);
  }

  Future<void> setSelectedBeepSound(int selectedBeepSound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBeepSound, selectedBeepSound);
    state = state.copyWith(selectedBeepSound: selectedBeepSound);
  }

  Future<void> setRestTime(int restTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRestTime, restTime);
    state = state.copyWith(restTimeBetweenExercises: restTime);
  }

  Future<void> setSelectedRoutineId(String selectedRoutineId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedRoutine, selectedRoutineId.trim());
    state = state.copyWith(selectedRoutineId: selectedRoutineId.trim());
  }
}

// Proveedor global para leer y modificar la configuración
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
