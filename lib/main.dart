import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/flowering-app-widget-with-getx.dart';
import 'app/global-dependency-injection-bindings.dart';
import 'config/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment configuration
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: '.env.$env');

  // Firebase is allowed to fail (emulator, network, missing config) — the app
  // still works without it, just without push/analytics.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('Firebase.initializeApp failed (non-fatal): $e\n$st');
    }
  }

  // Critical services MUST succeed. Swallowing their failure leaves GetX with
  // uninitialized services (e.g. StorageService._preferences) and produces
  // cryptic LateInitializationErrors downstream. Let the error propagate so
  // the platform crash reporter sees the real root cause.
  await initializeCriticalServices();

  runApp(const FloweringApp());

  // Defer non-critical init until after first frame to cut time-to-interactive.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initializeDeferredServices();
  });
}
