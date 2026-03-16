import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/main-shell-controller.dart';

/// Custom bottom navigation bar matching Pencil design
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainShellController>();

    return Container(
      height: AppSizes.navBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusXL),
          topRight: Radius.circular(AppSizes.radiusXL),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.borderLight, width: AppSizes.borderThin),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08191919),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: LucideIcons.messageCircle,
            label: 'nav_chat'.tr,
            isActive: controller.selectedIndex.value == 0,
            onTap: () => controller.changePage(0),
          ),
          _NavItem(
            icon: LucideIcons.bookOpen,
            label: 'nav_read'.tr,
            isActive: controller.selectedIndex.value == 1,
            onTap: () => controller.changePage(1),
          ),
          _NavItem(
            icon: LucideIcons.languages,
            label: 'nav_vocabulary'.tr,
            isActive: controller.selectedIndex.value == 2,
            onTap: () => controller.changePage(2),
          ),
          _NavItem(
            icon: LucideIcons.user,
            label: 'nav_profile'.tr,
            isActive: controller.selectedIndex.value == 3,
            onTap: () => controller.changePage(3),
          ),
        ],
      )),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textTertiary;
    final fontWeight = isActive ? FontWeight.w600 : FontWeight.w500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppSizes.navItemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppSizes.navIconSize, color: color),
            const SizedBox(height: AppSizes.navItemGap),
            AppText(
              label,
              variant: AppTextVariant.caption,
              fontSize: AppSizes.navFontSize,
              fontWeight: fontWeight,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
