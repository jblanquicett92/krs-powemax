import 'dart:ffi' hide Size;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'app.dart';

// Desactiva el backend de GPU/Vulkan para WebGPU en Linux para evitar congelamientos en FFI
void _disableGpuOnLinux() {
  if (!Platform.isLinux) return;
  try {
    final libc = DynamicLibrary.open('libc.so.6');
    final setenv = libc.lookupFunction<
        Int32 Function(Pointer<Uint8> name, Pointer<Uint8> value, Int32 overwrite),
        int Function(Pointer<Uint8> name, Pointer<Uint8> value, int overwrite)
    >('setenv');
    final malloc = libc.lookupFunction<Pointer<Void> Function(IntPtr), Pointer<Void> Function(int)>('malloc');

    // Función auxiliar para convertir String a puntero nativo
    Pointer<Uint8> stringToNative(String s) {
      final units = s.codeUnits;
      final ptr = Pointer<Uint8>.fromAddress(malloc(units.length + 1).address);
      for (int i = 0; i < units.length; i++) {
        ptr[i] = units[i];
      }
      ptr[units.length] = 0; // Null terminator
      return ptr;
    }

    setenv(stringToNative('VK_ICD_FILENAMES'), stringToNative(''), 1);
    setenv(stringToNative('WGPU_BACKEND'), stringToNative('empty'), 1);
    print("Variables de entorno para CPU fallback configuradas en Linux.");
  } catch (e) {
    print("Advertencia: No se pudo configurar el CPU fallback nativo: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Deshabilitar la GPU para FFI en Linux antes de inicializar gemma
  _disableGpuOnLinux();
  
  try {
    await FlutterGemma.initialize();
    print("FlutterGemma inicializado correctamente.");
  } catch (e) {
    print("Error al inicializar FlutterGemma: $e");
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
