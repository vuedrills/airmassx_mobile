import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/app_spacing.dart';
import 'widgets/onboarding_page.dart';

/// Award-winning onboarding screen with smooth animations
/// Inspired by AllTrails and Rocket Money
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScale;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Get Competitive Bids',
      description: 'Post your task and receive competitive bids from verified experts nearby.',
      imagePath: 'assets/images/onboarding_client.jpg',
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE04850), Color(0xFFFF5A5F)], // Red Gradient
      ),
      descriptionSpan: const TextSpan(
        children: [
          TextSpan(text: 'Post your task and receive competitive '),
          TextSpan(
            text: 'bids',
            style: TextStyle(
              color: Color(0xFFFF4848), // Bright Red
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' from verified experts nearby.'),
        ],
      ),
    ),
    OnboardingPageData(
      title: 'Find Clients',
      description: 'Receive SMS notifications when clients nearby request your services.',
      imagePath: 'assets/images/onboarding_professional.jpg',
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], // Royal Blue Gradient
      ),
      descriptionSpan: const TextSpan(
        children: [
          TextSpan(text: 'Receive '),
          TextSpan(
            text: 'SMS',
            style: TextStyle(
              color: Color(0xFFFF4848), // Bright Red
              fontWeight: FontWeight.w900,
            ),
          ),
          TextSpan(text: ' notifications when clients nearby request your services.'),
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _buttonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimController,
        curve: Curves.easeInOut,
      ),
    );

    // Start auto-play
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // Stop timer on last page
        _stopAutoPlay();
        // Option: Auto-navigate to login? User said: "automatically slide... and then show the signup page"
        // Let's hold on last page for a moment then navigate, or just stop. 
        // Given UX patterns, usually auto-play stops at end. 
        // But user request was specific: "automatically slide... and then show the signup page".
        // Let's navigate after a short delay on the last page.
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _currentPage == _pages.length - 1) {
            context.go('/home');
          }
        });
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    _buttonAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // If user manually swipes, we might want to reset the timer or stop it?
    // User didn't specify, but good UX is to pause/reset on interaction.
    // However, to strictly follow "slide after 2 seconds", we'll keep it running 
    // unless they are on last page.
  }

  void _onNext() {
    _stopAutoPlay(); // Stop auto-play if user interacts
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/home');
    }
  }

  void _onSkip() {
    _stopAutoPlay();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Stop auto-play on any tap down to allow user to read
        onTapDown: (_) => _stopAutoPlay(),
        child: Stack(
          children: [
            // PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return OnboardingPage(
                  data: _pages[index],
                  index: index,
                  viewportFraction: 1.0,
                );
              },
            ),

            // Skip button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: TextButton(
                onPressed: _onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54, // Darker text for white bg
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 16, // Slightly larger
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            // Bottom section with indicators and button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Page indicators
                      _buildPageIndicators(),

                      AppSpacing.vXl,

                      // Next/Get Started button
                      _buildNextButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == _currentPage ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == _currentPage
                ? AppTheme.primary
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLastPage = _currentPage == _pages.length - 1;

    return GestureDetector(
      onTapDown: (_) => _buttonAnimController.forward(),
      onTapUp: (_) {
        _buttonAnimController.reverse();
        _onNext(); // This handles navigation
      },
      onTapCancel: () => _buttonAnimController.reverse(),
      child: AnimatedBuilder(
        animation: _buttonScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _buttonScale.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLastPage ? 'Get Started' : 'Next',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (!isLastPage) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for onboarding pages
class OnboardingPageData {
  final String title;
  final String description;
  final IconData? icon;
  final String? imagePath;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final InlineSpan? descriptionSpan; // For rich text (e.g. bold/red SMS)

  OnboardingPageData({
    required this.title,
    required this.description,
    this.icon,
    this.imagePath,
    this.gradient,
    this.backgroundColor,
    this.descriptionSpan,
  });
}
