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
        // Use local IP for iOS Simulator/Device to avoid connection refused
        return 'http://192.168.99.174:8080/api/v1'; 
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
        // Use local IP for iOS Simulator/Device
        return 'http://192.168.99.174:8080'; 
    }
  }

  // Sentry DSN
  String get sentryDsn {
    return 'https://788e7a7e1f98018a13a7c6f0920400c4@o4508711466074112.ingest.us.sentry.io/4508742517817344';
  }

  // AdMob App ID (Android)
  String get adMobAppIdAndroid {
    switch (_environment) {
      case AppEnvironment.prod:
        return 'ca-app-pub-3940256099942544~3347511713'; // TODO: Replace with Real Prod ID
      case AppEnvironment.dev:
      default:
        return 'ca-app-pub-3940256099942544~3347511713'; // Test ID
    }
  }

  // AdMob App ID (iOS)
  String get adMobAppIdIos {
    switch (_environment) {
      case AppEnvironment.prod:
        return 'ca-app-pub-3940256099942544~1458002511'; // TODO: Replace with Real Prod ID
      case AppEnvironment.dev:
      default:
        return 'ca-app-pub-3940256099942544~1458002511'; // Test ID
    }
  }
  
  // Google Sign-In Client IDs
  String get googleWebClientId => '109180723972-rt2qtc2a4aq9vi2se2cn6llj0ii0ajqh.apps.googleusercontent.com';
  String get googleIosClientId => '109180723972-do0cr7ciniud9o93md67u47kh9hk9lf1.apps.googleusercontent.com';
  
  bool get isProduction => _environment == AppEnvironment.prod;
  bool get isDevelopment => _environment == AppEnvironment.dev;
}
