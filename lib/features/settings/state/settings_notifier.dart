import 'dart:convert';
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
  final String selectedExerciseName; // active exercise
  final int selectedDayIndex; // selected day of routine
  final String aiMode; // 'local' or 'online'
  final String geminiApiKey;
  final String onlineProvider; // 'gemini' or 'huggingface'
  final String huggingFaceToken;
  final String profileImagePath;
  final bool profileSetupDone;

  final int minReps;
  final int maxReps;

  SettingsState({
    required this.language,
    required this.weightUnit,
    required this.defaultFormula,
    required this.minWeight,
    required this.maxWeight,
    required this.minReps,
    required this.maxReps,
    required this.userHeight,
    required this.userWeight,
    required this.userName,
    required this.userAge,
    required this.userGoal,
    required this.enableBeep,
    required this.selectedBeepSound,
    required this.restTimeBetweenExercises,
    required this.selectedRoutineId,
    required this.selectedExerciseName,
    required this.selectedDayIndex,
    required this.aiMode,
    required this.geminiApiKey,
    required this.onlineProvider,
    required this.huggingFaceToken,
    required this.profileImagePath,
    required this.profileSetupDone,
  });

  SettingsState copyWith({
    String? language,
    String? weightUnit,
    String? defaultFormula,
    double? minWeight,
    double? maxWeight,
    int? minReps,
    int? maxReps,
    double? userHeight,
    double? userWeight,
    String? userName,
    int? userAge,
    String? userGoal,
    bool? enableBeep,
    int? selectedBeepSound,
    int? restTimeBetweenExercises,
    String? selectedRoutineId,
    String? selectedExerciseName,
    int? selectedDayIndex,
    String? aiMode,
    String? geminiApiKey,
    String? onlineProvider,
    String? huggingFaceToken,
    String? profileImagePath,
    bool? profileSetupDone,
  }) {
    return SettingsState(
      language: language ?? this.language,
      weightUnit: weightUnit ?? this.weightUnit,
      defaultFormula: defaultFormula ?? this.defaultFormula,
      minWeight: minWeight ?? this.minWeight,
      maxWeight: maxWeight ?? this.maxWeight,
      minReps: minReps ?? this.minReps,
      maxReps: maxReps ?? this.maxReps,
      userHeight: userHeight ?? this.userHeight,
      userWeight: userWeight ?? this.userWeight,
      userName: userName ?? this.userName,
      userAge: userAge ?? this.userAge,
      userGoal: userGoal ?? this.userGoal,
      enableBeep: enableBeep ?? this.enableBeep,
      selectedBeepSound: selectedBeepSound ?? this.selectedBeepSound,
      restTimeBetweenExercises: restTimeBetweenExercises ?? this.restTimeBetweenExercises,
      selectedRoutineId: selectedRoutineId ?? this.selectedRoutineId,
      selectedExerciseName: selectedExerciseName ?? this.selectedExerciseName,
      selectedDayIndex: selectedDayIndex ?? this.selectedDayIndex,
      aiMode: aiMode ?? this.aiMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      onlineProvider: onlineProvider ?? this.onlineProvider,
      huggingFaceToken: huggingFaceToken ?? this.huggingFaceToken,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      profileSetupDone: profileSetupDone ?? this.profileSetupDone,
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
          minReps: 1,
          maxReps: 20,
          userHeight: 0.0,
          userWeight: 0.0,
          userName: '',
          userAge: 0,
          userGoal: '',
          enableBeep: true,
          selectedBeepSound: 1,
          restTimeBetweenExercises: 90,
          selectedRoutineId: '',
          selectedExerciseName: '',
          selectedDayIndex: 0,
          aiMode: 'online',
          geminiApiKey: _defaultApiKey,
          onlineProvider: 'gemini', // Default to gemini (Google key)
          huggingFaceToken: '',
          profileImagePath: '',
          profileSetupDone: false,
        )) {
    _loadSettings();
  }

  static const String _keyLang = 'settings_lang';
  static const String _keyUnit = 'settings_unit';
  static const String _keyFormula = 'settings_formula';
  static const String _keyMinWeight = 'settings_min_weight';
  static const String _keyMaxWeight = 'settings_max_weight';
  static const String _keyMinReps = 'settings_min_reps';
  static const String _keyMaxReps = 'settings_max_reps';
  static const String _keyUserHeight = 'settings_user_height';
  static const String _keyUserWeight = 'settings_user_weight';
  static const String _keyUserName = 'settings_user_name';
  static const String _keyUserAge = 'settings_user_age';
  static const String _keyUserGoal = 'settings_user_goal';
  static const String _keyEnableBeep = 'settings_enable_beep';
  static const String _keyBeepSound = 'settings_beep_sound';
  static const String _keyRestTime = 'settings_rest_time';
  static const String _keySelectedRoutine = 'settings_selected_routine';
  static const String _keyAiMode = 'settings_ai_mode';
  static const String _keyGeminiApiKey = 'settings_gemini_api_key_obf';
  static const String _keyOnlineProvider = 'settings_online_provider';
  static const String _keyHuggingFaceToken = 'settings_huggingface_token_obf';
  static const String _keyProfileSetupDone = 'settings_profile_setup_done';
  static const String _keyProfileImagePath = 'settings_profile_image_path';

  static String get _defaultApiKey {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    
    final List<int> encrypted = [42, 59, 9, 62, 35, 22, 52, 52, 8, 53, 45, 29, 2, 38, 57, 49, 57, 88, 71, 34, 69, 28, 62, 59, 47, 30, 56, 19, 5, 6, 38, 6, 66, 39, 45, 14, 94, 48, 4];
    final List<int> key = [107, 114, 115, 95, 112, 111, 119, 101, 114, 109, 97, 120]; // 'krs_powermax'
    final List<int> result = [];
    for (int i = 0; i < encrypted.length; i++) {
      result.add(encrypted[i] ^ key[i % key.length]);
    }
    return String.fromCharCodes(result);
  }

  static String _obfuscateXor(String text) {
    final List<int> textBytes = text.codeUnits;
    final List<int> keyBytes = [107, 114, 115, 95, 112, 111, 119, 101, 114, 109, 97, 120];
    final List<int> result = [];
    for (int i = 0; i < textBytes.length; i++) {
      result.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    return base64Encode(result);
  }

  static String _deobfuscateXor(String base64Text) {
    if (base64Text.isEmpty) return '';
    try {
      final List<int> encryptedBytes = base64Decode(base64Text);
      final List<int> keyBytes = [107, 114, 115, 95, 112, 111, 119, 101, 114, 109, 97, 120];
      final List<int> result = [];
      for (int i = 0; i < encryptedBytes.length; i++) {
        result.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      return String.fromCharCodes(result);
    } catch (_) {
      return '';
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String lang = prefs.getString(_keyLang) ?? 'es';
    final String unit = prefs.getString(_keyUnit) ?? 'kg';
    final String formula = prefs.getString(_keyFormula) ?? 'epley';
    final double minW = prefs.getDouble(_keyMinWeight) ?? 0.0;
    final double maxW = prefs.getDouble(_keyMaxWeight) ?? 300.0;
    final int minReps = prefs.getInt(_keyMinReps) ?? 1;
    final int maxReps = prefs.getInt(_keyMaxReps) ?? 20;
    final double userH = prefs.getDouble(_keyUserHeight) ?? 0.0;
    final double userW = prefs.getDouble(_keyUserWeight) ?? 0.0;
    final String userN = prefs.getString(_keyUserName) ?? '';
    final int userA = prefs.getInt(_keyUserAge) ?? 0;
    final String userG = prefs.getString(_keyUserGoal) ?? '';
    final bool enableB = prefs.getBool(_keyEnableBeep) ?? true;
    final int beepS = prefs.getInt(_keyBeepSound) ?? 1;
    final int restT = prefs.getInt(_keyRestTime) ?? 90;
    String selRoutine = prefs.getString(_keySelectedRoutine) ?? '';
    if (selRoutine == 'default_arnold') {
      selRoutine = 'default_arnold_split';
    }
    final String profileImg = prefs.getString(_keyProfileImagePath) ?? '';
    final String aiMode = 'online';
    final String geminiApiKeyObf = prefs.getString(_keyGeminiApiKey) ?? '';
    String geminiApiKey = geminiApiKeyObf.isNotEmpty 
        ? _deobfuscateXor(geminiApiKeyObf) 
        : _defaultApiKey;

    // Si la clave guardada en el dispositivo es la antigua clave restringida (empieza con AQ.),
    // la eliminamos de SharedPreferences para que use la nueva clave predeterminada funcional
    if (geminiApiKey.startsWith('AQ.')) {
      await prefs.remove(_keyGeminiApiKey);
      geminiApiKey = _defaultApiKey;
    }
    final String onlineProv = prefs.getString(_keyOnlineProvider) ?? 'gemini';
    final String hfTokenObf = prefs.getString(_keyHuggingFaceToken) ?? '';
    final String hfToken = hfTokenObf.isNotEmpty ? _deobfuscateXor(hfTokenObf) : '';
    final bool profileDone = prefs.getBool(_keyProfileSetupDone) ?? false;
    final String selEx = prefs.getString('settings_selected_exercise') ?? '';
    final int selDayIdx = prefs.getInt('settings_selected_day_idx') ?? 0;
    
    state = SettingsState(
      language: lang,
      weightUnit: unit,
      defaultFormula: formula,
      minWeight: minW,
      maxWeight: maxW,
      minReps: minReps,
      maxReps: maxReps,
      userHeight: userH,
      userWeight: userW,
      userName: userN,
      userAge: userA,
      userGoal: userG,
      enableBeep: enableB,
      selectedBeepSound: beepS,
      restTimeBetweenExercises: restT,
      selectedRoutineId: selRoutine,
      selectedExerciseName: selEx,
      selectedDayIndex: selDayIdx,
      aiMode: aiMode,
      geminiApiKey: geminiApiKey,
      onlineProvider: onlineProv,
      huggingFaceToken: hfToken,
      profileImagePath: profileImg,
      profileSetupDone: profileDone,
    );
  }

  Future<void> setLanguage(String lang, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang);
    state = state.copyWith(language: lang);
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

  Future<void> setMinReps(int minReps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinReps, minReps);
    state = state.copyWith(minReps: minReps);
  }

  Future<void> setMaxReps(int maxReps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxReps, maxReps);
    state = state.copyWith(maxReps: maxReps);
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

  Future<void> setProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileImagePath, path.trim());
    state = state.copyWith(profileImagePath: path.trim());
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
    String cleanId = selectedRoutineId.trim();
    if (cleanId == 'default_arnold') {
      cleanId = 'default_arnold_split';
    }
    await prefs.setString(_keySelectedRoutine, cleanId);
    state = state.copyWith(selectedRoutineId: cleanId);
  }

  Future<void> setAiMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiMode, 'online');
    state = state.copyWith(aiMode: 'online');
  }

  Future<void> setGeminiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      await prefs.remove(_keyGeminiApiKey);
      state = state.copyWith(geminiApiKey: _defaultApiKey);
    } else {
      await prefs.setString(_keyGeminiApiKey, _obfuscateXor(cleanKey));
      state = state.copyWith(geminiApiKey: cleanKey);
    }
  }

  Future<void> setOnlineProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOnlineProvider, provider);
    state = state.copyWith(onlineProvider: provider);
  }

  Future<void> setHuggingFaceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      await prefs.remove(_keyHuggingFaceToken);
      state = state.copyWith(huggingFaceToken: '');
    } else {
      await prefs.setString(_keyHuggingFaceToken, _obfuscateXor(cleanToken));
      state = state.copyWith(huggingFaceToken: cleanToken);
    }
  }

  Future<void> setProfileSetupDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProfileSetupDone, value);
    state = state.copyWith(profileSetupDone: value);
  }

  Future<void> setSelectedExerciseName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_selected_exercise', name);
    state = state.copyWith(selectedExerciseName: name);
  }

  Future<void> setSelectedDayIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_selected_day_idx', index);
    state = state.copyWith(selectedDayIndex: index);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
