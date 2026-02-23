import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env files
class EnvConfig {
  EnvConfig._();

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get env => dotenv.env['ENV'] ?? 'development';
  static bool get isDev => env == 'development';
  static bool get isProd => env == 'production';
}
