import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

 try {
   // Initialize Firebase
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );

   // Initialize Hive local storage
   await Hive.initFlutter();

   // Only the services required for the first frame + splash auth decision.
   // Non-critical services (audio, subscriptions, connectivity listeners)
   // are kicked off below after the first frame paints.
   await initializeCriticalServices();
 } catch (e) {
   e.printError();
 }

  runApp(const FloweringApp());

  // Defer non-critical init until after first frame to cut time-to-interactive.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initializeDeferredServices();
  });
}
