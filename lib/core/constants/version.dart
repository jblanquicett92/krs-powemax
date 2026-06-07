import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proveedor que lee y extrae dinámicamente la versión directamente del
/// archivo pubspec.yaml incluido como asset de la aplicación.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    debugPrint("[VersionProvider] Intentando cargar el asset 'assets/pubspec.yaml'...");
    final content = await rootBundle.loadString('assets/pubspec.yaml');
    debugPrint("[VersionProvider] assets/pubspec.yaml cargado con éxito. Longitud: ${content.length} caracteres.");
    
    final match = RegExp(r'^version:\s*([^\s#]+)', multiLine: true).firstMatch(content);
    if (match != null) {
      final version = match.group(1)?.trim();
      debugPrint("[VersionProvider] Versión encontrada en regexp: '$version'");
      return version ?? 'unknown';
    } else {
      debugPrint("[VersionProvider] ADVERTENCIA: No se encontró la clave 'version:' en pubspec.yaml");
      // Imprimimos las primeras líneas para ver si tiene otro formato o cargó un archivo incorrecto
      final lines = content.split('\n').take(10).join('\n');
      debugPrint("[VersionProvider] Primeras 10 líneas de pubspec.yaml cargado:\n$lines");
      return 'unknown';
    }
  } catch (e, stack) {
    debugPrint("[VersionProvider] ERROR al leer pubspec.yaml: $e");
    debugPrint("[VersionProvider] StackTrace:\n$stack");
    rethrow;
  }
});
