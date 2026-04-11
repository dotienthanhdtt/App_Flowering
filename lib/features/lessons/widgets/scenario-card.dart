import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/lesson-models.dart';

/// Scenario card matching design `ScenarioCard` in design.pen.
///
/// Layout: full-size background image, frosted gradient overlay at bottom
/// (level dots + title), optional status badge top-right.
///
/// Status behaviour:
/// - available / trial → normal card
/// - locked → semi-transparent dark overlay + lock badge
/// - learned → green check badge top-right
class ScenarioCard extends StatelessWidget {
  final LessonScenario scenario;
  final VoidCallback? onTap;

  const ScenarioCard({super.key, required this.scenario, this.onTap});

  // Design spec: 180×230, body overlay 90px from bottom
  static const double _aspectRatio = 180 / 230;
  static const double _bodyHeight = 90.0;
  static const double _badgeSize = 20.0;
  static const Color _learnedColor = Color(0xFF6BAF7A);
  static const Color _levelLabelColor = Color(0xFF9C9585);
  static const Color _dotEmpty = Color(0xFFE5DFC9);

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

  /// Frosted gradient overlay — matches design `Card3Body` gradient + blur.
  Widget _buildBodyOverlay() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00FFFFFF),
                Color(0x0AFFFFFF),
                Color(0x33FFFFFF),
                Color(0x80FFFFFF),
                Color(0xCCFFFFFF),
                Color(0xDDFFFFFF),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(AppSizes.radiusL),
              bottomRight: Radius.circular(AppSizes.radiusL),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLevelRow(),
              const SizedBox(height: 6),
              Text(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelRow() {
    final filledCount = _difficultyToFilled(scenario.difficulty);
    return Row(
      children: [
        const Text(
          'Level',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _levelLabelColor,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (i) => _buildDot(i < filledCount)),
      ],
    );
  }

  Widget _buildDot(bool filled) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.primaryColor : _dotEmpty,
        ),
      ),
    );
  }

  /// beginner=2, intermediate=3, advanced=5
  int _difficultyToFilled(String difficulty) {
    switch (difficulty) {
      case 'intermediate':
        return 3;
      case 'advanced':
        return 5;
      default:
        return 2; // beginner
    }
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
