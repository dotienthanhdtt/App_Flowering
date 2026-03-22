# Phase 02 — Message Bubbles + Recording Bar

## Context Links
- Design: Pencil screens 08A (bubbles), 08C (recording), 08D (translation)
- Current files: `ai_message_bubble.dart`, `user_message_bubble.dart`, `text_action_button.dart`, `chat_recording_bar.dart`, `chat_waveform_bars.dart`

## Overview
- **Priority**: High
- **Status**: Complete
- Redesign AI bubble (remove avatar/Flora label, update shadow, action buttons below card with pill bg). Change user bubble color from orange to blue. Update recording bar button sizes to 48px and waveform to 39 bars.

## Key Insights
- AI bubble currently has "Flora" label inside — design removes it
- Action buttons (Translate/Play) move from inside card to below card with pill-shaped chip backgrounds
- User bubble switches from `primaryColor` (orange) to `secondaryColor` (blue)
- Voice message card is a new variant (blue card with play button + waveform + timer + transcription) — implement as future work unless backend supports it now
- Recording bar buttons increase from 36px to 48px circles

## Requirements

### Functional
- AI bubble: white card, cornerRadius 12, shadow (blur 4, #0000001A, offset y:1), padding 16, maxWidth 280
- AI bubble text: Inter 18px (`fontSizeLarge`), `textPrimaryColor`
- Translation inside card: divider + flag icon + translated text (08D)
- Action buttons below card: pill chips with icon + text, cornerRadius 8, padding [4,8], gap 16
- "Translate" button toggles to "Hide" when translation shown
- User bubble: blue (#0077BA `secondaryColor`), cornerRadius 12, padding 16, maxWidth 260
- User text: Inter 18px, white
- Grammar correction card: separate widget below user bubble (not inside), right-aligned
- Recording bar: cancel 48px circle, send 48px circle, 39 waveform bars

### Non-Functional
- Files under 200 lines
- Tappable words retained for word translation

## Related Code Files

### Files to Modify
1. `lib/features/chat/widgets/ai_message_bubble.dart` — remove Flora label, update card design, move actions outside
2. `lib/features/chat/widgets/user_message_bubble.dart` — change color to blue, remove embedded correction
3. `lib/features/chat/widgets/text_action_button.dart` — add pill background option
4. `lib/features/chat/widgets/chat_recording_bar.dart` — button sizes 36→48
5. `lib/features/chat/widgets/chat_waveform_bars.dart` — bar count 20→39, gap 2px

### Files to Create
- None

### Files to Delete
- None

## Implementation Steps

### Step 1: Update AiMessageBubble (`ai_message_bubble.dart`)

Remove:
- `AiAvatar` import and widget
- "Flora" label (`ai_name` text)
- Action buttons from inside the card Column

Update card decoration:
```dart
decoration: BoxDecoration(
  color: AppColors.surfaceColor,
  borderRadius: BorderRadius.circular(AppSizes.radiusM), // 12px all corners
  boxShadow: const [
    BoxShadow(
      color: Color(0x1A000000), // design: #0000001A
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ],
),
padding: EdgeInsets.all(AppSizes.space4), // 16px
```

Card content: just tappable text + optional translation section.

Translation section (08D):
```dart
if (showTranslation && translatedText != null) ...[
  Divider(height: 1, color: AppColors.infoColor), // #9CB0CF
  SizedBox(height: space3), // 12
  Row(children: [
    Icon(flag_or_translate, size: 16),
    SizedBox(width: 8),
    Expanded(AppText(translatedText, fontSize: fontSizeLarge, textPrimaryColor)),
  ]),
]
```

Action buttons below the card (outside Container):
```dart
SizedBox(height: 8),
Row(children: [
  TextActionButton(
    icon: translate,
    label: showTranslation ? 'Hide' : 'Translate',
    hasPillBackground: true, // new param
  ),
  SizedBox(width: 16),
  TextActionButton(
    icon: volume_up,
    label: 'Play',
    hasPillBackground: true,
  ),
]),
```

Overall structure becomes Column wrapping card + action row (not Row with avatar).

### Step 2: Update TextActionButton (`text_action_button.dart`)

Add pill background variant:
```dart
final bool hasPillBackground;

// In build:
Container(
  padding: hasPillBackground
    ? EdgeInsets.symmetric(horizontal: 8, vertical: 4)
    : EdgeInsets.zero,
  decoration: hasPillBackground
    ? BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0,1))],
      )
    : null,
  child: Row(icon + label),
)
```

### Step 3: Update UserMessageBubble (`user_message_bubble.dart`)

Changes:
- Color: `AppColors.secondaryColor` (blue #0077BA) instead of `primaryColor`
- BorderRadius: `BorderRadius.circular(AppSizes.radiusM)` (12px all corners)
- Text: fontSize `fontSizeLarge` (18px)
- Remove `GrammarCorrectionSection` from inside the bubble
- Remove `onToggleCorrection` callback

The grammar correction card will be rendered separately in the chat list (handled in Phase 03).

### Step 4: Update ChatRecordingBar (`chat_recording_bar.dart`)

Change cancel and send button sizes from 36 to 48:
```dart
// Cancel button
width: AppSizes.avatarXL, // 48
height: AppSizes.avatarXL, // 48

// Send button
width: AppSizes.avatarXL, // 48
height: AppSizes.avatarXL, // 48
```

Icon sizes stay at `iconSM` (16) — or increase to `iconXL` (24) per design.

### Step 5: Update ChatWaveformBars (`chat_waveform_bars.dart`)

- Change bar count: `List.generate(20, ...)` → `List.generate(39, ...)`
- Phase calc: `(i / 39 + _ctrl.value) % 1.0`
- Bar width: 3px (already correct)
- Gap: use `MainAxisAlignment.spaceEvenly` → may need to switch to fixed gap of 2px
- Height range: 6-26px → update formula: `6.0 + 20.0 * (0.5 + 0.5 * _sin(...))`

If 39 bars with 2px gap don't fit in `Expanded`, use `Row` with `mainAxisSize: min` or constrain:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(39, (i) {
    return Padding(
      padding: EdgeInsets.only(right: i < 38 ? 2 : 0),
      child: Container(width: 3, height: h, ...),
    );
  }),
)
```

Total width: 39*3 + 38*2 = 117+76 = 193px. Should fit in expanded area.

## Todo List

- [x] Update `ai_message_bubble.dart` — remove avatar/Flora, update card, actions below
- [x] Update `text_action_button.dart` — add pill background variant
- [x] Update `user_message_bubble.dart` — blue color, remove correction, radius 12
- [x] Update `chat_recording_bar.dart` — 48px buttons
- [x] Update `chat_waveform_bars.dart` — 39 bars, 2px gap, height 6-26px
- [x] Run `flutter analyze` to verify no errors

## Success Criteria

- AI bubbles: white card with shadow, no avatar, action pills below
- User bubbles: blue, 12px radius, no embedded correction
- Translation shows inside AI card with divider (08D)
- Recording bar has larger buttons and more waveform bars
- All files compile without errors

## Risk Assessment

- **Grammar correction removal from user bubble**: Must coordinate with Phase 03 where correction card renders separately in chat list. Temporary compile error if Phase 01 changes `GrammarCorrectionSection` API before Phase 02 removes it from `UserMessageBubble`. Mitigation: implement Phase 01 Step 2 and Phase 02 Step 3 together.
- **Voice message card**: Design 08A shows a blue voice-message card variant. This requires a new `ChatMessageType.userVoice` and is deferred unless backend supports it.

## Next Steps
- After this phase, proceed to Phase 03 for bottom sheet, context card, and screen integration
