import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../l10n/app-translations-loader.dart';
import 'routes/app-page-definitions-with-transitions.dart';
import 'global-dependency-injection-bindings.dart';

/// Main application widget with GetX configuration
///
/// Configures:
/// - Material theme with app colors
/// - GetX translations for EN/VI localization
/// - Route definitions and transitions
/// - Global dependency injection
/// - Smart management for auto-disposal
class FloweringApp extends StatelessWidget {
  const FloweringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flowering',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: _buildTheme(),

      // Localization setup
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),

      // Routing configuration
      initialRoute: AppPages.initialRoute,
      getPages: AppPages.pages,
      initialBinding: AppBindings(),

      // Smart management for automatic controller disposal
      smartManagement: SmartManagement.full,

      // Default page transitions
      defaultTransition: AppPages.defaultTransition,
      transitionDuration: AppPages.defaultDuration,
    );
  }

  /// Build Material3 theme with app colors
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surface,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}
