import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../screens/tasks/create_task_screen.dart';
import '../../models/ad.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart';
import 'package:url_launcher/url_launcher.dart';

class FeatureCarousel extends StatefulWidget {
  final List<Ad>? ads;
  const FeatureCarousel({super.key, this.ads});

  @override
  State<FeatureCarousel> createState() => _FeatureCarouselState();
}

class _FeatureCarouselState extends State<FeatureCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _defaultFeatures = [
    {
      'title': 'Your Home, Sorted',
      'subtitle': 'Expert help for every task',
      'button': 'Post a Task',
      'colors': [const Color(0xFF1A1A4E), const Color(0xFF2D2D7A)], // Navy Gradient
      'icon': Icons.home_repair_service_outlined,
      'is_internal': true,
    },
    {
      'title': 'Top-Rated Pros',
      'subtitle': 'Verified experts ready to help',
      'button': 'Post a Task',
      'colors': [const Color(0xFFA42444), const Color(0xFFC93D5E)], // Maroon Gradient
      'icon': Icons.verified_user_outlined,
      'is_internal': true,
    },
    {
      'title': 'Solar Deals',
      'subtitle': 'Save on renewable energy',
      'button': 'Post a Task',
      'colors': [const Color(0xFF0A5C36), const Color(0xFF0D7A48)], // Green Gradient
      'icon': Icons.solar_power_outlined,
      'is_internal': true,
    },
  ];

  List<dynamic> get _features {
    if (widget.ads != null && widget.ads!.isNotEmpty) {
      // Prioritize "notice_board" placement ads for the carousel
      final bannerAds = widget.ads!.where((ad) => ad.placement == 'notice_board').toList();
      return bannerAds.isNotEmpty ? bannerAds : _defaultFeatures;
    }
    return _defaultFeatures;
  }

  @override
  void initState() {
    super.initState();
    // Track impression for the first ad if it's a backend ad
    _trackCurrentAdImpression();
  }

  void _trackCurrentAdImpression() {
    final features = _features;
    if (_currentIndex < features.length && features[_currentIndex] is Ad) {
      final ad = features[_currentIndex] as Ad;
      getIt<ApiService>().trackAdImpression(ad.id);
    }
  }

  void _onAction(dynamic feature) {
    if (feature is Ad) {
      // Track click
      getIt<ApiService>().trackAdClick(feature.id);

      final String urlString = feature.actionUrl;
      
      // Handle internal app links
      if (urlString.startsWith('app://')) {
        if (urlString == 'app://create-task') {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateTaskScreen(),
            ),
          );
        }
        return;
      }

      final Uri url = Uri.parse(urlString);
      launchUrl(url).catchError((e) {
        debugPrint('Could not launch ${feature.actionUrl}');
        return false;
      });
    } else {
      // Default internal action
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CreateTaskScreen(),
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final features = _features;
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
              
              final String title = itemIsAd ? feature.title : feature['title'];
              final String subtitle = itemIsAd ? feature.description : feature['subtitle'];
              final String buttonText = itemIsAd ? feature.buttonText : feature['button'];
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
                    if (itemIsAd && feature.imageUrl.isNotEmpty)
                      Container(
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
                    else
                      Container(
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
                      ),
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
                          ),
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
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () => _onAction(feature),
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
                          ),
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
