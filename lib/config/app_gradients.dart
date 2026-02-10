import 'package:flutter/material.dart';
import 'theme.dart';

/// Gradient helper widgets and utilities for the Airmass Xpress design system
class AppGradients {
  AppGradients._();

  /// Brand gradient - primary use for splash and hero sections
  static const LinearGradient brand = AppTheme.brandGradient;

  /// Sunset gradient - for onboarding screens
  static const LinearGradient sunset = AppTheme.sunsetGradient;

  /// Warm gradient - for CTAs and accents
  static const LinearGradient warm = AppTheme.warmGradient;

  /// Night gradient - for dark backgrounds
  static const LinearGradient night = AppTheme.nightGradient;

  /// Overlay gradient - for text over images
  static const LinearGradient overlay = AppTheme.overlayGradient;

  /// Navy gradient - for professional/corporate sections
  static const LinearGradient navy = AppTheme.navyGradient;

  /// Premium shimmer gradient for loading states
  static LinearGradient shimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.neutral100,
      AppTheme.neutral200,
      AppTheme.neutral100,
    ],
  );
}

/// A container with a gradient background
class GradientContainer extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GradientContainer({
    super.key,
    required this.child,
    this.gradient = AppTheme.brandGradient,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// A button with a gradient background
class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.gradient = AppTheme.brandGradient,
    this.borderRadius = AppTheme.radiusMd,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTheme.buttonPaddingH,
      vertical: AppTheme.buttonPaddingV,
    ),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : null,
        color: onPressed == null ? AppTheme.neutral300 : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Full-screen gradient background
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient gradient;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient = AppTheme.sunsetGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}
