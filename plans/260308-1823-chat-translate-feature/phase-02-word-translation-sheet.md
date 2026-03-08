# Phase 02 — Word Translation Bottom Sheet UI

## Context Links
- Design: Pencil screen 08a
- Design system: `lib/core/constants/app_colors.dart`, `app_sizes.dart`, `app_text_styles.dart`
- Shared widgets: `lib/shared/widgets/`
- l10n: `lib/l10n/english-translations-en-us.dart`, `lib/l10n/vietnamese-translations-vi-vn.dart`

## Overview
- **Priority:** High
- **Status:** Pending
- **Description:** Build the word translation bottom sheet (design 08a) as a shared widget. Includes loading, error, and populated states.

## Key Insights
- Bottom sheet is reusable — place in `lib/shared/widgets/`
- Design specifies exact colors, sizes, spacing (documented in brainstorm)
- Must handle 3 states: loading, error, populated
- Audio play button is visual-only for now (TODO placeholder)

## Requirements

### Functional
- Drag handle at top (40x4 pill, #D4CEAE)
- Header row: word text (24px bold) + audio button (32x32, primarySoft bg) + close button (32x32, surfaceMuted bg)
- Pronunciation (14px, textTertiary) + POS badge (11px semibold, accentBlueDark/accentBlueLight pill)
- Divider (1px, borderLight)
- Translation section: languages icon + "Ban dich" label (accentBlue) + translation text (18px semibold)
- Definition section: label + text (14px, textSecondary, lineHeight 1.5)
- Examples section: label + card (radius 12, fill bg, padding 12) with italic example sentences
- Loading state: centered spinner
- Error state: error message with retry button

### Non-Functional
- Widget under 200 lines — split sections into private methods
- Uses existing `AppColors`, `AppSizes`, `GoogleFonts.outfit`
- All text labels use l10n keys

## Architecture

```
WordTranslationSheet (StatelessWidget)
  ├── _buildDragHandle()
  ├── _buildHeader(word, onClose, onPlayAudio)
  ├── _buildPronunciation(pronunciation, partOfSpeech)
  ├── _buildTranslation(translation)
  ├── _buildDefinition(definition)
  └── _buildExamples(examples)
```

The sheet receives a `WordTranslationModel?` (null = loading), an error string, and callbacks.

## Related Code Files

### Create
| File | Purpose |
|------|---------|
| `lib/shared/widgets/word-translation-sheet.dart` | Bottom sheet widget |

### Edit
| File | Change |
|------|--------|
| `lib/l10n/english-translations-en-us.dart` | Add translation keys |
| `lib/l10n/vietnamese-translations-vi-vn.dart` | Add translation keys |

## Implementation Steps

### 1. Add l10n keys
Add to both language files:

**English:**
```dart
'word_translation_title': 'Translation',
'word_definition_label': 'Definition',
'word_examples_label': 'Examples',
'word_translation_error': 'Could not load translation',
'word_translation_retry': 'Retry',
```

**Vietnamese:**
```dart
'word_translation_title': 'Ban dich',
'word_definition_label': 'Dinh nghia',
'word_examples_label': 'Vi du',
'word_translation_error': 'Khong the tai ban dich',
'word_translation_retry': 'Thu lai',
```

### 2. Create WordTranslationSheet
File: `lib/shared/widgets/word-translation-sheet.dart`

Constructor params:
```dart
class WordTranslationSheet extends StatelessWidget {
  final String word;
  final WordTranslationModel? data;   // null = loading
  final String? error;                 // non-null = error state
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final VoidCallback? onPlayAudio;     // TODO: wire later
}
```

Build method switches on state:
- `error != null` → error message + retry button
- `data == null` → loading spinner
- else → full content layout

### 3. Design spec mapping

| Design element | Implementation |
|---------------|----------------|
| Drag handle 40x4 pill #D4CEAE | `Container(w:40, h:4, decoration: BoxDecoration(color: Color(0xFFD4CEAE), borderRadius: 2))` |
| Word text 24px bold | `GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)` |
| Audio button 32x32 circle | `Container(w:32, h:32, decoration: BoxDecoration(color: AppColors.primarySoft, shape: circle))` with `Icons.volume_up` (Lucide volume-2 equivalent) |
| Close button 32x32 circle | `Container(w:32, h:32, decoration: BoxDecoration(color: AppColors.surfaceMuted, shape: circle))` with `Icons.close` size 16 |
| IPA 14px textTertiary | `GoogleFonts.outfit(fontSize: 14, color: AppColors.textTertiary)` |
| POS badge | `Container(padding: h8v4, decoration: BoxDecoration(color: AppColors.accentBlueLight, borderRadius: pill))` + `GoogleFonts.outfit(fontSize: 11, fontWeight: w600, color: AppColors.accentBlueDark)` |
| Divider | `Divider(height:1, color: AppColors.borderLight)` |
| Translation label | `Icon(Icons.language, size:14, color: AppColors.accentBlue)` + text 12px w600 accentBlue |
| Translation text | `GoogleFonts.outfit(fontSize: 18, fontWeight: w600, color: AppColors.textPrimary)` |
| Definition label | 12px w600 textTertiary |
| Definition text | 14px textSecondary lineHeight 1.5 |
| Examples label | 12px w600 textTertiary |
| Example card | `Container(decoration: BoxDecoration(color: AppColors.fill, borderRadius: 12), padding: 12)` with italic text |

### 4. Helper to show the sheet
Add a static method or top-level function:
```dart
static void show(BuildContext context, {required String word, ...}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: WordTranslationSheet(...),
    ),
  );
}
```

## Todo List
- [ ] Add l10n keys to both language files
- [ ] Create `WordTranslationSheet` widget with loading/error/populated states
- [ ] Match design 08a exactly (colors, sizes, spacing)
- [ ] Add static `show()` method for easy invocation
- [ ] Verify compilation with `flutter analyze`

## Success Criteria
- Sheet renders correctly in all 3 states (loading, error, populated)
- Visual match with design 08a
- Under 200 lines (split into helper methods if needed)
- `flutter analyze` passes

## Risk Assessment
| Risk | Mitigation |
|------|------------|
| AppColors may not have `accentBlueLight`/`accentBlueDark` | Check constants file; add if missing |
| `surfaceMuted` / `fill` colors may not exist | Check constants; use closest existing or add |
| Sheet too tall on small screens | Wrap content in `SingleChildScrollView`, use `isScrollControlled: true` |

## Next Steps
- Phase 03 wires this sheet to be shown on word tap in `AiMessageBubble`
