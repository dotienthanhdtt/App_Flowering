import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env files
class EnvConfig {
  EnvConfig._();

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get env => dotenv.env['ENV'] ?? 'development';
  static bool get isDev => env == 'development';
  static bool get isProd => env == 'production';

  // RevenueCat API Keys
  static String get revenueCatAppleApiKey =>
      dotenv.env['REVENUECAT_APPLE_API_KEY'] ?? '';
  static String get revenueCatGoogleApiKey =>
      dotenv.env['REVENUECAT_GOOGLE_API_KEY'] ?? '';

  // Firebase
  static String get firebaseIosApiKey =>
      dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';
  static String get firebaseIosAppId => dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
  static String get firebaseIosClientId =>
      dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? '';
  static String get firebaseIosBundleId =>
      dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '';
  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String get firebaseAndroidAppId =>
      dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
  static String get firebaseAndroidClientId =>
      dotenv.env['FIREBASE_ANDROID_CLIENT_ID'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
}
