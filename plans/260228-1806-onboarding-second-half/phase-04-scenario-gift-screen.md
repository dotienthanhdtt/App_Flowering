# Phase 04 — Scenario Gift Screen (Screen 08)

## Overview
- **Priority:** P2
- **Status:** Completed
- **Effort:** 2h
- **Blocked by:** Phase 03

Build Screen 08 displaying 5 AI-generated personalized learning scenarios from `/onboarding/complete` response.

## Key Insights

- Data comes from `OnboardingController.onboardingProfile.scenarios[]` (set in Phase 03)
- 5 cards with color-coded accent icons using existing `AppColors.accent*` tokens
- Single CTA: "Start Practicing" → opens Login Gate bottom sheet (screen 09)
- No persistence needed — scenarios stored in controller state only
- Screen is display-only, no API calls

## Requirements

### Functional
- Display 5 scenario cards in a scrollable list
- Each card shows: icon, title, description with accent color
- Map `accentColor` string to `AppColors.accent*` constants
- CTA button at bottom opens Login Gate bottom sheet
- Back navigation returns to chat (with confirmation — progress will reset)

### Non-functional
- Smooth scroll performance
- Cards should have visual hierarchy (icon prominence, readable text)

## Related Code Files

### Create
- `lib/features/onboarding/views/scenario_gift_screen.dart` — main screen
- `lib/features/onboarding/widgets/scenario_card.dart` — individual scenario card

### Modify
- `lib/app/routes/app-page-definitions-with-transitions.dart` — already done in Phase 01

## Architecture

```
ScenarioGiftScreen (StatelessWidget)
  → OnboardingController.onboardingProfile.scenarios[]
  → ScenarioCard × 5
  → CTA Button → Get.toNamed(AppRoutes.onboardingLoginGate) or showModalBottomSheet
```

## Implementation Steps

### 1. Create ScenarioCard Widget

```dart
class ScenarioCard extends StatelessWidget {
  final Scenario scenario;

  Color _getAccentColor(String accent) {
    return switch (accent) {
      'blue' => AppColors.accentBlue,
      'green' => AppColors.accentGreen,
      'lavender' => AppColors.accentLavender,
      'rose' => AppColors.accentRose,
      _ => AppColors.primary,
    };
  }

  // Card layout: left accent icon circle + right title/description
  // 16px padding, 12px border radius, white surface background
  // Accent color used for icon background circle
}
```

### 2. Create ScenarioGiftScreen

```dart
class ScenarioGiftScreen extends StatelessWidget {
  final controller = Get.find<OnboardingController>();

  @override
  Widget build(BuildContext context) {
    final scenarios = controller.onboardingProfile?.scenarios ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: "Your Learning Scenarios" title
            // Subtitle: "Flora created these just for you"
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 24),
                itemCount: scenarios.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (_, i) => ScenarioCard(scenario: scenarios[i]),
              ),
            ),
            // Bottom CTA: "Start Practicing" button
            // Opens Login Gate bottom sheet
          ],
        ),
      ),
    );
  }
}
```

### 3. Login Gate Trigger

The CTA button calls:
```dart
onTap: () => _showLoginGate(context),

void _showLoginGate(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LoginGateBottomSheet(),
  );
}
```

This bottom sheet is built in Phase 05 — for now use a placeholder that navigates to signup.

## Todo List

- [ ] Create ScenarioCard widget with accent color mapping
- [ ] Create ScenarioGiftScreen with scrollable list + CTA
- [ ] Wire CTA to open Login Gate bottom sheet (placeholder initially)
- [ ] Add translation keys for header/subtitle/CTA
- [ ] Test with mock scenario data
- [ ] Run `flutter analyze`

## Success Criteria

- 5 scenario cards displayed with correct accent colors
- Cards scrollable when content overflows
- CTA button opens login gate flow
- Screen receives data from OnboardingController

## Risk Assessment

- **Empty scenarios list** → show fallback message "Your scenarios are being prepared"
- **Icon name mismatch** → use generic icon fallback if Lucide icon not found

## Next Steps

→ Phase 05: Auth Feature
