import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Proveedor que obtiene la versión del aplicativo a nivel de plataforma nativa
/// usando package_info_plus.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return "${packageInfo.version}+${packageInfo.buildNumber}";
  } catch (e) {
    return 'unknown';
  }
});
