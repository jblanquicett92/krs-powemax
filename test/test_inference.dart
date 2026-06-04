import 'dart:convert';
import 'dart:io';
import 'package:flutter_gemma/core/ffi/litert_lm_client.dart';

void main() async {
  print("--- INICIANDO PRUEBA DE INFERENCIA LOCAL MULTI-TURNO ---");

  final modelPath = '/home/jorgeabm/.local/share/powermax_1rm/flutter_gemma/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm';
  final cacheDir = '/home/jorgeabm/.local/share/powermax_1rm/flutter_gemma/cache';
  Directory(cacheDir).createSync(recursive: true);

  final client = LiteRtLmFfiClient();

  try {
    print("Inicializando el cliente (cargando modelo: $modelPath)...");
    await client.initialize(
      modelPath: modelPath,
      backend: 'cpu',
      maxTokens: 2048,
      cacheDir: cacheDir,
    );
    print("✅ ¡ÉXITO! El cliente se ha inicializado correctamente.");
    
    final systemPrompt = "Actúa como Cristian, un entrenador de culturismo muy enérgico, motivador y un poco bromista del gym. Responde siempre en español, de forma muy concisa (máximo 2 párrafos).";
    print("System Prompt: $systemPrompt");

    print("Creando manejador de conversación...");
    final token = Object();
    
    // Función auxiliar para enviar mensajes a través de startVirtualTurn
    Future<void> sendTurn(String userText, List<({String role, String text})> history) async {
      print("\n------------------------------");
      print("USER: $userText");
      print("History turns: ${history.length}");
      for (var i = 0; i < history.length; i++) {
        print("  H[$i] ${history[i].role}: ${history[i].text}");
      }
      
      final messageJson = LiteRtLmFfiClient.buildMessageJson(userText);
      final responseBuffer = StringBuffer();
      
      await for (final chunk in client.startVirtualTurn(
        conversationToken: token,
        messageJson: messageJson,
        history: history,
        systemMessage: systemPrompt,
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        seed: 42,
      )) {
        final text = LiteRtLmFfiClient.extractTextFromResponse(chunk);
        stdout.write(text);
        responseBuffer.write(text);
      }
      print("\n------------------------------");
      final responseText = responseBuffer.toString();
      history.add((role: 'user', text: userText));
      history.add((role: 'model', text: responseText)); // 'model' is used internally
    }

    final List<({String role, String text})> history = [];
    
    // Simular conversación
    await sendTurn("hola, dame consejos", history);
    await sendTurn("como?", history);

    print("Apagando cliente...");
    client.shutdown();
    print("Prueba completada con éxito.");
  } catch (e, stack) {
    print("❌ Error durante la prueba de inferencia:");
    print(e);
    print(stack);
    client.shutdown();
  }
}
