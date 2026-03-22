import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/scenario_model.dart';

/// Lesson card matching Pencil Card3 component:
/// Image background (230px, 16px radius, clipped) + frosted glass body overlay
/// (90px, multi-stop gradient, background blur) with level dots + title.
/// Optional green learned badge with check icon at top-right.
class ScenarioCard extends StatelessWidget {
  final Scenario scenario;

  const ScenarioCard({super.key, required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _CardBody(scenario: scenario),
          if (scenario.learned) const _LearnedBadge(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (scenario.imageUrl != null && scenario.imageUrl!.isNotEmpty) {
      return Image.network(
        scenario.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _PlaceholderBg(scenario: scenario),
      );
    }
    return _PlaceholderBg(scenario: scenario);
  }
}

/// Frosted glass body overlay at bottom with gradient + blur.
class _CardBody extends StatelessWidget {
  final Scenario scenario;

  const _CardBody({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 90,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSizes.radiusL),
          bottomRight: Radius.circular(AppSizes.radiusL),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.1, 0.2, 0.3, 0.45, 0.6, 0.75, 0.9, 1.0],
                colors: [
                  Color(0x00FFFFFF),
                  Color(0x0AFFFFFF),
                  Color(0x1AFFFFFF),
                  Color(0x33FFFFFF),
                  Color(0x55FFFFFF),
                  Color(0x80FFFFFF),
                  Color(0xAAFFFFFF),
                  Color(0xCCFFFFFF),
                  Color(0xDDFFFFFF),
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _LevelDots(level: scenario.level),
                const SizedBox(height: 6),
                AppText(
                  scenario.title,
                  variant: AppTextVariant.bodyMedium,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Green circle badge with white check icon — shown when scenario is learned.
class _LearnedBadge extends StatelessWidget {
  const _LearnedBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      top: 8,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.successColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: AppSizes.iconXXS,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Level dots indicator: "Level" label + 5 dots (filled orange or border-light).
class _LevelDots extends StatelessWidget {
  final int level;

  const _LevelDots({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(
          'scenario_level'.tr,
          variant: AppTextVariant.caption,
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(width: 6),
        ...List.generate(5, (i) {
          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i < level ? AppColors.primaryColor : AppColors.borderLightColor,
              shape: BoxShape.circle,
            ),
          );
        }),
      ],
    );
  }
}

/// Colored placeholder with emoji when no image is available.
class _PlaceholderBg extends StatelessWidget {
  final Scenario scenario;

  const _PlaceholderBg({required this.scenario});

  Color _accentLightColor() => switch (scenario.accentColor) {
        'blue' => AppColors.secondaryLightColor,
        'green' => AppColors.successLightColor,
        'lavender' => AppColors.lavenderLightColor,
        'rose' => AppColors.roseLightColor,
        _ => AppColors.primarySoftColor,
      };

  String _iconEmoji() => switch (scenario.icon) {
        'briefcase' => '💼',
        'plane' => '✈️',
        'music' => '🎵',
        'book' => '📖',
        'heart' => '❤️',
        'globe' => '🌍',
        'camera' => '📷',
        'coffee' => '☕',
        'star' => '⭐',
        'zap' => '⚡',
        'award' => '🏆',
        'users' => '👥',
        'mic' => '🎙️',
        'tv' => '📺',
        'shopping-bag' => '🛍️',
        _ => '📚',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _accentLightColor(),
      child: Center(
        child: Text(
          _iconEmoji(),
          style: const TextStyle(fontSize: AppSizes.fontSize3XLarge),
        ),
      ),
    );
  }
}
