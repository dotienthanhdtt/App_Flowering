import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../controllers/profile-controller.dart';

/// Profile tab — user info, stats, settings, logout.
/// Tab child screen — exempt from BaseScreen to avoid nested Scaffold.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.spacingXXL),
            _buildUserHeader(controller),
            const SizedBox(height: AppSizes.spacingXXL),
            _buildStatsRow(),
            const SizedBox(height: AppSizes.spacingXXL),
            _buildSettingsSection(),
            const SizedBox(height: AppSizes.spacing4XL),
            _buildLogoutButton(controller),
            const SizedBox(height: AppSizes.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(ProfileController controller) {
    return Column(
      children: [
        CircleAvatar(
          radius: AppSizes.avatarXL / 2,
          backgroundColor: AppColors.primarySoftColor,
          child: const Icon(
            LucideIcons.user,
            size: AppSizes.iconXXL,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: AppSizes.spacingM),
        Obx(() => AppText(
          controller.userName.value.isEmpty
              ? 'my_profile'.tr
              : controller.userName.value,
          variant: AppTextVariant.h3,
        )),
        const SizedBox(height: AppSizes.spacingXS),
        Obx(() => AppText(
          controller.userEmail.value,
          variant: AppTextVariant.caption,
        )),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(label: 'streak'.tr, value: '0'),
        _StatItem(label: 'words_learned'.tr, value: '0'),
        _StatItem(label: 'accuracy'.tr, value: '0%'),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('settings'.tr, variant: AppTextVariant.h3),
        const SizedBox(height: AppSizes.spacingM),
        _SettingsRow(icon: LucideIcons.globe, label: 'language'.tr),
        _SettingsRow(icon: LucideIcons.bell, label: 'notifications'.tr),
        _SettingsRow(icon: LucideIcons.info, label: 'about'.tr),
      ],
    );
  }

  Widget _buildLogoutButton(ProfileController controller) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: controller.logout,
        icon: const Icon(LucideIcons.logOut, size: AppSizes.iconL),
        label: AppText('logout'.tr, color: AppColors.errorColor),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.errorColor,
          side: const BorderSide(color: AppColors.errorColor),
          padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText(value, variant: AppTextVariant.h3, color: AppColors.primaryColor),
        const SizedBox(height: AppSizes.spacingXS),
        AppText(label, variant: AppTextVariant.caption),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SettingsRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondaryColor, size: AppSizes.iconL),
      title: AppText(label, variant: AppTextVariant.bodyMedium),
      trailing: const Icon(
        LucideIcons.chevronRight,
        color: AppColors.textTertiaryColor,
        size: AppSizes.iconL,
      ),
      onTap: () {},
    );
  }
}
