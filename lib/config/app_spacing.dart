import 'package:flutter/material.dart';
import 'theme.dart';

/// Spacing utilities for the Airmass Xpress design system
/// Based on a 4px base unit for consistent spacing throughout the app
class AppSpacing {
  AppSpacing._();

  // ============================================================
  // SPACING SCALE
  // ============================================================

  static const double xs = AppTheme.spaceXs;   // 4px
  static const double sm = AppTheme.spaceSm;   // 8px
  static const double md = AppTheme.spaceMd;   // 12px
  static const double lg = AppTheme.spaceLg;   // 16px
  static const double xl = AppTheme.spaceXl;   // 24px
  static const double xxl = AppTheme.space2xl; // 32px
  static const double xxxl = AppTheme.space3xl; // 48px
  static const double xxxxl = AppTheme.space4xl; // 64px

  // ============================================================
  // LAYOUT CONSTANTS
  // ============================================================

  /// Horizontal page margin
  static const double pageMarginH = AppTheme.pageMarginH; // 20px

  /// Vertical page margin
  static const double pageMarginV = AppTheme.pageMarginV; // 16px

  /// Card internal padding
  static const double cardPadding = AppTheme.cardPadding; // 16px

  // ============================================================
  // EDGE INSETS
  // ============================================================

  /// Page padding (horizontal only)
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(
    horizontal: pageMarginH,
  );

  /// Page padding (all sides)
  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: pageMarginH,
    vertical: pageMarginV,
  );

  /// Card padding
  static const EdgeInsets card = EdgeInsets.all(cardPadding);

  /// List item padding
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Button padding
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: AppTheme.buttonPaddingH,
    vertical: AppTheme.buttonPaddingV,
  );

  /// Small padding
  static const EdgeInsets small = EdgeInsets.all(sm);

  /// Medium padding
  static const EdgeInsets medium = EdgeInsets.all(md);

  /// Large padding
  static const EdgeInsets large = EdgeInsets.all(lg);

  /// Extra large padding
  static const EdgeInsets extraLarge = EdgeInsets.all(xl);

  // ============================================================
  // GAP WIDGETS
  // ============================================================

  /// Vertical gap widgets
  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
  static const SizedBox vXxl = SizedBox(height: xxl);
  static const SizedBox vXxxl = SizedBox(height: xxxl);

  /// Horizontal gap widgets
  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
  static const SizedBox hXl = SizedBox(width: xl);
  static const SizedBox hXxl = SizedBox(width: xxl);

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Creates a vertical gap of specified height
  static SizedBox vertical(double height) => SizedBox(height: height);

  /// Creates a horizontal gap of specified width
  static SizedBox horizontal(double width) => SizedBox(width: width);

  /// Creates symmetric padding
  static EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);

  /// Creates padding for all sides
  static EdgeInsets all(double value) => EdgeInsets.all(value);
}

/// Border radius utilities
class AppRadius {
  AppRadius._();

  static const double xs = AppTheme.radiusXs;     // 4px
  static const double sm = AppTheme.radiusSm;     // 8px
  static const double md = AppTheme.radiusMd;     // 12px
  static const double lg = AppTheme.radiusLg;     // 16px
  static const double xl = AppTheme.radiusXl;     // 24px
  static const double full = AppTheme.radiusFull; // 999px (pills, avatars)

  /// Pre-made BorderRadius values
  static final BorderRadius xsAll = BorderRadius.circular(xs);
  static final BorderRadius smAll = BorderRadius.circular(sm);
  static final BorderRadius mdAll = BorderRadius.circular(md);
  static final BorderRadius lgAll = BorderRadius.circular(lg);
  static final BorderRadius xlAll = BorderRadius.circular(xl);
  static final BorderRadius fullAll = BorderRadius.circular(full);

  /// Top only border radius
  static final BorderRadius topMd = BorderRadius.vertical(top: Radius.circular(md));
  static final BorderRadius topLg = BorderRadius.vertical(top: Radius.circular(lg));
  static final BorderRadius topXl = BorderRadius.vertical(top: Radius.circular(xl));

  /// Bottom only border radius
  static final BorderRadius bottomMd = BorderRadius.vertical(bottom: Radius.circular(md));
  static final BorderRadius bottomLg = BorderRadius.vertical(bottom: Radius.circular(lg));
}
