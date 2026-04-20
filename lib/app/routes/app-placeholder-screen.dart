import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_sizes.dart';

/// Placeholder screen for initial setup — shown for routes not yet implemented
class AppPlaceholderScreen extends StatelessWidget {
  final String title;
  const AppPlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title - ${'coming_soon_suffix'.tr}',
              style: const TextStyle(fontSize: AppSizes.fontSizeLarge, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.space4),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: Text('go_back'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
