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

  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScale;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Get It Done',
      description: 'Post any task. Find trusted professionals in your area. Get things done effortlessly.',
      icon: Icons.check_circle_outline_rounded,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF5A5F), Color(0xFFFF7E82), Color(0xFFE04850)],
      ),
    ),
    OnboardingPageData(
      title: 'Earn Money',
      description: 'Browse tasks near you. Make competitive offers. Build your reputation and grow your income.',
      icon: Icons.payments_outlined,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE04850), Color(0xFFFF5A5F), Color(0xFF1A2B4A)],
      ),
    ),
    OnboardingPageData(
      title: 'Safe & Secure',
      description: 'Protected payments. Verified professionals. Your satisfaction is guaranteed.',
      icon: Icons.shield_outlined,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A2B4A), Color(0xFF2E4A6F), Color(0xFFE04850)],
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  void _onSkip() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
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
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
            boxShadow: index == _currentPage
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
        _onNext();
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLastPage ? 'Get Started' : 'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _pages[_currentPage].gradient?.colors.first ??
                      AppTheme.primary,
                  letterSpacing: 0.3,
                ),
              ),
              if (isLastPage) ...[
                AppSpacing.hSm,
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _pages[_currentPage].gradient?.colors.first ??
                      AppTheme.primary,
                  size: 22,
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

  OnboardingPageData({
    required this.title,
    required this.description,
    this.icon,
    this.imagePath,
    this.gradient,
    this.backgroundColor,
  });
}
