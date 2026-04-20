import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/lesson-models.dart';

/// Scenario card matching design `QKWzO` (ScenarioCard) in flowering_design.pen.
///
/// Layout: full-size background image, frosted backdrop-blur panel at the
/// bottom with the scenario title only, optional status badge top-right.
///
/// Status behaviour:
/// - available / trial → normal card
/// - locked → semi-transparent dark overlay + lock badge
/// - learned → green check badge top-right
class ScenarioCard extends StatelessWidget {
  final LessonScenario scenario;
  final VoidCallback? onTap;

  const ScenarioCard({super.key, required this.scenario, this.onTap});

  // Design QKWzO: 180×230, body overlay 53px high, padding [10,12]
  static const double _aspectRatio = 180 / 230;
  static const double _bodyHeight = 53.0;
  static const double _badgeSize = 20.0;
  static const Color _learnedColor = Color(0xFF6BAF7A);

  @override
  Widget build(BuildContext context) {
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
              if (scenario.status == 'locked')
                Container(color: Colors.black.withValues(alpha: 0.35)),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: _bodyHeight,
                child: _buildBodyOverlay(),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _buildStatusBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (scenario.imageUrl != null && scenario.imageUrl!.isNotEmpty) {
      return Image.network(
        scenario.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _buildPlaceholder(),
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

  /// Frosted backdrop-blur panel — matches design `Card3Body`:
  /// transparent-cream tint (#FFFCFC00) + background_blur radius 20.
  /// A light tint is added over the blur so dark title text stays legible
  /// against busy images.
  Widget _buildBodyOverlay() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x66FFFCFC),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppSizes.radiusL),
              bottomRight: Radius.circular(AppSizes.radiusL),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            scenario.title,
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

  Widget _buildStatusBadge() {
    if (scenario.status == 'learned') {
      return _badge(_learnedColor, LucideIcons.check);
    }
    if (scenario.status == 'locked') {
      return _badge(Colors.white, LucideIcons.lock,
          iconColor: AppColors.textSecondaryColor);
    }
    return const SizedBox.shrink();
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
