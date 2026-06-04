import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Estructuras FFI opacas de LiteRT-LM
final class LiteRtLmEngineSettings extends Opaque {}
final class LiteRtLmEngine extends Opaque {}
final class LiteRtLmSessionConfig extends Opaque {}
final class LiteRtLmConversationConfig extends Opaque {}
final class LiteRtLmConversation extends Opaque {}
final class LiteRtLmConversationOptionalArgs extends Opaque {}
final class LiteRtLmJsonResponse extends Opaque {}

// Parámetros de muestreo (Sampler Params)
final class LiteRtLmSamplerParams extends Struct {
  @Int32()
  external int typeAsInt;

  @Int32()
  external int top_k;

  @Float()
  external double top_p;

  @Float()
  external double temperature;

  @Int32()
  external int seed;
}

void main() async {
  print("=================================================================");
  print("   CENTRO DE ENTRENAMIENTO AI COACH - CHAT INTERACTIVO (CLI)");
  print("=================================================================");

  final envLibDir = Platform.environment['FLUTTER_GEMMA_LIB_DIR'];
  if (envLibDir == null || envLibDir.isEmpty) {
    print("❌ ERROR: La variable de entorno FLUTTER_GEMMA_LIB_DIR no está configurada.");
    print("\nPara ejecutar el script, usa el siguiente comando:");
    print("FLUTTER_GEMMA_LIB_DIR=\"/mnt/c/repos/krs-powemax/build/linux/x64/debug/bundle/lib\" VK_ICD_FILENAMES=\"\" WGPU_BACKEND=\"empty\" dart run test/test_interactive_chat.dart");
    exit(1);
  }

  // Rutas de los modelos
  final smolModelPath = '/home/jorgeabm/.local/share/powermax_1rm/flutter_gemma/SmolLM2_135M_Instruct.litertlm';
  final qwenModelPath = '/home/jorgeabm/.local/share/powermax_1rm/flutter_gemma/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm';
  final cacheDir = '/home/jorgeabm/.local/share/powermax_1rm/flutter_gemma/cache';

  String modelPath = smolModelPath;
  final hasQwen = File(qwenModelPath).existsSync();

  print("\nSelecciona el Modelo de IA a utilizar:");
  print("1) SmolLM2 (135M) - Muy rápido (~140MB). Solo funciona bien en Inglés.");
  if (hasQwen) {
    print("2) Qwen2.5 (1.5B) - Inteligente (~1.6GB). Funciona excelente en Español.");
  } else {
    print("2) [No descargado] Qwen2.5 (1.5B) - Excelente en Español (ejecuta primero './download_model.sh' para descargarlo).");
  }
  stdout.write("Elige una opción (1-2): ");
  final modelOption = stdin.readLineSync()?.trim() ?? "1";
  
  if (modelOption == "2" && hasQwen) {
    modelPath = qwenModelPath;
    print("-> Seleccionado: Qwen2.5 (1.5B)");
  } else {
    modelPath = smolModelPath;
    print("-> Seleccionado: SmolLM2 (135M)");
  }

  if (!File(modelPath).existsSync()) {
    print("❌ ERROR: No se encontró el modelo seleccionado en: $modelPath");
    exit(1);
  }

  Directory(cacheDir).createSync(recursive: true);

  // Selección de entrenador
  print("\nSelecciona tu Entrenador:");
  print("1) Cristian - Hipertrofia (Culturismo enérgico y motivador)");
  print("2) Ana - Nutrición y Definición (Empática y directa)");
  print("3) Igor - Powerlifting (Serio y analítico soviético)");
  print("4) Sin Entrenador - Modo Crudo/Inglés (Sin instrucciones de personalidad ni traducción)");
  stdout.write("Elige una opción (1-4): ");
  final optionInput = stdin.readLineSync()?.trim() ?? "1";
  
  String coachName = "Cristian";
  String systemPrompt = "Hola Cristian, actúa como mi entrenador de culturismo muy enérgico, motivador y un poco bromista del gym. Responde siempre en español, de forma muy concisa (máximo 2 párrafos). Mi consulta es la siguiente: ";
  
  if (optionInput == "2") {
    coachName = "Ana";
    systemPrompt = "Hola Ana, actúa como mi entrenadora de nutrición y definición, muy empática y directa. Responde siempre en español, de forma muy concisa (máximo 2 párrafos). Mi consulta es la siguiente: ";
  } else if (optionInput == "3") {
    coachName = "Igor";
    systemPrompt = "Hola Igor, actúa como mi serio entrenador soviético de powerlifting, muy analítico y directo. Responde siempre en español, de forma muy concisa (máximo 2 párrafos). Mi consulta es la siguiente: ";
  } else if (optionInput == "4") {
    coachName = "Modelo Crudo";
    systemPrompt = "";
  }

  print("\nCargando librerías y modelo (esto puede tardar unos segundos)...");

  // Pre-cargar librerías usando StreamProxy para soporte RTLD_GLOBAL
  final proxyLib = DynamicLibrary.open('$envLibDir/libStreamProxy.so');
  final loadGlobal = proxyLib.lookupFunction<
      Pointer Function(Pointer<Utf8>),
      Pointer Function(Pointer<Utf8>)>('stream_proxy_load_global');

  final libs = [
    'libLiteRt.so',
    'libGemmaModelConstraintProvider.so',
    'libLiteRtLm.so',
  ];

  for (final name in libs) {
    final fullPath = '$envLibDir/$name';
    final pathPtr = fullPath.toNativeUtf8();
    loadGlobal(pathPtr);
    calloc.free(pathPtr);
  }

  final lib = DynamicLibrary.open('$envLibDir/libLiteRtLm.so');

  // Lookup de las funciones nativas necesarias
  final litert_lm_engine_settings_create = lib.lookupFunction<
      Pointer<LiteRtLmEngineSettings> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>),
      Pointer<LiteRtLmEngineSettings> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>)
  >('litert_lm_engine_settings_create');

  final litert_lm_engine_settings_delete = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmEngineSettings>),
      void Function(Pointer<LiteRtLmEngineSettings>)
  >('litert_lm_engine_settings_delete');

  final litert_lm_engine_settings_set_max_num_tokens = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmEngineSettings>, Int32),
      void Function(Pointer<LiteRtLmEngineSettings>, int)
  >('litert_lm_engine_settings_set_max_num_tokens');

  final litert_lm_engine_settings_enable_benchmark = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmEngineSettings>),
      void Function(Pointer<LiteRtLmEngineSettings>)
  >('litert_lm_engine_settings_enable_benchmark');

  final litert_lm_engine_settings_set_cache_dir = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmEngineSettings>, Pointer<Utf8>),
      void Function(Pointer<LiteRtLmEngineSettings>, Pointer<Utf8>)
  >('litert_lm_engine_settings_set_cache_dir');

  final litert_lm_engine_create = lib.lookupFunction<
      Pointer<LiteRtLmEngine> Function(Pointer<LiteRtLmEngineSettings>),
      Pointer<LiteRtLmEngine> Function(Pointer<LiteRtLmEngineSettings>)
  >('litert_lm_engine_create');

  final litert_lm_engine_delete = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmEngine>),
      void Function(Pointer<LiteRtLmEngine>)
  >('litert_lm_engine_delete');

  final litert_lm_session_config_create = lib.lookupFunction<
      Pointer<LiteRtLmSessionConfig> Function(),
      Pointer<LiteRtLmSessionConfig> Function()
  >('litert_lm_session_config_create');

  final litert_lm_session_config_delete = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmSessionConfig>),
      void Function(Pointer<LiteRtLmSessionConfig>)
  >('litert_lm_session_config_delete');

  final litert_lm_session_config_set_sampler_params = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmSessionConfig>, Pointer<LiteRtLmSamplerParams>),
      void Function(Pointer<LiteRtLmSessionConfig>, Pointer<LiteRtLmSamplerParams>)
  >('litert_lm_session_config_set_sampler_params');

  final litert_lm_conversation_config_create = lib.lookupFunction<
      Pointer<LiteRtLmConversationConfig> Function(
          Pointer<LiteRtLmEngine>, Pointer<LiteRtLmSessionConfig>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Bool),
      Pointer<LiteRtLmConversationConfig> Function(
          Pointer<LiteRtLmEngine>, Pointer<LiteRtLmSessionConfig>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, bool)
  >('litert_lm_conversation_config_create');

  final litert_lm_conversation_config_delete = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmConversationConfig>),
      void Function(Pointer<LiteRtLmConversationConfig>)
  >('litert_lm_conversation_config_delete');

  final litert_lm_conversation_create = lib.lookupFunction<
      Pointer<LiteRtLmConversation> Function(Pointer<LiteRtLmEngine>, Pointer<LiteRtLmConversationConfig>),
      Pointer<LiteRtLmConversation> Function(Pointer<LiteRtLmEngine>, Pointer<LiteRtLmConversationConfig>)
  >('litert_lm_conversation_create');

  final litert_lm_conversation_delete = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmConversation>),
      void Function(Pointer<LiteRtLmConversation>)
  >('litert_lm_conversation_delete');

  final litert_lm_conversation_optional_args_create = lib.lookupFunction<
      Pointer<LiteRtLmConversationOptionalArgs> Function(),
      Pointer<LiteRtLmConversationOptionalArgs> Function()
  >('litert_lm_conversation_optional_args_create');

  final litert_lm_conversation_optional_args_delete = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmConversationOptionalArgs>),
      void Function(Pointer<LiteRtLmConversationOptionalArgs>)
  >('litert_lm_conversation_optional_args_delete');

  final litert_lm_conversation_send_message = lib.lookupFunction<
      Pointer<LiteRtLmJsonResponse> Function(
          Pointer<LiteRtLmConversation>, Pointer<Utf8>, Pointer<Utf8>, Pointer<LiteRtLmConversationOptionalArgs>),
      Pointer<LiteRtLmJsonResponse> Function(
          Pointer<LiteRtLmConversation>, Pointer<Utf8>, Pointer<Utf8>, Pointer<LiteRtLmConversationOptionalArgs>)
  >('litert_lm_conversation_send_message');

  final litert_lm_json_response_get_string = lib.lookupFunction<
      Pointer<Utf8> Function(Pointer<LiteRtLmJsonResponse>),
      Pointer<Utf8> Function(Pointer<LiteRtLmJsonResponse>)
  >('litert_lm_json_response_get_string');

  final litert_lm_json_response_delete = lib.lookupFunction<
      Void Function(Pointer<LiteRtLmJsonResponse>),
      void Function(Pointer<LiteRtLmJsonResponse>)
  >('litert_lm_json_response_delete');

  // Inicializar Motor
  final modelPathPtr = modelPath.toNativeUtf8();
  final backendPtr = 'cpu'.toNativeUtf8();

  final settings = litert_lm_engine_settings_create(modelPathPtr, backendPtr, nullptr, nullptr);
  if (settings == nullptr) {
    print("❌ ERROR: No se pudieron crear los ajustes del motor.");
    calloc.free(modelPathPtr);
    calloc.free(backendPtr);
    exit(1);
  }

  litert_lm_engine_settings_set_max_num_tokens(settings, 2048);
  litert_lm_engine_settings_enable_benchmark(settings);

  final cacheDirPtr = cacheDir.toNativeUtf8();
  litert_lm_engine_settings_set_cache_dir(settings, cacheDirPtr);
  calloc.free(cacheDirPtr);

  final engine = litert_lm_engine_create(settings);
  litert_lm_engine_settings_delete(settings);
  calloc.free(modelPathPtr);
  calloc.free(backendPtr);

  if (engine == nullptr) {
    print("❌ ERROR: No se pudo crear el motor (Engine).");
    exit(1);
  }

  // Configuración de la sesión
  final sessionConfig = litert_lm_session_config_create();
  final samplerParams = calloc<LiteRtLmSamplerParams>();
  samplerParams.ref.typeAsInt = 2; // TopP
  samplerParams.ref.top_k = 40;
  samplerParams.ref.top_p = 0.95;
  samplerParams.ref.temperature = 0.6; // Ligeramente más bajo para consistencia
  samplerParams.ref.seed = 42;

  litert_lm_session_config_set_sampler_params(sessionConfig, samplerParams);
  calloc.free(samplerParams);

  // Conversación sin System Message nativo por el bug del template de SmolLM2
  final convConfig = litert_lm_conversation_config_create(
    engine,
    sessionConfig,
    nullptr,
    nullptr,
    nullptr,
    false,
  );
  litert_lm_session_config_delete(sessionConfig);

  if (convConfig == nullptr) {
    print("❌ ERROR: No se pudo crear la configuración de conversación.");
    litert_lm_engine_delete(engine);
    exit(1);
  }

  final conversation = litert_lm_conversation_create(engine, convConfig);
  litert_lm_conversation_config_delete(convConfig);

  if (conversation == nullptr) {
    print("❌ ERROR: No se pudo crear la conversación.");
    litert_lm_engine_delete(engine);
    exit(1);
  }

  print("✅ Entrenador $coachName cargado y listo.");
  print("🔥 Escribe tu mensaje y presiona ENTER. Escribe 'salir' o 'exit' para salir.\n");

  bool isFirstMessage = true;

  while (true) {
    stdout.write("\nTú > ");
    final input = stdin.readLineSync(encoding: utf8);
    if (input == null) break;

    final trimmedInput = input.trim();
    if (trimmedInput.isEmpty) continue;

    if (trimmedInput.toLowerCase() == 'salir' || trimmedInput.toLowerCase() == 'exit') {
      print("¡Adiós, guerrero! A seguir entrenando duro. 💪🔥");
      break;
    }

    String messageText;
    if (isFirstMessage) {
      messageText = "$systemPrompt$trimmedInput";
      isFirstMessage = false;
    } else {
      messageText = trimmedInput;
    }

    final content = [{'type': 'text', 'text': messageText}];
    final messageJson = jsonEncode({'role': 'user', 'content': content});

    final messageJsonPtr = messageJson.toNativeUtf8();
    final optionalArgs = litert_lm_conversation_optional_args_create();

    stdout.write("$coachName > Pensando...");

    final response = litert_lm_conversation_send_message(
      conversation,
      messageJsonPtr.cast(),
      nullptr,
      optionalArgs,
    );

    // Borrar "Pensando..."
    stdout.write("\r" + " " * (coachName.length + 15) + "\r");

    if (response == nullptr) {
      print("$coachName > ❌ Error: No se recibió respuesta.");
    } else {
      final strPtr = litert_lm_json_response_get_string(response);
      if (strPtr != nullptr) {
        final responseJsonStr = strPtr.cast<Utf8>().toDartString();
        
        try {
          final jsonMap = jsonDecode(responseJsonStr) as Map<String, dynamic>;
          final contentList = jsonMap['content'] as List<dynamic>?;
          if (contentList != null) {
            final buffer = StringBuffer();
            for (final item in contentList) {
              if (item is Map<String, dynamic> && item['type'] == 'text') {
                buffer.write(item['text'] as String? ?? '');
              }
            }
            stdout.write("$coachName > ");
            print(buffer.toString().trim());
          } else {
            stdout.write("$coachName > ");
            print(responseJsonStr);
          }
        } catch (e) {
          stdout.write("$coachName > ");
          print(responseJsonStr);
        }
      } else {
        print("$coachName > ❌ Error: Respuesta vacía.");
      }
      litert_lm_json_response_delete(response);
    }

    litert_lm_conversation_optional_args_delete(optionalArgs);
    calloc.free(messageJsonPtr);
  }

  litert_lm_conversation_delete(conversation);
  litert_lm_engine_delete(engine);
  print("\nRecursos liberados.");
}
