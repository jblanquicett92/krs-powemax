import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../calculator/state/calculator_notifier.dart';
import '../../settings/state/settings_notifier.dart';
import '../../history/state/history_notifier.dart';
import '../../history/data/workout_record.dart';
import 'package:system_info_plus/system_info_plus.dart';


class ChatMessage {
  final String text;
  final bool isUser;
  final bool isThinking;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isThinking = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'isThinking': isThinking,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      isThinking: json['isThinking'] as bool? ?? false,
    );
  }
}

class CoachState {
  final bool isModelInstalled;
  final bool isDownloading;
  final int downloadProgress;
  final List<ChatMessage> messages;
  final bool isThinking;
  final String selectedCoach; // 'cristian' (hipertrofia), 'ana' (definición/nutrición), 'igor' (fuerza)
  final String? error;
  final bool isOnboarded;
  final String? experienceLevel;
  final String? trainingFrequency;
  final Map<String, List<ChatMessage>> conversations;
  final String activeExercise;
  final bool isUsingLocalAI;
  final bool isDeviceCompatible;
  final int deviceRamMb;

  CoachState({
    required this.isModelInstalled,
    required this.isDownloading,
    required this.downloadProgress,
    required this.messages,
    required this.isThinking,
    required this.selectedCoach,
    this.error,
    required this.isOnboarded,
    this.experienceLevel,
    this.trainingFrequency,
    required this.conversations,
    required this.activeExercise,
    required this.isUsingLocalAI,
    required this.isDeviceCompatible,
    required this.deviceRamMb,
  });

  CoachState copyWith({
    bool? isModelInstalled,
    bool? isDownloading,
    int? downloadProgress,
    List<ChatMessage>? messages,
    bool? isThinking,
    String? selectedCoach,
    String? error,
    bool? isOnboarded,
    String? experienceLevel,
    String? trainingFrequency,
    Map<String, List<ChatMessage>>? conversations,
    String? activeExercise,
    bool? isUsingLocalAI,
    bool? isDeviceCompatible,
    int? deviceRamMb,
  }) {
    return CoachState(
      isModelInstalled: isModelInstalled ?? this.isModelInstalled,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      selectedCoach: selectedCoach ?? this.selectedCoach,
      error: error,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      trainingFrequency: trainingFrequency ?? this.trainingFrequency,
      conversations: conversations ?? this.conversations,
      activeExercise: activeExercise ?? this.activeExercise,
      isUsingLocalAI: isUsingLocalAI ?? this.isUsingLocalAI,
      isDeviceCompatible: isDeviceCompatible ?? this.isDeviceCompatible,
      deviceRamMb: deviceRamMb ?? this.deviceRamMb,
    );
  }
}

class CoachNotifier extends StateNotifier<CoachState> {
  final Ref ref;
  static const String _modelFileName = 'Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm';

  static const String _keyIsOnboarded = 'coach_is_onboarded';
  static const String _keySelectedCoach = 'coach_selected_coach';
  static const String _keyExperienceLevel = 'coach_experience_level';
  static const String _keyTrainingFrequency = 'coach_training_frequency';
  static const String _keyConversations = 'coach_conversations';

  int _sessionSeq = 0; // Concurrency sequence number to prevent race conditions

  CoachNotifier(this.ref)
      : super(CoachState(
          isModelInstalled: false,
          isDownloading: false,
          downloadProgress: 0,
          messages: [],
          isThinking: false,
          selectedCoach: 'cristian', // Cristian por defecto
          isOnboarded: false,
          conversations: {},
          activeExercise: 'General',
          isUsingLocalAI: false,
          isDeviceCompatible: true,
          deviceRamMb: 0,
        )) {
    _loadOnboardingAndModelStatus();
  }

  Future<void> _loadOnboardingAndModelStatus() async {
    final mySeq = ++_sessionSeq;
    try {
      int deviceRamMb = 0;
      bool isCompatible = true;
      try {
        if (Platform.isLinux) {
          final file = File('/proc/meminfo');
          if (await file.exists()) {
            final lines = await file.readAsLines();
            final memTotalLine = lines.firstWhere((l) => l.startsWith('MemTotal:'), orElse: () => '');
            if (memTotalLine.isNotEmpty) {
              final match = RegExp(r'\d+').firstMatch(memTotalLine);
              if (match != null) {
                final kb = int.parse(match.group(0)!);
                deviceRamMb = kb ~/ 1024;
                if (deviceRamMb < 3500) {
                  isCompatible = false;
                }
              }
            }
          }
        } else {
          final ram = await SystemInfoPlus.physicalMemory;
          if (ram != null) {
            deviceRamMb = ram;
            if (deviceRamMb < 3500) {
              isCompatible = false;
            }
          }
        }
      } catch (e) {
        print("[CoachNotifier] Advertencia al verificar la memoria RAM: $e");
      }

      final prefs = await SharedPreferences.getInstance();
      if (mySeq != _sessionSeq) return;

      final bool isOnboarded = prefs.getBool(_keyIsOnboarded) ?? false;
      final String selectedCoach = prefs.getString(_keySelectedCoach) ?? 'cristian';
      final String? exp = prefs.getString(_keyExperienceLevel);
      final String? freq = prefs.getString(_keyTrainingFrequency);

      // Cargar conversaciones guardadas
      final String? convJsonStr = prefs.getString(_keyConversations);
      Map<String, List<ChatMessage>> loadedConversations = {};
      if (convJsonStr != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(convJsonStr) as Map<String, dynamic>;
          decoded.forEach((key, val) {
            final List<dynamic> list = val as List<dynamic>;
            loadedConversations[key] = list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
          });
        } catch (e) {
          loadedConversations = {};
        }
      }

      state = state.copyWith(
        isOnboarded: isOnboarded,
        selectedCoach: selectedCoach,
        experienceLevel: exp,
        trainingFrequency: freq,
        conversations: loadedConversations,
        activeExercise: 'General',
        messages: loadedConversations['General'] ?? [],
        isDeviceCompatible: isCompatible,
        deviceRamMb: deviceRamMb,
      );

      state = state.copyWith(isModelInstalled: true);
      
      if (isOnboarded) {
        if (state.messages.isEmpty) {
          await _initializeChatSession();
        }
      }
      state = state.copyWith(isUsingLocalAI: false);
    } catch (e) {
      state = state.copyWith(isModelInstalled: false, isUsingLocalAI: false);
    }
  }

  // Sincroniza y guarda conversaciones a SharedPreferences
  Future<void> _saveConversationsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final updatedConversations = Map<String, List<ChatMessage>>.from(state.conversations);
    updatedConversations[state.activeExercise] = state.messages;
    
    final mapJson = updatedConversations.map((key, val) => MapEntry(key, val.map((msg) => msg.toJson()).toList()));
    await prefs.setString(_keyConversations, jsonEncode(mapJson));
  }

  // Cambia el hilo de conversación basado en el ejercicio activo
  Future<void> selectExercise(String exercise) async {
    final mySeq = ++_sessionSeq;
    // Primero guardamos los mensajes actuales del ejercicio activo actual
    final updatedConversations = Map<String, List<ChatMessage>>.from(state.conversations);
    updatedConversations[state.activeExercise] = state.messages;

    final targetMessages = updatedConversations[exercise] ?? [];
    
    state = state.copyWith(
      activeExercise: exercise,
      conversations: updatedConversations,
      messages: targetMessages,
    );

    if (targetMessages.isEmpty) {
      await _initializeChatSession();
    } else {
      await _saveConversationsToPrefs();
    }
    state = state.copyWith(isUsingLocalAI: false);
  }

  // Obtiene las últimas 3 marcas de un ejercicio específico
  List<WorkoutRecord> _getLast3Records(String exerciseName) {
    final allRecords = ref.read(historyProvider);
    final filtered = allRecords
        .where((r) => r.exerciseName.toLowerCase() == exerciseName.toLowerCase())
        .toList();
    filtered.sort((a, b) => b.date.compareTo(a.date)); // Recientes primero
    return filtered.take(3).toList();
  }

  String get systemPrompt => _buildSystemPrompt();

  String _buildSystemPrompt() {
    final calcState = ref.read(calculatorProvider);
    final settings = ref.read(settingsProvider);
    final unit = settings.weightUnit;
    final r1rm = calcState.calculated1RM;

    String coachInstruction = "";
    final isOnline = settings.aiMode == 'online';
    final String concisenessConstraint = isOnline 
        ? " Da respuestas detalladas, fluidas, estructuradas y completas con contexto explicativo, tips de técnica, motivación y nutrición sin límite de palabras."
        : " Habla de forma EXTREMADAMENTE breve, concisa y directa al grano para ahorrar tokens y procesamiento (máximo 2 oraciones o 40 palabras en total, sin saludos redundantes ni introducciones largas).";
    
    if (state.selectedCoach == 'cristian') {
      coachInstruction = "Eres Cristian, un motivador entrenador personal experto en hipertrofia y culturismo. Enfatiza series al RPE 8-10, control excéntrico y tempo lento.$concisenessConstraint";
    } else if (state.selectedCoach == 'ana') {
      coachInstruction = "Eres Ana, una apasionada coach de definición, pérdida de grasa y nutrición deportiva. Enfatiza el déficit calórico inteligente, la ingesta proteica y el cardio metabólico.$concisenessConstraint";
    } else {
      coachInstruction = "Eres Igor, un serio y directo entrenador soviético de powerlifting y fuerza máxima. Enfatiza progresión de cargas, velocidad de barra y bajas repeticiones.$concisenessConstraint";
    }

    double? bmi;
    if (settings.userHeight > 0 && settings.userWeight > 0) {
      double weightKg = settings.userWeight;
      if (settings.weightUnit == 'lbs') {
        weightKg = settings.userWeight * 0.45359237;
      }
      final heightM = settings.userHeight / 100.0;
      bmi = weightKg / (heightM * heightM);
    }

    String profileInfo = "";
    final hasName = settings.userName.trim().isNotEmpty;
    final hasAge = settings.userAge > 0;
    final hasHeight = settings.userHeight > 0;
    final hasWeight = settings.userWeight > 0;
    final hasGoal = settings.userGoal.trim().isNotEmpty;

    if (hasName || hasAge || hasHeight || hasWeight || hasGoal) {
      profileInfo += " Datos de perfil del usuario:";
      if (hasName) profileInfo += " Nombre: ${settings.userName}.";
      if (hasAge) profileInfo += " Edad: ${settings.userAge} años.";
      if (hasHeight) profileInfo += " Altura: ${settings.userHeight} cm.";
      if (hasWeight) profileInfo += " Peso: ${settings.userWeight} ${settings.weightUnit}.";
      if (bmi != null) profileInfo += " IMC (Índice de Masa Corporal): ${bmi.toStringAsFixed(1)}.";
      if (hasGoal) profileInfo += " Objetivo del usuario: ${settings.userGoal}.";
      profileInfo += " Usa estos datos para personalizar tu asesoría y consejos.";
    } else {
      profileInfo += " El usuario no ha completado sus datos de perfil (nombre, edad, peso, altura u objetivo) en la pestaña de perfil/ajustes. Sugiérele o solicítale sutilmente y con tacto, cuando sea natural en la conversación, que complete su perfil para poder calcular su IMC (Índice de Masa Corporal) y personalizar mucho mejor sus entrenamientos.";
    }

    String systemPrompt = coachInstruction + profileInfo;
    if (state.activeExercise != 'General') {
      final last3 = _getLast3Records(state.activeExercise);
      String historyContext = "";
      if (last3.isNotEmpty) {
        historyContext = " Ejercicio activo: '${state.activeExercise}'. Últimos levantamientos del usuario:\n" +
            last3.map((r) => "- ${r.date.toIso8601String().substring(0, 10)}: ${r.weight} ${r.unit} x ${r.reps} reps (1RM: ${r.oneRepMax} ${r.unit})").join("\n") +
            "\nUsa estas marcas reales para sugerir progresión de cargas.";
      } else {
        historyContext = " Ejercicio activo: '${state.activeExercise}'. El usuario aún no tiene marcas. Aconséjale registrar una en la calculadora.";
      }
      systemPrompt += historyContext;
    } else {
      systemPrompt += " 1RM general del usuario: $r1rm $unit (basado en ${calcState.weight} ${unit} x ${calcState.reps} reps).";
    }

    return systemPrompt;
  }



  // Completa el formulario de datos, propone el coach idóneo y lo guarda de forma persistente
  Future<void> completeOnboarding({
    required String objective, // 'hipertrofia' (Cristian), 'definicion' (Ana), 'fuerza' (Igor)
    required String experienceLevel,
    required String trainingFrequency,
  }) async {
    final mySeq = ++_sessionSeq;
    String coach = 'cristian';
    if (objective == 'definicion') {
      coach = 'ana';
    } else if (objective == 'fuerza') {
      coach = 'igor';
    }

    final prefs = await SharedPreferences.getInstance();
    if (mySeq != _sessionSeq) return;
    await prefs.setBool(_keyIsOnboarded, true);
    await prefs.setString(_keySelectedCoach, coach);
    await prefs.setString(_keyExperienceLevel, experienceLevel);
    await prefs.setString(_keyTrainingFrequency, trainingFrequency);

    state = state.copyWith(
      isOnboarded: true,
      selectedCoach: coach,
      experienceLevel: experienceLevel,
      trainingFrequency: trainingFrequency,
      conversations: {},
      activeExercise: 'General',
      messages: [],
    );

    if (state.isModelInstalled) {
      _initializeChatSession();
    }
  }

  // Permite al usuario resetear su coach asignado para repetir el test
  Future<void> resetOnboarding() async {
    final mySeq = ++_sessionSeq;
    final prefs = await SharedPreferences.getInstance();
    if (mySeq != _sessionSeq) return;
    await prefs.remove(_keyIsOnboarded);
    await prefs.remove(_keySelectedCoach);
    await prefs.remove(_keyExperienceLevel);
    await prefs.remove(_keyTrainingFrequency);
    await prefs.remove(_keyConversations);

    state = state.copyWith(
      isOnboarded: false,
      selectedCoach: 'cristian',
      experienceLevel: null,
      trainingFrequency: null,
      messages: [],
      conversations: {},
      activeExercise: 'General',
    );
  }

  // Cambia de entrenador e inicializa una nueva sesión de chat (Obsoleto en flujo de 1 solo coach, pero conservado para compatibilidad)
  void selectCoach(String coach) {
    if (state.selectedCoach == coach && state.messages.isNotEmpty) return;
    state = state.copyWith(selectedCoach: coach);
    _initializeChatSession();
  }

  // Descarga e instala el modelo LLM local desde HuggingFace (Mockeado)
  Future<void> downloadModel() async {
    final mySeq = ++_sessionSeq;
    state = state.copyWith(isDownloading: true, downloadProgress: 0, error: null);

    int progress = 0;
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mySeq != _sessionSeq) {
        timer.cancel();
        return;
      }
      progress += 10;
      if (progress <= 100) {
        state = state.copyWith(downloadProgress: progress);
      } else {
        timer.cancel();
        state = state.copyWith(
          isDownloading: false,
          isModelInstalled: true,
          downloadProgress: 100,
        );
        _initializeChatSession();
      }
    });
  }

  // Inicializa el chat con el mensaje de bienvenida y personalidad del coach seleccionado
  Future<void> _initializeChatSession() async {
    final mySeq = ++_sessionSeq;
    final calcState = ref.read(calculatorProvider);
    final unit = ref.read(settingsProvider).weightUnit;
    final r1rm = calcState.calculated1RM;
    
    String welcomeText = "";
    if (state.activeExercise == 'General') {
      if (state.selectedCoach == 'cristian') {
        welcomeText = "Hola, soy Cristian. ¿Te diseño una rutina de hipertrofia o resolvemos dudas de técnica hoy?";
      } else if (state.selectedCoach == 'ana') {
        welcomeText = "Hola, soy Ana. ¿Qué dudas tienes hoy sobre tu nutrición, déficit o cardio?";
      } else {
        welcomeText = "Saludos, soy Igor. ¿Qué objetivos de fuerza o dudas de entrenamiento quieres consultar hoy?";
      }
    } else {
      // Diálogo de ejercicio específico con últimas marcas integradas
      final last3 = _getLast3Records(state.activeExercise);
      String recordsSummary = "";
      if (last3.isNotEmpty) {
        recordsSummary = "\n\nÚltimas marcas en ${state.activeExercise}:\n" +
            last3.map((r) {
              final dateStr = "${r.date.day}/${r.date.month}/${r.date.year}";
              return "• $dateStr: ${r.weight} ${r.unit} x ${r.reps} reps (1RM: ${r.oneRepMax} ${r.unit})";
            }).join("\n");
      } else {
        recordsSummary = "\n\nAún no tienes marcas registradas para ${state.activeExercise}.";
      }

      if (state.selectedCoach == 'cristian') {
        welcomeText = "Hola, soy Cristian. Analicemos tu rendimiento en **${state.activeExercise}**.$recordsSummary\n\n¿Quieres consejos de volumen o técnica para este ejercicio?";
      } else if (state.selectedCoach == 'ana') {
        welcomeText = "Hola, soy Ana. Analicemos tu rendimiento en **${state.activeExercise}**.$recordsSummary\n\n¿Tienes dudas de entrenamiento o dieta para definición?";
      } else {
        welcomeText = "Saludos, soy Igor. Analicemos tus marcas en **${state.activeExercise}**.$recordsSummary\n\n¿Planificamos tu progresión de cargas?";
      }
    }

    state = state.copyWith(
      messages: [
        ChatMessage(
          text: welcomeText,
          isUser: false,
        )
      ],
    );

    // Guardar la conversación recién inicializada
    await _saveConversationsToPrefs();
    state = state.copyWith(isUsingLocalAI: false);
  }

  // Envía un mensaje al entrenador de IA
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    final updatedMessages = [...state.messages, userMsg];
    
    state = state.copyWith(
      messages: updatedMessages,
      isThinking: true,
    );

    // Guardar inmediatamente el mensaje del usuario
    await _saveConversationsToPrefs();

    // Imprimir INPUT de interacción con la IA
    print("==================== IA INPUT PROMPT ====================");
    print("Active Exercise: ${state.activeExercise}");
    print("Coach: ${state.selectedCoach}");
    print("Prompt: $text");
    print("=========================================================");

    final settings = ref.read(settingsProvider);
    final systemPrompt = _buildSystemPrompt();

    if (settings.aiMode == 'online') {
      final isGeminiKeyRestricted = settings.geminiApiKey.trim().startsWith('AQ.');
      final activeProvider = isGeminiKeyRestricted ? 'huggingface' : settings.onlineProvider;

      if (activeProvider == 'gemini') {
        if (settings.geminiApiKey.isEmpty) {
          final errorMsg = ChatMessage(
            text: "Configuración incompleta: Por favor, ve a la pantalla de Ajustes e ingresa tu API Key de Gemini para poder chatear con tu entrenador online de forma gratuita.",
            isUser: false,
          );
          state = state.copyWith(
            messages: [...state.messages, errorMsg],
            isThinking: false,
          );
          await _saveConversationsToPrefs();
          return;
        }

        try {
          final responseText = await _callGeminiApi(
            systemPrompt,
            state.messages,
            settings.geminiApiKey,
          );

          print("==================== IA OUTPUT RESPONSE (GEMINI) ====================");
          print("Response: $responseText");
          print("=====================================================================");

          state = state.copyWith(
            messages: [
              ...state.messages,
              ChatMessage(text: responseText, isUser: false),
            ],
            isThinking: false,
            isUsingLocalAI: false,
          );
          await _saveConversationsToPrefs();
        } catch (e) {
          print("==================== ERROR EN GEMINI API ====================");
          print("Error: $e");
          print("=============================================================");
          final errorMsg = ChatMessage(
            text: "Error al llamar a la API de Gemini: $e",
            isUser: false,
          );
          state = state.copyWith(
            messages: [...state.messages, errorMsg],
            isThinking: false,
          );
          await _saveConversationsToPrefs();
        }
      } else {
        // Hugging Face API Mode
        try {
          final responseText = await _callHuggingFaceApi(
            systemPrompt,
            state.messages,
            settings.huggingFaceToken,
          );

          print("==================== IA OUTPUT RESPONSE (HUGGINGFACE) ====================");
          print("Response: $responseText");
          print("==========================================================================");

          state = state.copyWith(
            messages: [
              ...state.messages,
              ChatMessage(text: responseText, isUser: false),
            ],
            isThinking: false,
            isUsingLocalAI: false,
          );
          await _saveConversationsToPrefs();
        } catch (e) {
          print("==================== ERROR EN HUGGING FACE API ====================");
          print("Error: $e");
          print("====================================================================");
          final errorMsg = ChatMessage(
            text: "Error al llamar a la API de Hugging Face: $e",
            isUser: false,
          );
          state = state.copyWith(
            messages: [...state.messages, errorMsg],
            isThinking: false,
          );
          await _saveConversationsToPrefs();
        }
      }
      return;
    }

    _fallbackResponse(text);
  }

  // Genera respuestas simuladas inteligentes basadas en el 1RM actual y la personalidad del coach
  void _fallbackResponse(String userQuery) {
    final calcState = ref.read(calculatorProvider);
    final unit = ref.read(settingsProvider).weightUnit;
    
    double active1RM = calcState.calculated1RM;
    if (state.activeExercise != 'General') {
      final last3 = _getLast3Records(state.activeExercise);
      if (last3.isNotEmpty) {
        active1RM = last3.first.oneRepMax;
      }
    }
    
    String reply = "";
    final queryLower = userQuery.trim().toLowerCase();

    // Detección de intenciones conversacionales básicas para la simulación
    // Limpiamos signos de puntuación comunes para que coincida mejor (ej. "si, colaborame" -> "si colaborame")
    final cleanQuery = queryLower.replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()?¿¡!]'), '').trim();

    final bool isYes = cleanQuery == 'si' || 
                       cleanQuery.startsWith('si ') ||
                       cleanQuery == 's' ||
                       cleanQuery.startsWith('s ') ||
                       cleanQuery.contains('por favor') ||
                       cleanQuery.contains('porfavor') ||
                       cleanQuery.contains('claro') ||
                       cleanQuery.contains('dale') ||
                       cleanQuery.contains('bueno') ||
                       cleanQuery.contains('colabora') ||
                       cleanQuery.contains('ayuda') ||
                       cleanQuery.contains('rutina') ||
                       cleanQuery.contains('entrenar') ||
                       cleanQuery.contains('ejercicios');

    final bool isThanks = cleanQuery.contains('gracias') || 
                          cleanQuery.contains('grx') || 
                          cleanQuery.contains('ok') || 
                          cleanQuery == 'entendido' ||
                          cleanQuery == 'listo';

    final bool isGreeting = cleanQuery == 'hola' || 
                            cleanQuery.contains('buenas') || 
                            cleanQuery.contains('buen dia') || 
                            cleanQuery.contains('buen día') || 
                            cleanQuery.contains('que tal') || 
                            cleanQuery.contains('saludos');

    if (isGreeting) {
      if (state.selectedCoach == 'cristian') {
        reply = "¡Qué pasa, crack! Cristian al habla. ¿Listo para congestionar y meterle volumen a esas series hoy?";
      } else if (state.selectedCoach == 'ana') {
        reply = "¡Hola! Qué gusto saludarte. ¿Cómo va el progreso con tus entrenamientos y nutrición hoy?";
      } else {
        reply = "Saludos. Reporta tu estado actual o haz una consulta sobre tu rutina de fuerza.";
      }
    } else if (isThanks) {
      if (state.selectedCoach == 'cristian') {
        reply = "¡A ti, fiera! Dale duro a esas series hoy y recuerda llevar cada repetición al límite. ¡Nos vemos en los fierros!";
      } else if (state.selectedCoach == 'ana') {
        reply = "¡Un placer ayudarte! Cuida tu descanso y alimentación hoy. Si tienes más dudas, aquí estaré.";
      } else {
        reply = "De nada. Ejecuta las series indicadas con total precisión. Disciplina ante todo.";
      }
    } else if (isYes) {
      if (state.selectedCoach == 'cristian') {
        reply = "¡De una, fiera! Aquí tienes una rutina de Hipertrofia brutal para potenciar tu **${state.activeExercise}**:\n\n"
            "1. **${state.activeExercise} (Principal)**: 4 series x 8-10 reps al RPE 9 (peso sugerido: ${(active1RM * 0.75).toStringAsFixed(1)} $unit). Controla la fase excéntrica (bajada) en 3 segundos.\n"
            "2. Ejercicio accesorio 1: Aperturas con mancuernas - 3 series x 12 reps.\n"
            "3. Ejercicio accesorio 2: Press inclinado - 3 series x 10 reps.\n"
            "4. Drop Set final: Reduce el peso un 30% y haz reps al fallo.\n\n"
            "¡A congestionar ese músculo hoy! ¿Te convence esta rutina?";
      } else if (state.selectedCoach == 'ana') {
        reply = "¡Perfecto! Diseñemos un plan metabólico enfocado en **${state.activeExercise}** que cuide tu masa muscular:\n\n"
            "1. **${state.activeExercise}**: 3 series de 8 repeticiones intensas con ${(active1RM * 0.78).toStringAsFixed(1)} $unit para mantener la densidad ósea y muscular.\n"
            "2. Súper-serie: Zancadas caminando (12 reps por pierna) + Flexiones de pecho al fallo. Descansa 60s y repite 3 veces.\n"
            "3. Cardio HIIT al final: 15 minutos en caminadora (alternando 30s sprint / 30s descanso).\n\n"
            "Recuerda mantener tu déficit calórico y beber agua. ¿Qué te parece?";
      } else {
        reply = "Entendido. Aquí tienes la programación estricta de fuerza para **${state.activeExercise}** hoy:\n\n"
            "1. **${state.activeExercise} (Carga principal)**: 5 series x 3 repeticiones con ${(active1RM * 0.88).toStringAsFixed(1)} $unit. Descansa de 3 a 5 minutos completos entre series.\n"
            "2. Trabajo de velocidad: 3 series x 3 repeticiones explosivas con ${(active1RM * 0.65).toStringAsFixed(1)} $unit.\n"
            "3. Accesorio: Remo con barra pesado - 4 series x 5 reps.\n\n"
            "Concéntrate en la velocidad de ejecución y en empujar con fuerza. ¿Procedemos con este entrenamiento?";
      }
    } else {
      // 1. RESPUESTAS DE CRISTIAN (Hipertrofia)
      if (state.selectedCoach == 'cristian') {
        if (cleanQuery.contains("calentar") || cleanQuery.contains("calentamiento")) {
          reply = "¡Ojo al calentamiento, crack! No queremos rompernos antes de bombear. Para tu 1RM de $active1RM $unit en ${state.activeExercise}, te sugiero esto:\n\n"
              "1. Movilidad general y articular (5 mins).\n"
              "2. 1 serie de 15 reps muy ligeras para activar.\n"
              "3. 1 serie de 8 reps al 50% de tu 1RM (${(active1RM * 0.5).toStringAsFixed(1)} $unit).\n"
              "4. 1 serie de 6 reps al 70% (${(active1RM * 0.7).toStringAsFixed(1)} $unit) para sentir la carga pero sin fatiga.\n\n"
              "¡Listo, ya tienes los músculos llenos de sangre! A darle duro.";
        } else if (cleanQuery.contains("hipertrofia") || cleanQuery.contains("masa") || cleanQuery.contains("volumen") || cleanQuery.contains("rutina")) {
          reply = "¡Ese es mi terreno! Para hipertrofia pura y meter tamaño usando tu 1RM de $active1RM $unit en ${state.activeExercise}, tu zona ideal es el 72-80%:\n\n"
              "• **Carga de trabajo**: ${(active1RM * 0.72).toStringAsFixed(1)} a ${(active1RM * 0.8).toStringAsFixed(1)} $unit.\n"
              "• **Volumen**: 3 a 4 series de 8 a 12 repeticiones, controlando la bajada (fase excéntrica) en 3 segundos.\n"
              "• **Tip PRO**: En la última serie, haz un 'Drop Set': reduce el peso un 30% y haz todas las reps que puedas hasta el fallo. ¡Eso creará un bombeo brutal!";
        } else if (cleanQuery.isEmpty || cleanQuery == 'que' || cleanQuery == 'como') {
          reply = "Cuéntame, ¿qué duda específica tienes sobre tus entrenamientos de **${state.activeExercise}**? Puedo planificarte una rutina, decirte cómo calentar o indicarte qué pesos usar.";
        } else {
          reply = "¡A tope! Pensando en tu récord de $active1RM $unit en ${state.activeExercise}, te recomiendo trabajar en series de 10 repeticiones con ${(active1RM * 0.75).toStringAsFixed(1)} $unit, buscando siempre esa conexión mente-músculo y un RPE de 9 (casi al fallo).\n\n"
              "¿Quieres que te prepare una rutina enfocada en empuje o tirón para hoy?";
        }
      }
      
      // 2. RESPUESTAS DE ANA (Definición y Nutrición)
      else if (state.selectedCoach == 'ana') {
        if (cleanQuery.contains("dieta") || cleanQuery.contains("nutricion") || cleanQuery.contains("comer") || cleanQuery.contains("proteina")) {
          reply = "¡Hola! La nutrición es el 80% de tu definición. Para mantener tu fuerza de $active1RM $unit en ${state.activeExercise} en déficit, ten en cuenta esto:\n\n"
              "• **Proteína**: Consume entre 2.0 y 2.2 gramos de proteína por kilo de peso corporal al día. Esto evita la pérdida de músculo.\n"
              "• **Déficit**: Reduce solo un 15-20% de tus calorías de mantenimiento (unas 300-500 kcal menos). Un déficit muy agresivo tumbará tu fuerza.\n"
              "• **Carbohidratos**: No los elimines; consúmelos principalmente antes y después de entrenar para tener energía para tus marcas.";
        } else if (cleanQuery.contains("calentar") || cleanQuery.contains("calentamiento")) {
          reply = "Para calentar con seguridad y activar tu metabolismo antes de entrenar con base en tu marca de $active1RM $unit en ${state.activeExercise}:\n\n"
              "1. 5 minutos de caminata a paso ligero (activación cardiovascular).\n"
              "2. Estiramientos dinámicos y movilidad.\n"
              "3. 2 series de aproximación al 50% (${(active1RM * 0.5).toStringAsFixed(1)} $unit) enfocándote en una velocidad de ejecución alta.\n"
              "¡El calentamiento previene lesiones y optimiza la quema de calorías!";
        } else if (cleanQuery.isEmpty || cleanQuery == 'que' || cleanQuery == 'como') {
          reply = "Cuéntame, ¿qué te gustaría ajustar en tu sesión de **${state.activeExercise}**? Puedo darte pautas de alimentación, cardio o armarte una rutina metabólica.";
        } else {
          reply = "Para tu objetivo de definición, mantendremos la intensidad de fuerza alta con ${(active1RM * 0.78).toStringAsFixed(1)} $unit a 6-8 repeticiones en ${state.activeExercise} (para dar señal de preservar músculo al cuerpo) y añadiremos 15 minutos de cardio HIIT al final.\n\n"
              "¿Quieres que revisemos cuánta proteína necesitas consumir al día o prefieres consejos de suplementos?";
        }
      }
      
      // 3. RESPUESTAS DE IGOR (Fuerza y Explosividad)
      else {
        if (cleanQuery.contains("fuerza") || cleanQuery.contains("maxima") || cleanQuery.contains("1rm") || cleanQuery.contains("progresion")) {
          reply = "Escucha atentamente. Para aumentar tu marca de $active1RM $unit en ${state.activeExercise}, la fatiga es el enemigo. Tu sistema nervioso debe estar fresco:\n\n"
              "• **Zona de Fuerza**: Trabaja estrictamente entre el 85% y el 92% de tu 1RM (${(active1RM * 0.85).toStringAsFixed(1)} a ${(active1RM * 0.92).toStringAsFixed(1)} $unit).\n"
              "• **Series y Reps**: 5 series de 3 repeticiones o 3 series de 5 repeticiones. Nunca busques el fallo muscular (RPE 7.5-8.5).\n"
              "• **Descanso**: Reposa de 3 a 5 minutos completos entre series. Si descansas menos, entrenarás resistencia, no fuerza.";
        } else if (cleanQuery.contains("calentar") || cleanQuery.contains("calentamiento")) {
          reply = "Para preparar tu sistema nervioso central para levantar cargas pesadas cerca de tu 1RM de $active1RM $unit en ${state.activeExercise}, sigue este protocolo estricto:\n\n"
              "1. Activación de core (planchas) y movilidad articular.\n"
              "2. 5 reps con barra vacía.\n"
              "3. 3 reps con el 60% (${(active1RM * 0.6).toStringAsFixed(1)} $unit).\n"
              "4. 1 rep con el 80% (${(active1RM * 0.8).toStringAsFixed(1)} $unit) para indicarle al cerebro que viene peso real.\n\n"
              "Descansa 3 minutos e inicia tus series de fuerza efectiva.";
        } else if (cleanQuery.isEmpty || cleanQuery == 'que' || cleanQuery == 'como') {
          reply = "Especifica tu duda sobre **${state.activeExercise}**. Puedo estructurar tu progresión de cargas, detallar tu calentamiento nervioso o planificar tus series efectivas.";
        } else {
          reply = "Si tu meta es superar tus $active1RM $unit actuales en ${state.activeExercise}, hoy realizaremos un entrenamiento de fuerza explosiva. Haremos 5 series de 2 repeticiones pesadas con ${(active1RM * 0.88).toStringAsFixed(1)} $unit, empujando la barra con la máxima velocidad posible en la subida.\n\n"
              "¿Quieres que te detalle la progresión semanal de cargas o tienes dudas de técnica en tu levantamiento?";
        }
      }
    }

    final replyMsg = ChatMessage(text: reply, isUser: false);

    // Imprimir OUTPUT de interacción con la IA (Simulación Fallback)
    print("==================== IA OUTPUT (SIMULATION) ====================");
    print("Response: $reply");
    print("================================================================");

    state = state.copyWith(
      messages: [
        ...state.messages,
        replyMsg,
      ],
      isThinking: false,
    );
    _saveConversationsToPrefs();
  }

  Future<void> deleteModel() async {
    state = state.copyWith(
      isModelInstalled: false,
      isUsingLocalAI: false,
      messages: [],
      conversations: {},
      isOnboarded: false,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('coach_is_onboarded');
    await prefs.remove('coach_conversations');
  }

  Future<String> _callGeminiApi(String systemPrompt, List<ChatMessage> history, String apiKey) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=" + apiKey);
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final List<Map<String, dynamic>> contents = [];
      for (final msg in history) {
        // La API de chat de Gemini requiere que el primer mensaje tenga el rol 'user'
        if (contents.isEmpty && !msg.isUser) {
          continue;
        }
        contents.add({
          "role": msg.isUser ? "user" : "model",
          "parts": [{"text": msg.text}]
        });
      }

      final body = {
        "contents": contents,
        "systemInstruction": {
          "parts": [{"text": systemPrompt}]
        },
        "generationConfig": {
          "temperature": 0.6,
          "maxOutputTokens": 8192,
        }
      };

      request.write(jsonEncode(body));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

        final candidates = decoded["candidates"] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]["content"] as Map<String, dynamic>?;
          if (content != null) {
            final parts = content["parts"] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]["text"] as String? ?? "Entendido.";
            }
          }
        }
        return "Lo siento, no pude obtener respuesta del servidor.";
      } else {
        final errorResponse = await response.transform(utf8.decoder).join();
        print("[Gemini API Error] Status ${response.statusCode}: $errorResponse");
        return "Error al conectar con la API de Gemini (Código " + response.statusCode.toString() + ").";
      }
    } catch (e) {
      print("[Gemini API Exception] $e");
      if (e is SocketException) {
        return "Error de conexión: Parece que no tienes acceso a internet. Verifica tu red e intenta nuevamente.";
      }
      return "Error de conexión: No se pudo contactar con la API de Gemini.";
    } finally {
      client.close();
    }
  }

  Future<String> _callHuggingFaceApi(String systemPrompt, List<ChatMessage> history, String token) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse("https://api-inference.huggingface.co/models/Qwen/Qwen2.5-7B-Instruct/v1/chat/completions");
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      if (token.isNotEmpty) {
        request.headers.set("Authorization", "Bearer " + token);
      }

      final List<Map<String, dynamic>> messages = [
        {"role": "system", "content": systemPrompt}
      ];
      for (final msg in history) {
        messages.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text
        });
      }

      final body = {
        "model": "Qwen/Qwen2.5-7B-Instruct",
        "messages": messages,
        "max_tokens": 2048,
        "temperature": 0.6
      };

      request.write(jsonEncode(body));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;

        final choices = decoded["choices"] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]["message"] as Map<String, dynamic>?;
          if (message != null) {
            return message["content"] as String? ?? "Entendido.";
          }
        }
        return "Lo siento, no pude procesar la respuesta del modelo.";
      } else {
        final errorResponse = await response.transform(utf8.decoder).join();
        print("[Hugging Face API Error] Status ${response.statusCode}: $errorResponse");
        if (response.statusCode == 503) {
          return "El modelo se está cargando en Hugging Face. Por favor, espera unos segundos e intenta enviar el mensaje nuevamente.";
        }
        return "Error al conectar con Hugging Face (Código " + response.statusCode.toString() + ").";
      }
    } catch (e) {
      print("[Hugging Face API Exception] $e");
      if (e is SocketException) {
        return "Error de conexión: Parece que no tienes acceso a internet. Verifica tu red e intenta nuevamente.";
      }
      return "Error de conexión: No se pudo contactar con Hugging Face.";
    } finally {
      client.close();
    }
  }

  void clearChat() {
    state = state.copyWith(
      messages: [],
    );
    _initializeChatSession();
  }
}

// Proveedor global para el entrenador de IA
final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  return CoachNotifier(ref);
});
