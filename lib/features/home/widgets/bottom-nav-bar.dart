import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/main-shell-controller.dart';

/// Bottom navigation bar matching Pencil design (flowering_design.pen → BottomNavBar).
/// Flat container with 0.5px top border, 4 evenly distributed tabs, custom SVG icons.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  // Design border color is #E0E0E0 (not in AppColors token palette).
  static const Color _borderColor = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainShellController>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border(
          top: BorderSide(color: _borderColor, width: AppSizes.navBorderThickness),
        ),
      ),
      padding: const EdgeInsets.only(
        top: AppSizes.navTopPadding,
        bottom: AppSizes.navBottomPadding,
      ),
      child: Obx(() {
        final index = controller.selectedIndex.value;
        return Row(
          children: [
            Expanded(
              child: _NavItem(
                iconAsset: 'assets/icons/nav/chat.svg',
                label: 'nav_chat'.tr,
                isActive: index == 0,
                onTap: () => controller.changePage(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                iconAsset: 'assets/icons/nav/reading.svg',
                label: 'nav_read'.tr,
                isActive: index == 1,
                onTap: () => controller.changePage(1),
              ),
            ),
            Expanded(
              child: _NavItem(
                iconAsset: 'assets/icons/nav/vocab.svg',
                label: 'nav_vocabulary'.tr,
                isActive: index == 2,
                onTap: () => controller.changePage(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                iconAsset: 'assets/icons/nav/profile.svg',
                label: 'nav_profile'.tr,
                isActive: index == 3,
                onTap: () => controller.changePage(3),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconAsset,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Active = primary orange, inactive = neutral slate (matches design #FD9029 / #545F71).
    final color = isActive ? AppColors.primaryColor : AppColors.neutralColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSizes.navItemTopPadding,
          bottom: AppSizes.navItemBottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: AppSizes.navIconSize,
              height: AppSizes.navIconSize,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: AppSizes.navItemGap),
            AppText(
              label,
              variant: AppTextVariant.caption,
              fontSize: AppSizes.navFontSize,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
