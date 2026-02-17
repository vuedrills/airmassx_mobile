import 'dart:io';
import 'package:flutter/foundation.dart';

enum AppEnvironment {
  dev,
  prod,
}

class AppConfig {
  static final AppConfig shared = AppConfig._internal();

  factory AppConfig() {
    return shared;
  }

  AppConfig._internal();

  AppEnvironment _environment = AppEnvironment.dev;
  AppEnvironment get environment => _environment;

  void initialize({AppEnvironment env = AppEnvironment.dev}) {
    _environment = env;
  }

  // API URL
  String get apiUrl {
    switch (_environment) {
      case AppEnvironment.prod:
        return 'https://v2-api.airmassxpress.com/api/v1';
      case AppEnvironment.dev:
      default:
         if (kIsWeb) {
          return 'http://localhost:8080/api/v1';
        }
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:8080/api/v1';
        }
        // Use localhost for iOS Simulator. Update IP if testing on Physical Device.
        return 'http://localhost:8080/api/v1'; // fallback IP was: 192.168.24.174
    }
  }
  
  // Asset Base URL
  String get assetBaseUrl {
     switch (_environment) {
      case AppEnvironment.prod:
        return 'https://v2-api.airmassxpress.com';
      case AppEnvironment.dev:
      default:
         if (kIsWeb) {
          return 'http://localhost:8080';
        }
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:8080';
        }
        // Use localhost for iOS Simulator. Update IP if testing on Physical Device.
        return 'http://localhost:8080'; // fallback IP was: 192.168.24.174
    }
  }

  // Sentry DSN
  String get sentryDsn {
    return 'https://f95eaf1e713b068687be7c1509c7a2e7@o4510872956829696.ingest.us.sentry.io/4510872966004736';
  }

  // AdMob App ID (Android) - FOUND IN: android/app/src/main/AndroidManifest.xml
  String get adMobAppIdAndroid {
    switch (_environment) {
      case AppEnvironment.prod:
        return 'ca-app-pub-1237074677015039~3506864960'; 
      case AppEnvironment.dev:
      default:
        return 'ca-app-pub-1237074677015039~3506864960'; 
    }
  }

  // AdMob Banner Unit ID (Android)
  String get adMobBannerUnitIdAndroid {
    return 'ca-app-pub-1237074677015039/8543677025'; 
  }

  // AdMob Interstitial Unit ID (Android)
  String get adMobInterstitialUnitIdAndroid {
    return 'ca-app-pub-1237074677015039/5917513681';
  }

  // AdMob App ID (iOS) - FOUND IN: ios/Runner/Info.plist
  String get adMobAppIdIos {
    switch (_environment) {
      case AppEnvironment.prod:
        return 'ca-app-pub-1237074677015039~3786174369';
      case AppEnvironment.dev:
      default:
        return 'ca-app-pub-1237074677015039~3786174369';
    }
  }

  // AdMob Banner Unit ID (iOS)
  String get adMobBannerUnitIdIos {
    return 'ca-app-pub-1237074677015039/3291350348';
  }

  // AdMob Interstitial Unit ID (iOS)
  String get adMobInterstitialUnitIdIos {
    return 'ca-app-pub-1237074677015039/6999387414';
  }
  
  // Google Sign-In Client IDs
  String get googleWebClientId => '109180723972-rt2qtc2a4aq9vi2se2cn6llj0ii0ajqh.apps.googleusercontent.com';
  String get googleIosClientId => '109180723972-do0cr7ciniud9o93md67u47kh9hk9lf1.apps.googleusercontent.com';
  
  bool get isProduction => _environment == AppEnvironment.prod;
  bool get isDevelopment => _environment == AppEnvironment.dev;
}
