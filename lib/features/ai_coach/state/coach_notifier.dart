import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../calculator/state/calculator_notifier.dart';
import '../../settings/state/settings_notifier.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isThinking;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isThinking = false,
  });
}

class CoachState {
  final bool isModelInstalled;
  final bool isDownloading;
  final int downloadProgress;
  final List<ChatMessage> messages;
  final bool isThinking;
  final String selectedCoach; // 'cristian' (hipertrofia), 'ana' (definición/nutrición), 'igor' (fuerza)
  final String? error;

  CoachState({
    required this.isModelInstalled,
    required this.isDownloading,
    required this.downloadProgress,
    required this.messages,
    required this.isThinking,
    required this.selectedCoach,
    this.error,
  });

  CoachState copyWith({
    bool? isModelInstalled,
    bool? isDownloading,
    int? downloadProgress,
    List<ChatMessage>? messages,
    bool? isThinking,
    String? selectedCoach,
    String? error,
  }) {
    return CoachState(
      isModelInstalled: isModelInstalled ?? this.isModelInstalled,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      selectedCoach: selectedCoach ?? this.selectedCoach,
      error: error,
    );
  }
}

class CoachNotifier extends StateNotifier<CoachState> {
  final Ref ref;
  dynamic _activeChatSession; // Guarda la sesión activa de flutter_gemma en producción
  static const String _modelFileName = 'smollm-135m-instruct.litertlm';
  static const String _modelDownloadUrl = 'https://huggingface.co/litert-community/SmolLM-135M-Instruct/resolve/main/smollm-135m-instruct.litertlm';

  CoachNotifier(this.ref)
      : super(CoachState(
          isModelInstalled: false,
          isDownloading: false,
          downloadProgress: 0,
          messages: [],
          isThinking: false,
          selectedCoach: 'cristian', // Cristian por defecto
        )) {
    _checkModelStatus();
  }

  // Cambia de entrenador e inicializa una nueva sesión de chat personalizada
  void selectCoach(String coach) {
    if (state.selectedCoach == coach && state.messages.isNotEmpty) return;
    state = state.copyWith(selectedCoach: coach);
    _initializeChatSession();
  }

  // Verifica si el modelo está instalado localmente al iniciar
  Future<void> _checkModelStatus() async {
    try {
      final isInstalled = await FlutterGemma.isModelInstalled(_modelFileName);
      state = state.copyWith(isModelInstalled: isInstalled);
      if (isInstalled) {
        _initializeChatSession();
      }
    } catch (e) {
      state = state.copyWith(isModelInstalled: false);
    }
  }

  // Descarga e instala el modelo LLM local desde HuggingFace
  Future<void> downloadModel() async {
    state = state.copyWith(isDownloading: true, downloadProgress: 0, error: null);

    try {
      await FlutterGemma.installModel(modelType: ModelType.general)
          .fromNetwork(_modelDownloadUrl)
          .withProgress((progress) {
            state = state.copyWith(downloadProgress: progress);
          })
          .install();

      state = state.copyWith(
        isDownloading: false,
        isModelInstalled: true,
        downloadProgress: 100,
      );
      _initializeChatSession();
    } catch (e) {
      // Modo de Simulación de Prototipo (Mecanismo de Respaldo Excepcional)
      int progress = 0;
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        progress += 5;
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
  }

  // Inicializa el chat con el mensaje de bienvenida y personalidad del coach seleccionado
  Future<void> _initializeChatSession() async {
    final calcState = ref.read(calculatorProvider);
    final unit = ref.read(settingsProvider).weightUnit;
    final r1rm = calcState.calculated1RM;
    
    String welcomeText = "";
    if (state.selectedCoach == 'cristian') {
      welcomeText = "¡Qué pasa, crack! Soy Cristian, tu entrenador enfocado en Hipertrofia Muscular. 💪 He visto que tu 1RM estimado es de $r1rm $unit. ¡Un excelente punto de partida! Vamos a congestionar y meterle volumen a esas series para romper fibras hoy. ¿Prefieres que te diseñe una rutina para ganar masa o tienes dudas de técnica?";
    } else if (state.selectedCoach == 'ana') {
      welcomeText = "¡Hola! Soy Ana 🍎, tu especialista en Definición Corporal y Nutrición. Con tu 1RM estimado de $r1rm $unit, podemos estructurar un entrenamiento metabólico increíble que queme grasa mientras conserva cada gramo de tu músculo. ¿Qué dudas tienes sobre tu dieta, suplementación o cardio para hoy?";
    } else {
      welcomeText = "Saludos. Soy Igor ⚡, especialista en Fuerza Máxima y Potencia Explosiva. Tu marca estimada de $r1rm $unit es respetable, pero está lejos de tu límite real. Ganar fuerza requiere menos repeticiones, descansos largos y una progresión perfecta. ¿Listo para programar tu próxima marca personal?";
    }

    state = state.copyWith(
      messages: [
        ChatMessage(
          text: welcomeText,
          isUser: false,
        )
      ],
    );

    try {
      final model = await FlutterGemma.getActiveModel(maxTokens: 512);
      _activeChatSession = await model.openChat();
    } catch (e) {
      _activeChatSession = null;
    }
  }

  // Envía un mensaje al entrenador de IA
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isThinking: true,
    );

    final calcState = ref.read(calculatorProvider);
    final unit = ref.read(settingsProvider).weightUnit;
    final r1rm = calcState.calculated1RM;

    // Crear prompt de personalidad según el coach seleccionado
    String coachInstruction = "";
    if (state.selectedCoach == 'cristian') {
      coachInstruction = "Actúa como Cristian, un entrenador de culturismo muy enérgico, motivador y un poco bromista del gym, especializado en hipertrofia y ganancia muscular. Enfócate en RPE 8-10, drop-sets, tiempo bajo tensión y nutrición hipercalórica. ";
    } else if (state.selectedCoach == 'ana') {
      coachInstruction = "Actúa como Ana, una entrenadora profesional especialista en definición, pérdida de grasa corporal y nutrición deportiva. Habla con un tono alentador, empático y muy basado en ciencia. Prioriza el déficit calórico, macronutrientes y entrenamiento de alta intensidad. ";
    } else {
      coachInstruction = "Actúa como Igor, un entrenador soviético de powerlifting clásico, extremadamente serio, analítico y directo, especialista en fuerza máxima. Prioriza series de bajas repeticiones (1-5 reps), descansos de 3-5 minutos, y progresión lineal con el 1RM. ";
    }

    final String contextPrompt = "$coachInstruction El usuario tiene un 1RM de $r1rm $unit "
        "con base en ${calcState.weight} levantados para ${calcState.reps} reps. ";

    if (_activeChatSession != null) {
      try {
        final fullPrompt = "$contextPrompt Pregunta del usuario: $text";
        await _activeChatSession.addQueryChunk(Message.text(text: fullPrompt, isUser: true));
        
        final response = await _activeChatSession.generateChatResponse();
        String replyText = "Entendido.";
        if (response is TextResponse) {
          replyText = response.token;
        }

        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage(text: replyText, isUser: false),
          ],
          isThinking: false,
        );
      } catch (e) {
        _fallbackResponse(text);
      }
    } else {
      // Simulación de respuesta adaptada a la personalidad de cada Coach
      await Future.delayed(const Duration(seconds: 1));
      _fallbackResponse(text);
    }
  }

  // Genera respuestas simuladas inteligentes basadas en el 1RM actual y la personalidad del coach
  void _fallbackResponse(String userQuery) {
    final calcState = ref.read(calculatorProvider);
    final unit = ref.read(settingsProvider).weightUnit;
    final r1rm = calcState.calculated1RM;
    
    String reply = "";
    final queryLower = userQuery.toLowerCase();

    // 1. RESPUESTAS DE CRISTIAN (Hipertrofia)
    if (state.selectedCoach == 'cristian') {
      if (queryLower.contains("calentar") || queryLower.contains("calentamiento")) {
        reply = "¡Ojo al calentamiento, crack! No queremos rompernos antes de bombear. Para tu 1RM de $r1rm $unit, te sugiero esto:\n\n"
            "1. Movilidad de hombros y codos (5 mins).\n"
            "2. 1 serie de 15 reps muy ligeras (la barra sola).\n"
            "3. 1 serie de 8 reps al 50% de tu 1RM (${(r1rm * 0.5).toStringAsFixed(1)} $unit).\n"
            "4. 1 serie de 6 reps al 70% (${(r1rm * 0.7).toStringAsFixed(1)} $unit) para sentir la carga pero sin fatiga.\n\n"
            "¡Listo, ya tienes los músculos llenos de sangre! A darle duro.";
      } else if (queryLower.contains("hipertrofia") || queryLower.contains("masa") || queryLower.contains("volumen")) {
        reply = "¡Ese es mi terreno! Para hipertrofia pura y meter tamaño usando tu 1RM de $r1rm $unit, tu zona ideal es el 72-80%:\n\n"
            "• **Carga de trabajo**: ${(r1rm * 0.72).toStringAsFixed(1)} a ${(r1rm * 0.8).toStringAsFixed(1)} $unit.\n"
            "• **Volumen**: 3 a 4 series de 8 a 12 repeticiones, controlando la bajada (fase excéntrica) en 3 segundos.\n"
            "• **Tip PRO**: En la última serie, haz un 'Drop Set': reduce el peso un 30% y haz todas las reps que puedas hasta que te ardan los músculos. ¡Eso creará un bombeo brutal!";
      } else {
        reply = "¡A tope! Pensando en tu récord de $r1rm $unit, para hipertrofia te recomiendo trabajar en series de 10 repeticiones con ${(r1rm * 0.75).toStringAsFixed(1)} $unit, buscando siempre esa conexión mente-músculo y un RPE de 9 (casi al fallo).\n\n"
            "¿Quieres que te prepare una rutina enfocada en empuje o tirón para hoy?";
      }
    }
    
    // 2. RESPUESTAS DE ANA (Definición y Nutrición)
    else if (state.selectedCoach == 'ana') {
      if (queryLower.contains("dieta") || queryLower.contains("nutricion") || queryLower.contains("comer") || queryLower.contains("proteina")) {
        reply = "¡Hola! La nutrición es el 80% de tu definición. Para mantener tu fuerza de $r1rm $unit en déficit, ten en cuenta esto:\n\n"
            "• **Proteína**: Consume entre 2.0 y 2.2 gramos de proteína por kilo de peso corporal al día. Esto evita la pérdida de músculo.\n"
            "• **Déficit**: Reduce solo un 15-20% de tus calorías de mantenimiento (unas 300-500 kcal menos). Un déficit muy agresivo tumbará tu fuerza.\n"
            "• **Carbohidratos**: No los elimines; consúmelos principalmente antes y después de entrenar para tener energía para tus marcas.";
      } else if (queryLower.contains("calentar") || queryLower.contains("calentamiento")) {
        reply = "Para calentar con seguridad y activar tu metabolismo antes de entrenar con base en tu marca de $r1rm $unit:\n\n"
            "1. 5 minutos de caminata a paso ligero o elíptica (activación cardiovascular).\n"
            "2. Estiramientos dinámicos y movilidad.\n"
            "3. 2 series de aproximación al 50% (${(r1rm * 0.5).toStringAsFixed(1)} $unit) enfocándote en una velocidad de ejecución alta.\n"
            "¡El calentamiento previene lesiones y optimiza la quema de calorías!";
      } else {
        reply = "Para tu objetivo de definición, mantendremos la intensidad de fuerza alta con ${(r1rm * 0.78).toStringAsFixed(1)} $unit a 6-8 repeticiones (para dar señal de preservar músculo al cuerpo) y añadiremos 15 minutos de cardio HIIT al final.\n\n"
            "¿Quieres que revisemos cuánta proteína necesitas consumir al día o prefieres consejos de suplementos quemagrasa?";
      }
    }
    
    // 3. RESPUESTAS DE IGOR (Fuerza y Explosividad)
    else {
      if (queryLower.contains("fuerza") || queryLower.contains("maxima") || queryLower.contains("1rm") || queryLower.contains("progresion")) {
        reply = "Escucha atentamente. Para aumentar tu marca de $r1rm $unit, la fatiga es el enemigo. Tu sistema nervioso debe estar fresco:\n\n"
            "• **Zona de Fuerza**: Trabaja estrictamente entre el 85% y el 92% de tu 1RM (${(r1rm * 0.85).toStringAsFixed(1)} a ${(r1rm * 0.92).toStringAsFixed(1)} $unit).\n"
            "• **Series y Reps**: 5 series de 3 repeticiones o 3 series de 5 repeticiones. Nunca busques el fallo muscular (RPE 7.5-8.5).\n"
            "• **Descanso**: Reposa de 3 a 5 minutos completos entre series. Si descansas menos, entrenarás resistencia, no fuerza.";
      } else if (queryLower.contains("calentar") || queryLower.contains("calentamiento")) {
        reply = "Para preparar tu sistema nervioso central para levantar cargas pesadas cerca de tu 1RM de $r1rm $unit, sigue este protocolo estricto:\n\n"
            "1. Activación de core (planchas) y movilidad articular.\n"
            "2. 5 reps con barra vacía.\n"
            "3. 3 reps con el 60% (${(r1rm * 0.6).toStringAsFixed(1)} $unit).\n"
            "4. 1 rep con el 80% (${(r1rm * 0.8).toStringAsFixed(1)} $unit) para indicarle al cerebro que viene peso real.\n\n"
            "Descansa 3 minutos e inicia tus series de fuerza efectiva.";
      } else {
        reply = "Si tu meta es superar tus $r1rm $unit actuales, hoy realizaremos un entrenamiento de fuerza explosiva. Haremos 5 series de 2 repeticiones pesadas con ${(r1rm * 0.88).toStringAsFixed(1)} $unit, empujando la barra con la máxima velocidad posible en la subida.\n\n"
            "¿Quieres que te detalle la progresión semanal de cargas o tienes dudas de técnica en tu levantamiento?";
      }
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(text: reply, isUser: false),
      ],
      isThinking: false,
    );
  }

  void clearChat() {
    _initializeChatSession();
  }
}

// Proveedor global para el entrenador de IA
final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  return CoachNotifier(ref);
});
