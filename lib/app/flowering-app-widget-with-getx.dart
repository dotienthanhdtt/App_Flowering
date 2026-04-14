import 'package:flutter/foundation.dart';
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

      // Debug-only route logger — prints route changes to the console to make
      // navigation easier to trace during development.
      routingCallback: kReleaseMode
          ? null
          : (routing) {
              if (routing == null) return;
              debugPrint(
                '[ROUTE] ${routing.current}'
                '${routing.args != null ? '  args=${routing.args}' : ''}',
              );
            },
    );
  }

  /// Build Material3 theme with app colors
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryColor,
        primary: AppColors.primaryColor,
        secondary: AppColors.successColor,
        surface: AppColors.surfaceColor,
        error: AppColors.errorColor,
      ),
      scaffoldBackgroundColor: AppColors.backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceColor,
        foregroundColor: AppColors.textPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusM),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusL),
        ),
        color: AppColors.surfaceColor,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderColor,
        thickness: 1,
      ),
    );
  }
}
