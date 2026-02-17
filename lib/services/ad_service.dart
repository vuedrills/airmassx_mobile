import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env.dart';
import '../config/constants.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Use AppConfig for AdMob IDs
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return AppConfig.shared.adMobBannerUnitIdAndroid;
    } else if (Platform.isIOS) {
      return AppConfig.shared.adMobBannerUnitIdIos;
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get interstitialAdUnitId {
     if (Platform.isAndroid) {
      return AppConfig.shared.adMobInterstitialUnitIdAndroid;
    } else if (Platform.isIOS) {
      return AppConfig.shared.adMobInterstitialUnitIdIos;
    }
    throw UnsupportedError('Unsupported platform');
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;
  DateTime? _lastInterstitialShowTime;
  
  // Track if ads are enabled from backend
  bool _adsEnabled = false; // Default to false until confirmed enabled
  DateTime? _lastStatusCheck;
  final Completer<void> _initCompleter = Completer<void>();

  /// Check if ads are enabled (public getter)
  bool get adsEnabled => _adsEnabled;
  Future<void> get isInitialized => _initCompleter.future;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    await checkAdMobStatus();
    if (!_initCompleter.isCompleted) _initCompleter.complete();
    
    if (_adsEnabled) {
      _loadInterstitialAd();
    }
  }

  /// Fetch AdMob status from backend
  Future<void> checkAdMobStatus() async {
    // Check every 5 minutes in production, but 30 seconds in debug for testing
    final cacheDuration = kReleaseMode 
        ? const Duration(minutes: 5) 
        : const Duration(seconds: 30);

    if (_lastStatusCheck != null &&
        DateTime.now().difference(_lastStatusCheck!) < cacheDuration) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.shared.apiUrl}/settings/admob-status'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _adsEnabled = data['enabled'] ?? true;
        _lastStatusCheck = DateTime.now();
        debugPrint('AdMob status: ${_adsEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      debugPrint('Failed to check AdMob status: $e');
      // Default to enabled if we can't reach the server
      _adsEnabled = true;
    }
  }

  void _loadInterstitialAd() {
    if (!_adsEnabled) return;
    if (_isInterstitialAdLoading || _interstitialAd != null) return;

    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          debugPrint('InterstitialAd loaded.');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (!_adsEnabled) {
      debugPrint('Skipping interstitial: Ads disabled by admin.');
      return;
    }

    final now = DateTime.now();
    if (_lastInterstitialShowTime != null &&
        now.difference(_lastInterstitialShowTime!).inMinutes < 3) {
      debugPrint('Skipping interstitial: Too soon.');
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not ready.');
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastInterstitialShowTime = DateTime.now();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }

  /// Preload interstitial for next use
  void preloadInterstitial() {
    if (_adsEnabled && _interstitialAd == null) {
      _loadInterstitialAd();
    }
  }
}
