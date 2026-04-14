# Chat Screen Design Spec (Flowering)

> Source: Pencil `.pen` design file (batch_get dump at 15.5M chars).
> Extracted: 2026-04-14.
> Note: The frame literally named `09_chat_screen` in the dump is actually the **scenario-picker** screen (topic cards like "Ordering food at a restaurant"), not the chat conversation. The *actual chat conversation* screens live under IDs `08A..08E`. Both are documented below; the `08A..08E` set is what a Flutter "ChatScreen" should implement. `09_chat_screen` is the *entry screen* that precedes it.

---

## 1. Design Tokens (Global)

### 1.1 Colors

| Token | Hex | Usage |
|---|---|---|
| `$primary_color` | `#FD9029` | Orange — mic/send button, accents, waveform bars, fire/streak icon, bookmark, primary button text |
| `$secondary_color` | `#0077BA` | Blue — user message bubble background, translation icon/text color, `noun` tag label |
| `$warning_color` | `#FFB830` | Amber/gold — context card fill, audio button fill in bottom sheet |
| `$success_color` | `#60993E` | Green — not used on chat, validation |
| `$error_color` | `#E63950` | Red/pink — correction card stroke + sparkles icon + "Try this instead:" label, recording red-dot |
| `$surface_color` | `#FFFFFF` | White — top bar, bot message card, input bar, bottom sheet |
| `$background_color` | `#F9F7F2` | Warm off-white — screen background, input field fill, bottom sheet example card |
| `$neutral_color` | `#545F71` | Slate grey — back/more/translate/play icons + labels, body neutral text |
| `$info_color` | `#9CB0CF` | Light blue-grey — dividers, hairlines, placeholder text, position-tag bg, bottom-sheet handle pill |
| Literal `#1C1C1E` | — | Primary dark text (bot messages, user input typed text, headings inside sheet) |

### 1.2 Typography

Font family: **Inter** everywhere.

| Token | Size | Default weight seen |
|---|---|---|
| `$font-size-x-small` | 12 | 600 |
| `$font-size-small` | 14 | normal / 500 / 600 |
| `$font-size-base` | 14 | 500 / 600 (recording timer) |
| `$font-size-medium` | 16 | normal / 500 |
| `$font-size-large` | 18 | normal / 600 (button label) |
| `$font-size-x-large` | 20 | 600 (top-bar title, word translation) |
| `$font-size-2x-large` | 24 | 600 |
| `$font-size-3x-large` | 28 | 700 (bottom-sheet word headline) |

### 1.3 Spacing / Radius patterns

- Bubble corner radius: **12**
- Pill shapes (input field, mic button, audio button, cancel/send record): **999**
- Small chips (translate/play buttons, pos-tag): **8 / 6**
- Bottom sheet top corners: **24 / 24 / 0 / 0**
- Example card inside sheet: **8**
- Screen / status-bar padding: **16** horizontal
- Content padding inside bubbles: **16**
- Input bar padding: **12**
- Recording bar padding: **8 vertical, 12 horizontal**

### 1.4 Shadows

- Bot card: `blur:4, color:#0000001A (10%), offset:(0,1)` — soft downward
- User card (08A only): `blur:4, color:#00000040 (25%), offset:(0,4)` — stronger
- User card in later variants (08B, 08C, 08D, 08E): no shadow (flat secondary fill)
- Input field large: `blur:8, color:#0000000D, offset:(0,2)` (general component; not used on chat input)

---

## 2. Frame-level Info (all chat screens)

All chat screens are siblings with identical frame shell:

| Property | Value |
|---|---|
| `width` | **391** |
| `height` | **852** |
| `fill` | `$background_color` (#F9F7F2) |
| `clip` | true |
| `layout` | `vertical` |

Positions on canvas (side-by-side): 08A x=2602.94, 08B x=3027.43, 08C x=3451.92, 08D x=3876.41, 08E x=4300.90, all y=50.

### Top-level structure (top→bottom)

```
topBar              (h=56, fill surface, padding [0,16])
divider1            (h=1,  fill $info_color)
content             (flex, vertical, padding [10,16,8,16], gap 8/16)
  ├─ botMsg1   (bot bubble + actions row)
  ├─ userMsg1  (user bubble, right aligned)
  ├─ botMsg2   (bot bubble + actions row)
  └─ userMsg2  (voice card + correction card)
div2                (h=1,  fill $info_color)
inputBar OR recordingBar (h≈68 effective, fill surface, padding 12 / [8,12])
```

---

## 3. Top Bar (all variants)

| Prop | Value |
|---|---|
| height | 56 |
| fill | `$surface_color` (#FFFFFF) |
| padding | [0, 16] |
| alignItems | center |

Children:
- **backIcon** — lucide `arrow-left`, 24×24, fill `$neutral_color`
- **titleText** — "Coffee Chat ☕" (08B–08E) or "Coffee Chat" (08A), Inter 20/600, fill `#1C1C1E`, centered, `fill_container` width
- **moreIcon** (08E only) — lucide `ellipsis-vertical`, 24×24, fill `$neutral_color`

Below top bar: **divider1** — 1px rectangle, fill `$info_color` (#9CB0CF), full width.

---

## 4. Message Bubbles

### 4.1 Bot message (bot first turn — text)

- Container `botMsg1`: vertical layout, gap 4, width `fill_container`.
- **botCard1**
  - fill: `$surface_color` (#FFFFFF)
  - cornerRadius: 12
  - padding: 16
  - width: **280** (card 1) / **300** (card 2 — the longer one)
  - shadow: blur 4, color `#0000001A`, offset (0,1)
- **botText1** content (example): "Hi there! Welcome to Bean & Brew. What can I get for you today?"
  - Inter 18 (font-size-large), weight normal, fill `#1C1C1E`
- **botText2** content: "Sure! Would you like that hot or iced? And what size — small, medium, or large?"

Below the card, **botActions1** row — horizontal, gap 16, alignItems center:
- **trBtn1** — "Translate" chip: padding [4,8], cornerRadius 8, gap 4
  - icon: lucide `languages`, 16×16, `$neutral_color`
  - label: "Translate", Inter 14 (font-size-small), weight 500, `$neutral_color`
- **plBtn1** — "Play" chip: padding [4,8], cornerRadius 8, gap 4
  - icon: lucide `volume-2`, 16×16, `$neutral_color`
  - label: "Play", same style as above

### 4.2 User message (text)

- Container `userMsg1`: vertical, alignItems end (right-aligned), gap 4.
- **userCard1**
  - fill: `$secondary_color` (#0077BA)
  - cornerRadius: 12
  - padding: 16
  - width: **260**
  - **08A only:** shadow blur 4, color `#00000040`, offset (0,4). Other variants: flat (no shadow).
- **userTx1**: "Hi! Can I have a latte please?"
  - Inter 18 (font-size-large), weight normal, fill `$surface_color` (white on blue)

### 4.3 User message (voice + correction)

Container `userMsg2`: vertical, alignItems end, gap 8.

#### 4.3.1 voiceCard
- fill `$secondary_color` (#0077BA)
- cornerRadius 12, padding 16, gap 8, width **240**
- 08A: has shadow (same as user text bubble 08A). Other variants: flat.

Inner rows:

**voiceRow** (horizontal, alignItems center, gap 8, width fill_container)
- **playIc** — lucide `play`, 24×24, fill `$surface_color` (white)
- **waveform** frame (height 24, gap 2, fill_container width) — 15 rectangles of varying heights, each `width 3`, `cornerRadius 2`, fill `$primary_color` (#FD9029). Heights pattern: `[8,16,6,20,10,22,8,18,6,14,20,8,12,18,6]`
- **durTx** — "0:03", Inter 14 (font-size-small), fill `$surface_color`

**transTx** (below voiceRow)
- content: "I want a ice latte medium size."
- Inter 16 (font-size-medium), weight normal, fill `$surface_color` (white), width fill_container

#### 4.3.2 corrCard (grammar correction card)

Attached right under voiceCard, gap 8.

- fill `$surface_color` (#FFFFFF)
- cornerRadius 8
- padding 8
- gap 8
- width **240**
- stroke: inside, `$error_color` (#E63950), thickness 1
- Horizontal layout (icon + column):
  - **corrIc** — lucide `sparkles`, 16×16, fill `$error_color`
  - **corrCol** (vertical, gap 2, fill_container):
    - **corrLbl**: "Try this instead:", Inter 14 (font-size-small), weight 600, fill `$error_color`
    - **corrTxt**: "I'd like an iced latte, medium please.", Inter 16, weight 500, fill `#1C1C1E`

---

## 5. Content Layout

- `content` frame height: `fill_container`
- gap: **8** in 08A / 08C / 08D / 08E; **16** in 08B
- padding: `[10, 16, 8, 16]` (top, right, bottom, left); 08B uses `16` uniform
- layout: vertical
- Below content: **div2** — 1px rectangle, fill `$info_color`.

---

## 6. Input Bar — Default / Text states (08A, 08D, 08E)

Bottom-most bar (after div2):

- fill `$surface_color` (#FFFFFF)
- padding 12
- gap 8
- alignItems center
- horizontal layout (inputField + micBtn)

### 6.1 inputField (pill)

- height **44**
- cornerRadius **999**
- fill `$background_color` (#F9F7F2)
- padding `[0, 16]` horizontal
- stroke: inside 1px `$neutral_color` (not present in 08E)
- Contains **inputPh** text: "Type your message..." (08A/08D/08E) — Inter 16, normal, fill `$info_color` (placeholder)

### 6.2 micBtn (trailing circular button)

- width 44, height 44
- cornerRadius 999
- fill `$primary_color` (#FD9029)
- justifyContent center, alignItems center
- icon: lucide `mic`, 24×24, fill `$surface_color` (white)

---

## 7. Input Bar — Has Text state (08B)

Same pill container (44h, radius 999, stroke 1 `$neutral_color`) but:

- **inputPh** text becomes typed value: "I'd like a medium iced la..." — fill `#1C1C1E` (full-opacity), Inter 16 normal.
- inputField has no background_color fill (uses parent surface).
- Trailing button renamed **sendBtn** (still 44×44, cornerRadius 999, fill `$primary_color`).
- Icon inside sendBtn: lucide `send`, 24×24, fill `$surface_color`.

---

## 8. Recording Bar (08C — voice recording active)

Replaces the input bar entirely.

- fill `$surface_color`, padding `[8, 12]`, gap 10, alignItems center, horizontal.
- Four children in a row:

### 8.1 cancelBtn
- 48×48, cornerRadius 999, fill `$background_color` (#F9F7F2)
- Contains `cancelIcon` (lucide `x`) 24×24 at (x=12,y=12), fill `$neutral_color`

### 8.2 dotTimer
- horizontal, gap 6
- **redDot**: 8×8 ellipse, fill `$error_color` (#E63950)
- **timer** text: "0:03", Inter 14 (font-size-base), weight 600, fill `#1C1C1E`

### 8.3 waveform (live recording)
- height 28, gap 2, fill_container, justifyContent center
- 39 rectangles (w1..w39), each width 3, cornerRadius **1.5**, fill `$primary_color`
- Heights pattern: `[8,16,10,22,12,26,8,20,14,24,8,26,12,20,6,16,10,18,6,14,8,22,10,16,18,8,24,12,20,6,16,26,10,22,14,8,18,12,6]`

### 8.4 sendVoiceBtn
- 48×48, cornerRadius 999, fill `$primary_color`
- Contains `sendIcon` (lucide `send`) 24×24 at (x=12,y=12), fill `$surface_color`

---

## 9. Variant 08D — Bot Message Translated

Same shell as 08A, but **botCard1** is expanded:

- botCard1: same surface/radius 12/padding 16, **gap 12** (vertical layout), width 280, with the bot shadow.
- Children in botCard1:
  1. **botText1** (original, `#1C1C1E`, size 18 normal)
  2. **translationDivider** — 1px rectangle, fill `$info_color`
  3. **translationRow** — horizontal, gap 8:
     - **transIcon** — lucide `languages`, 16×16, fill `$secondary_color`
     - **translatedText** — "Xin chào! Chào mừng đến Bean & Brew. Hôm nay bạn muốn dùng gì?", Inter 16 (font-size-medium), normal, fill `$secondary_color` (#0077BA)

Also the botActions1 `trBtn1` changes:
- icon becomes lucide `eye-off` (not `languages`)
- label becomes **"Hide"** (instead of "Translate")

The rest of the screen (userMsg1, botCard2/botAct2 with plain "Translate/Play", voice+correction userMsg2, inputBar with mic) is identical to 08A.

---

## 10. Variant 08E — Word Tap Bottom Sheet

Everything from 08D is visible, PLUS:

### 10.1 Extra context card (at top of content, above botMsg1)

`contextCard`:
- cornerRadius 12
- fill `$warning_color` (#FFB830)
- padding 16, gap 8
- Horizontal row:
  - **ctxIcon** — lucide `message-circle`, 20×20, `$primary_color`
  - **ctxText**: "You're ordering coffee at a café. Try to ask for your drink and make small talk!", Inter 16, normal, `#1C1C1E`

### 10.2 Top bar gains moreIcon

Added trailing `ellipsis-vertical` icon (see §3).

### 10.3 Dim overlay
`dimOverlay`: rectangle 393×852 @ (0,0), fill `#00000066` (40% black) — sits above all chat content.

### 10.4 bottomSheet

Container:
- position: x=0, y=**472** (slides up from bottom)
- width **393**, height **380**
- fill `$surface_color` (#FFFFFF)
- cornerRadius `[24, 24, 0, 0]` (top-left, top-right, bottom-right, bottom-left)
- padding `[0, 24, 34, 24]` (top, right, bottom, left — bottom 34 for safe area)
- gap implied via spacer frames
- clip true, vertical layout

Children (top→bottom):

1. **handleBar** — height 28, centered
   - **handlePill** — 36×4 rectangle, cornerRadius 2, fill `$info_color` (#9CB0CF)

2. **wordRow** — horizontal, gap 8, fill_container
   - **wordCol** (vertical, gap 4, width 73):
     - **wordText**: "latte", Inter **28** (font-size-3x-large), weight **700**, fill `#1C1C1E`
     - **phoneticText**: "/ˈlɑː.teɪ/", Inter 16, normal, fill `$neutral_color`
   - **audioBtn** — 44×44, cornerRadius 999, fill `$warning_color` (#FFB830), contains `audioIcon` lucide `volume-2` 24×24 fill `$primary_color`
   - **closeBtn** — 28×28, cornerRadius 999, fill `$background_color`, absolutely positioned at (x=328, y=**-16**) — floats above sheet top edge; contains `closeIcon` lucide `x` 16×16 fill `$neutral_color`

3. **spacer1** — 12h

4. **posTag** (part-of-speech chip) — padding [2,8], cornerRadius 6, fill `$info_color`
   - **tagLabel**: "noun", Inter 14 (font-size-small), weight 500, fill `$secondary_color`

5. **spacer2** — 16h

6. **translationSection** (vertical, gap 4)
   - **transLabel**: "Translation", Inter 14, weight 600, fill `$neutral_color`
   - **transValue**: "cà phê sữa nóng kiểu Ý", Inter **20** (font-size-x-large), weight 600, fill `#1C1C1E`

7. **spacer3** — 16h

8. **exampleSection** (vertical, gap 4)
   - **exLabel**: "Example", Inter 14, weight 600, `$neutral_color`
   - **exCard** — cornerRadius 8, fill `$background_color`, padding 12
     - **exText**: `"Can I have a latte with oat milk?"`, Inter 16, normal, `#1C1C1E`

9. **spacer4** — `fill_container` (pushes button to bottom)

10. **saveBtn** — outline button
    - height 52, cornerRadius 12, gap 8, alignItems center, justifyContent center
    - stroke inside 1.5 `$primary_color` (no fill)
    - **btnIcon** — lucide `bookmark`, 20×20, fill `$primary_color`
    - **btnLabel**: "Save to My Words", Inter 18 (font-size-large), weight 600, fill `$primary_color`

---

## 11. The `09_chat_screen` Frame (scenario picker, NOT conversation)

For completeness — this is the screen users see **before** entering an 08-series chat. Width 393, height 800, background `$background_color`, vertical layout, padding for safe area.

Structure:
- **Status Bar** (h 8, padding [0,20])
- **Top Bar** (h 56, padding [0,20]):
  - Flag & Dropdown (Vietnamese flag 32×32 circle + lucide `chevron-down` 20×20 in `$text-primary`)
  - Streak chip (padding [8,12], cornerRadius 20, fill `$surface_color`, gap 6): flame icon 20×20 `$primary_color` + "12" Inter (font-size-medium)/700/`$primary_color`
- **Content Area** (h 650, gap 24, padding [0,0,24,0], clip)
  - Category List (gap 28, vertical)
    - **Category: Daily Life** — header "Daily Life" (Inter 18/700 `$text-primary`) + 3 cards horizontal row (gap 12, padding [0,20]): card1, card2 ("Ordering food at a restaurant"), card3 ("Shopping at the market"). Cards reference component `QKWzO` with image fills.
    - **Category: Travel & Transport** — card "Asking for directions" etc.
    - **Category: Food & Drink**
- **bottomNav2** (ref to shared bottom nav)

---

## 12. Icon References (all from `lucide` iconFontFamily)

`arrow-left`, `ellipsis-vertical`, `languages`, `volume-2`, `eye-off`, `sparkles`, `message-circle`, `mic`, `send`, `play`, `x`, `bookmark`, `chevron-down`, `chevron-right`, `flame`, `check`, `circle`.

---

## 13. Flutter Implementation Cheat Sheet

Direct mapping guidance:

- Screen scaffold: `backgroundColor: Color(0xFFF9F7F2)`, width target 391 (logical px), extendBodyBehindAppBar false.
- AppBar: custom 56h, white, 16 horizontal padding, `Icons.arrow_back` in `Color(0xFF545F71)`, center title "Coffee Chat ☕" `TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))`.
- Bot bubble: `Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0,1))]), constraints: BoxConstraints(maxWidth: 280 or 300))`.
- User text bubble: same but `color: Color(0xFF0077BA)`, max width 260; white text (18/normal). Voice variant width 240 with shadow `Color(0x40000000)` offset (0,4) *only* for initial state.
- Chip (translate/play): Row, `Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)))` — no fill — icon(16, Color(0xFF545F71)) + gap 4 + text(14, w500, Color(0xFF545F71)).
- Waveform: `Row(children: heights.map((h) => Container(width: 3, height: h.toDouble(), margin: EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: Color(0xFFFD9029), borderRadius: BorderRadius.circular(2))))`.
- Input bar: Row, padding 12, background white; `Expanded` pill (44h, radius 999, fill Color(0xFFF9F7F2), 1px Color(0xFF545F71) border, 16h padding, placeholder 16/Color(0xFF9CB0CF)), gap 8, trailing 44×44 circle `Color(0xFFFD9029)` with `Icons.mic` or `Icons.send` 24 white.
- Correction card: `Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(0xFFE63950), width: 1)))` — Row of sparkles icon 16 + Column (gap 2): "Try this instead:" (14/w600/#E63950) + corrected text (16/w500/#1C1C1E).
- Bottom sheet (Word tap): use `showModalBottomSheet(isScrollControlled: true, backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))))`, `SafeArea` bottom + 34 padding, height ~380; handle pill 36×4 `#9CB0CF`.

---

## Unresolved Questions

1. The raw dump doesn't expose the **content-area message list gap**'s actual rendered value for overflow — in practice the chat is scrollable; design file shows 4 messages static.
2. **Typing indicator** — not present in the 5 variants (A–E); design file appears to omit a "bot is typing" state. If needed, you'll have to invent consistent with `$neutral_color` dots in a `botCard1`-like container.
3. **Quick replies** — not present. No suggestion-chips above the input bar in any variant.
4. The user bubble shadow differs across variants (08A strong, 08B/C/D/E none). Intentional, or unresolved design regression? Unclear. Suggest picking one (likely "none" per the later variants).
5. The `09_chat_screen` frame is ambiguously named — it is a scenario/topic picker. Confirm with designer whether Flutter should call that screen `ChatScenariosScreen` and reserve `ChatScreen` for the 08A–E variants.
6. Exact icon bundle — `lucide` is referenced; the Flutter app will need `lucide_icons` package OR SVG assets. No custom icons found in dump.
