import 'package:flutter/material.dart';
import '../onboarding_screen.dart';
import '../../../config/theme.dart';
import '../../../config/app_spacing.dart';

/// Individual onboarding page widget with immersive design
/// Features gradient overlay, bold typography, and subtle animations
class OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final int index;
  final double viewportFraction;

  const OnboardingPage({
    super.key,
    required this.data,
    this.index = 0,
    this.viewportFraction = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: data.gradient ?? AppTheme.sunsetGradient,
      ),
      child: Stack(
        children: [
          // Background pattern/illustration area
          Positioned.fill(
            child: _buildBackgroundDecoration(),
          ),

          // Gradient overlay for text legibility
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Illustration
                  _buildIllustration(),

                  const Spacer(flex: 1),

                  // Text content
                  _buildTextContent(context),

                  AppSpacing.vXxxl,
                  AppSpacing.vXxxl,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Stack(
      children: [
        // Floating circles for visual interest
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          top: 150,
          left: -80,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 2,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 280,
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            data.icon ?? Icons.star_rounded,
            size: 100,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(BuildContext context) {
    return Column(
      children: [
        // Title
        Text(
          data.title,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.2,
              ),
          textAlign: TextAlign.center,
        ),

        AppSpacing.vLg,

        // Description
        Text(
          data.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
                letterSpacing: 0.2,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
