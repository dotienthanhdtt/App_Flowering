import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text.dart';
import '../models/onboarding_language_model.dart';
import 'language_card.dart';
import 'language_list_skeleton.dart';
import 'language_load_error.dart';

/// Common layout for language selection screens (native & learning).
///
/// Renders: [topBar] → title → [searchField] → language list → [bottomWidget].
class LanguageSelectionLayout extends StatelessWidget {
  final String title;
  final bool isLoading;
  final List<OnboardingLanguage> languages;
  final String? selectedCode;
  final void Function(OnboardingLanguage lang) onSelect;
  final VoidCallback onRetry;
  final double flagSize;
  final double cardPadding;
  final int skeletonCount;
  final Widget? topBar;
  final Widget? searchField;
  final Widget? bottomWidget;
  final Widget? listFooter;

  const LanguageSelectionLayout({
    super.key,
    required this.title,
    required this.isLoading,
    required this.languages,
    required this.selectedCode,
    required this.onSelect,
    required this.onRetry,
    this.flagSize = AppSizes.cardFlagSize,
    this.cardPadding = AppSizes.space3,
    this.skeletonCount = 8,
    this.topBar,
    this.searchField,
    this.bottomWidget,
    this.listFooter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar (back button or spacer)
        topBar ?? const SizedBox(height: AppSizes.buttonHeightMedium),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
          child: AppText(
            title,
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: AppSizes.trackingSnug,
            ),
            textAlign: TextAlign.left,
          ),
        ),

        const SizedBox(height: AppSizes.space6),

        // Search + language list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.space4),
            child: Column(
              children: [
                if (searchField != null) ...[
                  searchField!,
                  const SizedBox(height: AppSizes.space4),
                ],
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ),

        // Bottom widget (e.g. continue button)
        ?bottomWidget,
      ],
    );
  }

  Widget _buildList() {
    if (isLoading) return LanguageListSkeleton(itemCount: skeletonCount);
    if (languages.isEmpty) return LanguageLoadError(onRetry: onRetry);

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSizes.space8),
      itemCount: languages.length + (listFooter != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSizes.space2),
      itemBuilder: (context, index) {
        if (index == languages.length) return listFooter!;
        final lang = languages[index];
        return LanguageListCard(
          language: lang,
          isSelected: selectedCode == lang.code,
          flagSize: flagSize,
          cardPadding: cardPadding,
          onTap: () => onSelect(lang),
        );
      },
    );
  }
}