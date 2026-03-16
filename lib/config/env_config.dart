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
}
