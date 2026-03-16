# Phase 4 — Language Selection Screens 2A/2B

**Priority:** High
**Status:** completed
**Effort:** Medium
**Depends on:** Phase 3

---

## Context

- Design nodes: `2ywmo` (Screen 2A — Native Language), `DHGCc` (Screen 2B — Learning Language)
- Mock data only — no API calls for language lists yet

## Overview

Implement native language list (2A) and learning language grid (2B). Create shared language model and reusable card widget. Pre-select Vietnamese (2A) and English (2B). Disabled languages show "Soon"/"Coming soon" badges.

## Language Mock Data

### Native Languages (2A — vertical list)

| Flag | Name | Subtitle | Enabled |
|------|------|----------|---------|
| 🇻🇳 | Tiếng Việt | Vietnamese | Yes (default selected) |
| 🇬🇧 | English | English | Yes |
| 🇯🇵 | 日本語 | Japanese | No — "Soon" |
| 🇰🇷 | 한국어 | Korean | No — "Soon" |
| 🇨🇳 | 中文 | Chinese | No — "Soon" |
| 🇪🇸 | Español | Spanish | No — "Soon" |
| 🇫🇷 | Français | French | No — "Soon" |

### Learning Languages (2B — 2-col grid)

| Flag | Name | Subtitle | Enabled |
|------|------|----------|---------|
| 🇬🇧 | English | The language to global citizen | Yes (default selected) |
| 🇯🇵 | Japanese | Coming soon | No |
| 🇰🇷 | Korean | Coming soon | No |
| 🇨🇳 | Chinese | Coming soon | No |
| 🇪🇸 | Spanish | Coming soon | No |
| 🇫🇷 | French | Coming soon | No |

## Implementation Steps

### 1. Create `onboarding_language_model.dart`

```dart
class OnboardingLanguage {
  final String code;
  final String flag;
  final String name;
  final String subtitle;
  final bool isEnabled;

  const OnboardingLanguage({
    required this.code,
    required this.flag,
    required this.name,
    required this.subtitle,
    this.isEnabled = false,
  });
}
```

Define two static lists: `nativeLanguages` and `learningLanguages`.

### 2. Create `onboarding_controller.dart`

```dart
class OnboardingController extends GetxController {
  final selectedNativeLanguage = 'vi'.obs;  // default Vietnamese
  final selectedLearningLanguage = 'en'.obs; // default English

  void selectNativeLanguage(String code) {
    selectedNativeLanguage.value = code;
    // Auto-advance to 2B after short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      Get.toNamed(AppRoutes.onboardingLearningLanguage);
    });
  }

  void selectLearningLanguage(String code) {
    selectedLearningLanguage.value = code;
    // Navigate to Screen 3 (AI Chat) after short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      Get.toNamed(AppRoutes.chat); // placeholder for Screen 3
    });
  }
}
```

### 3. Create `language_card.dart` widget

Reusable for both list (2A) and grid (2B) variants:

**List variant (2A):**
- Row: flag emoji (26px) + [name bold + subtitle small] + check circle (if selected)
- Height: 68, padding 16 horizontal, cornerRadius 16
- Selected: orange border (2px #FF7A27), orange bg (#FFEADB), orange check circle, shadow
- Unselected: white bg, #F0ECDA border (1px)
- Disabled: opacity 0.5, "Soon" badge (use existing Badge/Warning component style)

**Grid variant (2B):**
- Column: flag emoji (48px) + name (18px bold) + subtitle (11px)
- cornerRadius 16, padding 20
- Selected: orange border (2px #FF7A27), shadow
- Unselected: white bg, #F0ECDA border (1px)
- Disabled: opacity 0.5, "Coming soon" subtitle

Use an `isGridMode` param or create two separate methods.

### 4. Create `native_language_screen.dart` (Screen 2A)

Layout:
```
┌──────────────────────┐
│ [<] back button      │  ← chevron left, 40x40 rounded
├──────────────────────┤
│ "What's your native  │
│  language?"          │  ← 24px bold, center
│ subtitle             │  ← 14px, #5C5646, center
├──────────────────────┤
│ ┌──────────────────┐ │
│ │ 🇻🇳 Tiếng Việt ✓│ │  ← selected
│ └──────────────────┘ │
│ ┌──────────────────┐ │
│ │ 🇬🇧 English     │ │
│ └──────────────────┘ │
│ ┌──────────────────┐ │
│ │ 🇯🇵 日本語  Soon│ │  ← disabled
│ └──────────────────┘ │
│ ...                  │
└──────────────────────┘
```

- Background: #F8F4E3
- Header padding: top 56, horizontal 24, bottom 16
- List padding: horizontal 24, bottom 32
- List gap: 12
- Back button: chevron left icon in rounded container (40x40, white bg, #F0ECDA border)
- ListView for scrollable language cards
- Tapping enabled card → `controller.selectNativeLanguage(code)` → auto-advance to 2B

### 5. Create `learning_language_screen.dart` (Screen 2B)

Layout:
```
┌──────────────────────┐
│ "What do you want    │
│  to learn?"          │  ← 24px bold, center
│ subtitle             │  ← 14px, center
├──────────────────────┤
│ ┌────────┐ ┌────────┐│
│ │🇬🇧     │ │🇯🇵     ││
│ │English │ │Japanese││
│ │subtitle│ │Coming  ││
│ └────────┘ └────────┘│
│ ┌────────┐ ┌────────┐│
│ │🇰🇷     │ │🇨🇳     ││
│ └────────┘ └────────┘│
│ ...                  │
└──────────────────────┘
```

- Background: #F8F4E3
- Header padding: top 56, horizontal 24, bottom 24
- Grid: 2 columns, gap 16, horizontal padding 24
- Use `GridView.count(crossAxisCount: 2)` or `Wrap`
- Card height: auto (roughly 169px from design)
- Tapping enabled card → `controller.selectLearningLanguage(code)` → navigate to chat

### 6. Wire in `onboarding_binding.dart`

Ensure `OnboardingController` is available for both screens:
```dart
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
  }
}
```

Bind to all onboarding routes (welcome + language screens).

## Files Created

| File | Purpose |
|------|---------|
| `lib/features/onboarding/models/onboarding_language_model.dart` | Language data model + mock lists |
| `lib/features/onboarding/controllers/onboarding_controller.dart` | Selected language state + navigation |
| `lib/features/onboarding/widgets/language_card.dart` | Reusable language card (list + grid) |
| `lib/features/onboarding/views/native_language_screen.dart` | Screen 2A |
| `lib/features/onboarding/views/learning_language_screen.dart` | Screen 2B |

## Design Specs

| Element | Style |
|---------|-------|
| Background | #F8F4E3 |
| Title | Outfit, 24px, 700, #191919, letterSpacing -0.3, center |
| Subtitle | Outfit, 14px, 400, #5C5646, lineHeight 1.4, center |
| Card name (2A) | Outfit, 16px, 600, #191919 |
| Card subtitle (2A) | Outfit, 13px, 400, #5C5646 |
| Card name (2B) | Outfit, 18px, 700, #191919 |
| Card subtitle (2B) | Outfit, 11px, 400 or 500, #5C5646 or #9C9585 |
| Selected border | 2px #FF7A27 |
| Selected bg (2A only) | #FFEADB |
| Unselected border | 1px #F0ECDA |
| Disabled opacity | 0.5 |
| "Soon" badge | Use Badge/Warning style from design system |

## Todo

- [x] Create `onboarding_language_model.dart` with mock data
- [x] Create `onboarding_controller.dart`
- [x] Create `language_card.dart` (list + grid variants)
- [x] Create `native_language_screen.dart` (2A)
- [x] Create `learning_language_screen.dart` (2B)
- [x] Update `onboarding_binding.dart` if needed
- [x] Auto-advance on language selection
- [x] Visual match against design screenshots
- [x] `flutter analyze` passes

## Success Criteria

- 2A shows 7 languages in vertical list
- Vietnamese pre-selected with orange border + check
- Disabled langs at 0.5 opacity with "Soon" badge
- Tapping enabled lang → selects + auto-advances to 2B
- 2B shows 6 languages in 2-col grid
- English pre-selected with orange border
- Tapping enabled lang → selects + navigates to Screen 3 route
- Back navigation works (2B → 2A → 1C)
