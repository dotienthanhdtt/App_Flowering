/// Centralized design-token sizes used across the app.
class AppSizes {
  AppSizes._();

  // ═══════════════════════════════════════════════════════════════════
  // ── SPACING (Design Tokens) ──
  // Base unit: 4px
  // ═══════════════════════════════════════════════════════════════════
  static const double space0 = 0; // Reset
  static const double space1 = 4; // Tight gaps (icon-to-text, chip)
  static const double space2 = 8; // Inline spacing (badges, small gaps)
  static const double space3 = 12; // Input/compact card padding
  static const double space4 = 16; // Default content/card padding
  static const double space5 = 20; // Between form fields
  static const double space6 = 24; // Section gap inside screen
  static const double space8 = 32; // Between major sections
  static const double space10 = 40; // Screen top/bottom safe padding
  static const double space12 = 48; // Large section dividers
  static const double space16 = 64; // Hero/onboarding vertical spacing

  // ═══════════════════════════════════════════════════════════════════
  // ── FONT SIZES (Design Tokens) ──
  // ═══════════════════════════════════════════════════════════════════
  static const double fontSizeXSmall = 12; // Category labels, streak counters
  static const double fontSizeSmall = 14; // Captions, timestamps, hints
  static const double fontSizeBase = 14; // Button text, input labels, tabs
  static const double fontSizeMedium = 16; // Secondary text, descriptions
  static const double fontSizeLarge = 18; // Primary reading text, lesson content
  static const double fontSizeXLarge = 20; // Sub-sections, modal titles
  static const double fontSize2XLarge = 24; // Card titles, lesson names
  static const double fontSize3XLarge = 28; // Section headers
  static const double fontSize4XLarge = 32; // Screen titles
  static const double fontSize5XLarge = 48; // Splash screens, onboarding hero

  // ═══════════════════════════════════════════════════════════════════
  // ── LINE HEIGHTS (Design Tokens) ──
  // Values are TextStyle.height multipliers (designPx / fontSize)
  // ═══════════════════════════════════════════════════════════════════
  static const double lineHeightXSmall = 14 / 12; // 1.17 — 14px / fontSizeXSmall
  static const double lineHeightSmall = 16 / 14; // 1.14 — 16px / fontSizeSmall
  static const double lineHeightBase = 20 / 14; // 1.43 — 20px / fontSizeBase
  static const double lineHeightMedium = 20 / 16; // 1.25 — 20px / fontSizeMedium
  static const double lineHeightLarge = 24 / 18; // 1.33 — 24px / fontSizeLarge
  static const double lineHeightXLarge = 24 / 20; // 1.20 — 24px / fontSizeXLarge
  static const double lineHeight2XLarge = 28 / 24; // 1.17 — 28px / fontSize2XLarge
  static const double lineHeight3XLarge = 32 / 28; // 1.14 — 32px / fontSize3XLarge
  static const double lineHeight4XLarge = 36 / 32; // 1.13 — 36px / fontSize4XLarge
  static const double lineHeight5XLarge = 40 / 48; // 0.83 — 40px / fontSize5XLarge

  // ═══════════════════════════════════════════════════════════════════
  // ── BUTTON (Design Tokens) ──
  // ═══════════════════════════════════════════════════════════════════
  static const double buttonHeightLarge = 52;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightSmall = 36;
  static const double buttonRadiusLarge = 12;
  static const double buttonRadiusMedium = 10;
  static const double buttonRadiusSmall = 8;
  static const double buttonPaddingLarge = 24;
  static const double buttonPaddingMedium = 20;
  static const double buttonPaddingSmall = 16;
  static const double buttonFontLarge = 18;
  static const double buttonFontMedium = 14;
  static const double buttonFontSmall = 14;

  // ═══════════════════════════════════════════════════════════════════
  // ── INPUT FIELD (Design Tokens) ──
  // ═══════════════════════════════════════════════════════════════════
  static const double inputFieldHeight = 64;
  static const double inputFieldRadius = 16;
  static const double inputFieldPaddingV = 12;
  static const double inputFieldPaddingH = 16;
  static const double inputFieldGap = 4;
  static const double inputLabelFont = 12;
  static const double inputTextFont = 14;
  static const double inputIconSize = 20;
  static const double inputBorderWidth = 1;

  // ═══════════════════════════════════════════════════════════════════
  // ── CARD (Design Tokens — Language Card) ──
  // ═══════════════════════════════════════════════════════════════════
  static const double cardRadius = 12;
  static const double cardPadding = 16;
  static const double cardGap = 16;
  static const double cardFlagSize = 36;
  static const double cardFlagSizeLarge = 48;
  static const double cardTitleFont = 16;
  static const double cardSubtitleFont = 14;
  static const double cardChevronSize = 20;
  static const double cardBorderWidth = 1;

  // ═══════════════════════════════════════════════════════════════════
  // ── BORDER RADIUS ──
  // ═══════════════════════════════════════════════════════════════════
  static const double radiusXXS = 2;
  static const double radiusXS = 4;
  static const double radiusS = 6;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;
  static const double radiusPill = 100;

  // ── Border Width ──
  static const double borderThin = 1;
  static const double borderMedium = 1.5;

  // ═══════════════════════════════════════════════════════════════════
  // ── ICON SIZES ──
  // ═══════════════════════════════════════════════════════════════════
  static const double iconXXS = 12;
  static const double iconXS = 14;
  static const double iconSM = 16;
  static const double iconM = 18;
  static const double iconL = 20;
  static const double iconXL = 24;
  static const double iconXXL = 32;
  static const double icon3XL = 48;
  static const double icon4XL = 64;

  // ═══════════════════════════════════════════════════════════════════
  // ── OTHER COMPONENT SIZES ──
  // ═══════════════════════════════════════════════════════════════════
  static const double topBarHeight = 56;
  static const double navBarHeight = 80;
  static const double navIconSize = 22;
  static const double navFontSize = 10;
  static const double navItemWidth = 64;
  static const double navItemGap = 4;
  static const double avatarS = 24;
  static const double avatarM = 32;
  static const double avatarXL = 48;

  // ── Letter Spacing ──
  static const double trackingSnug = -0.3;
}
