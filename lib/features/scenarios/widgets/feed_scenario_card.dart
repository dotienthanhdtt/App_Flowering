import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/scenario_access_tier.dart';
import '../models/scenario_feed_item.dart';
import '../models/scenario_user_status.dart';
import 'access_tier_badge.dart';

/// Scenario card for the Flowering (default) tab.
///
/// Layout: full-bleed image + frosted title overlay at the bottom.
/// Top-left: PRO pill when `accessTier == premium`.
/// Top-right: status badge (check for learned, lock + dark overlay for locked).
class FeedScenarioCard extends StatelessWidget {
  final ScenarioFeedItem item;
  final VoidCallback? onTap;

  const FeedScenarioCard({super.key, required this.item, this.onTap});

  static const double _aspectRatio = 180 / 230;
  static const double _bodyHeight = 53.0;
  static const double _badgeSize = 20.0;
  static const Color _learnedColor = Color(0xFF6BAF7A);

  @override
  Widget build(BuildContext context) {
    final isLocked = item.status == ScenarioUserStatus.locked;

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(),
              if (isLocked) Container(color: Colors.black.withValues(alpha: 0.35)),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: _bodyHeight,
                child: _buildTitleOverlay(),
              ),
              if (item.accessTier == ScenarioAccessTier.premium)
                Positioned(
                  top: 8,
                  left: 8,
                  child: AccessTierBadge(tier: item.accessTier),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: _buildStatusBadge(item.status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    final url = item.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceMutedColor,
      child: const Icon(
        LucideIcons.image,
        color: AppColors.textTertiaryColor,
        size: AppSizes.iconXXL,
      ),
    );
  }

  Widget _buildTitleOverlay() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0x66FFFCFC),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(AppSizes.radiusL),
              bottomRight: Radius.circular(AppSizes.radiusL),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryColor,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  /// `learned` wins if somehow both states are set — explicit precedence.
  Widget _buildStatusBadge(ScenarioUserStatus status) {
    switch (status) {
      case ScenarioUserStatus.learned:
        return _badge(_learnedColor, LucideIcons.check);
      case ScenarioUserStatus.locked:
        return _badge(
          Colors.white,
          LucideIcons.lock,
          iconColor: AppColors.textSecondaryColor,
        );
      case ScenarioUserStatus.available:
        return const SizedBox.shrink();
    }
  }

  Widget _badge(Color bg, IconData icon, {Color iconColor = Colors.white}) {
    return Container(
      width: _badgeSize,
      height: _badgeSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: AppSizes.iconXXS, color: iconColor),
    );
  }
}
