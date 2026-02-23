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
      decoration: const BoxDecoration(
        color: Colors.white, // White background
      ),
      child: Stack(
        children: [
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

                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildIllustration() {
    if (data.imagePath != null) {
      return SizedBox(
        height: 520,
        width: 350,
        child: Image.asset(
          data.imagePath!,
          fit: BoxFit.contain,
        ),
      );
    }

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
        // Description (Now acting as the main title)
        if (data.descriptionSpan != null)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.navy, // Navy Blue
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    letterSpacing: 0.2,
                  ),
              children: [data.descriptionSpan!],
            ),
          )
        else
          Text(
            data.description,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.navy, // Navy Blue
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                  letterSpacing: 0.2,
                ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
