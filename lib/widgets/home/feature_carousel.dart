import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../screens/tasks/create_task_screen.dart';
import '../../models/ad.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../screens/projects/post_project_screen.dart';
import '../../screens/equipment/post_equipment_request_screen.dart';

class FeatureCarousel extends StatefulWidget {
  final List<Ad>? ads;
  final int tabIndex;
  const FeatureCarousel({super.key, this.ads, this.tabIndex = 0});

  @override
  State<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends State<FeatureCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<Map<String, dynamic>> _getDefaultFeatures() {
    return [
      {
        'title': 'Your Home, Sorted',
        'subtitle': 'Expert help for every task',
        'button': 'Post a Task',
        'colors': [const Color(0xFF1A1A4E), const Color(0xFF2D2D7A)],
        'icon': Icons.home_repair_service_outlined,
        'action': 'app://create-task',
      },
      {
        'title': 'Top-Rated Pros',
        'subtitle': 'Verified experts ready to help',
        'button': 'Consult a Pro',
        'colors': [const Color(0xFFA42444), const Color(0xFFC93D5E)],
        'icon': LucideIcons.shieldCheck,
        'action': 'app://create-project',
      },
      {
        'title': 'Solar Deals',
        'subtitle': 'Get equipment for your site',
        'button': 'Request Equipment',
        'colors': [const Color(0xFF0A5C36), const Color(0xFF0D7A48)],
        'icon': Icons.solar_power_outlined,
        'action': 'app://create-equipment-request',
      },
      {
        'title': 'Construction Experts',
        'subtitle': 'Build your dream project',
        'button': 'Find a Contractor',
        'colors': [const Color(0xFFEAA300), const Color(0xFFC48200)],
        'icon': Icons.engineering_outlined,
        'action': 'app://create-project',
      },
    ];
  }

  List<dynamic> get _features {
    final defaults = _getDefaultFeatures();
    final List<dynamic> combinedFeatures = List.from(defaults);

    if (widget.ads != null && widget.ads!.isNotEmpty) {
      final bannerAds = widget.ads!.where((ad) => ad.placement == 'notice_board').toList();
      
      // Merge ads into the defaults based on index
      for (int i = 0; i < combinedFeatures.length; i++) {
        if (i < bannerAds.length) {
          combinedFeatures[i] = bannerAds[i];
        }
      }
    }
    return combinedFeatures;
  }

  @override
  void initState() {
    super.initState();
    // Default to the correct page for the tab
    _currentIndex = _getInitialIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
      _trackCurrentAdImpression();
    });
  }

  int _getInitialIndex() {
    final features = _features;
    // If we have ads, default to tabIndex (assuming 1:1 mapping is desired) 
    // or start at 0? The original logic was strict:
    // "If we have ads, start at 0. If defaults, start at tabIndex."
    // But since we are enforcing context per tab, we should respect tabIndex even for Ads
    // provided the list represents the tabs.
    if (widget.tabIndex < features.length) return widget.tabIndex;
    return 0;
  }

  @override
  void didUpdateWidget(FeatureCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) {
      final features = _features;
      // Scroll to the index matching the tab
      if (widget.tabIndex < features.length) {
        _pageController.animateToPage(
          widget.tabIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  void _trackCurrentAdImpression() {
    final features = _features;
    if (_currentIndex < features.length && features[_currentIndex] is Ad) {
      final ad = features[_currentIndex] as Ad;
      getIt<ApiService>().trackAdImpression(ad.id);
    }
  }

  void _onAction(dynamic feature, String? overrideAction) {
    String urlString;
    
    // Use override action if provided
    if (overrideAction != null) {
      urlString = overrideAction;
      if (feature is Ad) {
         getIt<ApiService>().trackAdClick(feature.id);
      }
    } else {
      if (feature is Ad) {
        getIt<ApiService>().trackAdClick(feature.id);
        urlString = feature.actionUrl;
      } else {
        urlString = feature['action'] ?? 'app://create-task';
      }
    }
    
    // Handle internal app links
    if (urlString.startsWith('app://')) {
      if (urlString == 'app://create-task') {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateTaskScreen(),
          ),
        );
      } else if (urlString == 'app://create-project') {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PostProjectScreen(),
          ),
        );
      } else if (urlString == 'app://create-equipment-request') {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PostEquipmentRequestScreen(),
          ),
        );
      }
      return;
    }

    final Uri url = Uri.parse(urlString);
    launchUrl(url).catchError((e) {
      debugPrint('Could not launch $urlString');
      return false;
    });
  }

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppTheme.primary;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return AppTheme.primary;
    }
  }

  // Get contextual button config based on index
  Map<String, String>? _getOverrideConfig(int index) {
    switch (index) {
      case 0: // Trades
        return {'text': 'Post a Task', 'action': 'app://create-task'};
      case 1: // Professional
        return {'text': 'Consult a Pro', 'action': 'app://create-task'};
      case 2: // Equipment
        return {'text': 'Request Equipment', 'action': 'app://create-equipment-request'};
      case 3: // Contractors
        return {'text': 'Find a Contractor', 'action': 'app://create-project'};
      default:
        return null; // No override for extra indices
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = _features;
    // Safety check just in case
    if (features.isEmpty) return const SizedBox.shrink();
    
    // Ensure current index is valid
    if (_currentIndex >= features.length) _currentIndex = 0;

    final currentFeature = features[_currentIndex];
    final bool isAd = currentFeature is Ad;
    
    // Determine background colors
    List<Color> bgColors;
    if (isAd) {
      final Color baseColor = _hexToColor(currentFeature.backgroundColor);
      // Create a subtle gradient from the base color
      bgColors = [baseColor, baseColor.withOpacity(0.8)];
    } else {
      bgColors = currentFeature['colors'] as List<Color>;
    }
    
    return Container(
      height: 124, 
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              _trackCurrentAdImpression();
            },
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              final bool itemIsAd = feature is Ad;
              
              // Apply overrides based on index
              final overrideConfig = _getOverrideConfig(index);
              
              final String title = itemIsAd ? feature.title : feature['title'];
              final String subtitle = itemIsAd ? feature.description : feature['subtitle'];
              
              // Use override text if available, otherwise original
              final String buttonText = overrideConfig?['text'] ?? 
                  (itemIsAd ? feature.buttonText : feature['button']);
              
              // Use override action if available
              final String? actionUrl = overrideConfig?['action'];
              
              final IconData icon = itemIsAd ? Icons.campaign_outlined : feature['icon'];
              final Color btnTextColor = itemIsAd 
                  ? _hexToColor(feature.backgroundColor) 
                  : feature['colors'][0];
              
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box or Ad Image
                    (itemIsAd && feature.imageUrl.isNotEmpty
                      ? Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(feature.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 26,
                          ),
                        )
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () => _onAction(feature, actionUrl),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: btnTextColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: Text(
                                buttonText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Dots Indicator
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(features.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentIndex == index ? 16 : 6,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_currentIndex == index ? 1 : 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
