import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure bindings are ready.
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseInitialized = false;

  // ── 1. Initialize Firebase Safely ──────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── 2. Configure Crashlytics error handlers ──────────────────────────
    // Pass all uncaught Flutter framework errors to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    isFirebaseInitialized = true;
  } catch (e, stack) {
    // Print fallback error to local console.
    debugPrint("⚠️ Firebase initialization failed or platform not supported: $e");
    debugPrint(stack.toString());
  }

  // ── 3. Run app inside a guarded zone ───────────────────────────────────
  runZonedGuarded(
    () {
      runApp(
        const ProviderScope(
          child: MyApp(),
        ),
      );
    },
    (error, stack) {
      if (isFirebaseInitialized) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        debugPrint("❌ Uncaught error (Firebase not active): $error");
      }
    },
  );
}
