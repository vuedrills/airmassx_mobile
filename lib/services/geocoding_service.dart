import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../core/service_locator.dart';

/// Place result from geocoding/autocomplete
class PlaceResult {
  final String label;
  final String displayName;
  final double lat;
  final double lng;
  final String? city;
  final String? suburb;
  final String? country;
  final String? placeId; // Added for Google Places

  PlaceResult({
    required this.label,
    required this.displayName,
    required this.lat,
    required this.lng,
    this.city,
    this.suburb,
    this.country,
    this.placeId,
  });

  @override
  String toString() => displayName;
}

/// Geocoding Service using free APIs
/// - Photon (OpenStreetMap) for autocomplete - unlimited free
/// - Nominatim for reverse geocoding - free with attribution
/// 
/// Architecture: Autocomplete → Select → Store coordinates with task
/// Coordinates are stored in DB, never need to geocode again when displaying on map
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  // Cache for autocomplete results
  final Map<String, List<PlaceResult>> _cache = {};
  static const int _maxCacheSize = 50;

  // Default center for Zimbabwe (Harare)
  static const double defaultLat = -17.8252;
  static const double defaultLng = 31.0335;

  // Google Places API Key (Should be fetched securely or from config via native bridge if possible, 
  // but for Dart direct HTTP calls we need it here. However, using native GooglePlacesPlugin is better practice.
  // For simplicity and quick hybrid toggle, we'll try to use the key passed from native config or hardcoded here as fallback
  // WARNING: Ideally use a proxy backend or restrict this key heavily.
  static const String _googleApiKey = "AIzaSyBF4R495Ci11ppAnCtHpHQrUbE2l6ljFcY"; 
  final _uuid = const Uuid();


  /// Search for places with hybrid logic (Google vs OSM)
  Future<List<PlaceResult>> searchPlaces(String query, {String? sessionToken}) async {
    if (query.length < 3) return [];

    // Check Global Setting
    final apiService = getIt<ApiService>();
    final provider = await apiService.getMapProvider();

    if (provider == 'google') {
        return _searchWithGoogle(query, sessionToken);
    }

    // Default to OSM logic
    return _searchWithOsm(query);
  }

  /// Search using OSM (Photon/Nominatim)
  Future<List<PlaceResult>> _searchWithOsm(String query) async {
    final cacheKey = query.toLowerCase().trim();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Try Photon first, then Nominatim as fallback
    var results = await _searchWithPhoton(query);
    if (results.isEmpty) {
      results = await _searchWithNominatim(query);
    }

    if (results.isNotEmpty) {
      _addToCache(cacheKey, results);
    }

    return results;
  }

  /// Search using Google Places API (New)
  Future<List<PlaceResult>> _searchWithGoogle(String query, String? sessionToken) async {
    try {
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:autocomplete'
      );

      final token = sessionToken ?? _uuid.v4();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,
        },
        body: json.encode({
          "input": query,
          "sessionToken": token,
          "locationRestriction": {
            "circle": {
              "center": {
                "latitude": defaultLat,
                "longitude": defaultLng
              },
              "radius": 50000.0 // 50km radius (Max allowed by API is 50,000)
            }
          }
        }),
      );

      // Track usage on every autocomplete API call
      getIt<ApiService>().reportMapUsage();

      if (response.statusCode != 200) {
        print('Google Places API error: ${response.statusCode} ${response.body}');
        return [];
      }

      final data = json.decode(response.body);
      final suggestions = data['suggestions'] as List? ?? [];

      return suggestions.map((item) {
        final placePrediction = item['placePrediction'];
        final text = placePrediction['text'];
        final mainText = text['text'];
        final secondaryText = placePrediction['structuredFormat']['secondaryText']['text'];
        
        // We don't get lat/lng from Autocomplete directly, we get a Place ID.
        // For the purpose of the UI list, we return 0,0 and fetch details later if needed.
        // Or we use the Geocoding API to get details on selection.
        // But our EnhancedLocationPicker expects lat/lng immediately for some logic?
        // Actually, Autocomplete just gives text. We need a second call "Get Place Details" to get Lat/Lng.
        // To save costs/complexity, implementing "Get Details" is another step.
        // For now, let's look at how to fit this into PlaceResult.
        
        return PlaceResult(
          label: mainText,
          displayName: '$mainText, $secondaryText',
          lat: 0, // Placeholder, requires GetPlaceDetails
          lng: 0, // Placeholder
          city: mainText,
          placeId: placePrediction['placeId'], 
        );
      }).toList();

      // WAIT: Google Autocomplete returns Place IDs. To get Lat/Lng, we MUST call "Get Place Details" (Free if only asking for IDs/Location).
      // If we don't return Lat/Lng, the map won't move when user selects a suggestion.
      // Modifying PlaceResult to include placeId is best.
    } catch (e) {
      print('Google Search Error: $e');
      return [];
    }
  }

  Future<PlaceResult?> getGooglePlaceDetails(String placeId) async {
      try {
          final url = Uri.parse('https://places.googleapis.com/v1/places/$placeId?fields=location,id,displayName&key=$_googleApiKey');
          
          // Report usage on detail fetch (selection)
          getIt<ApiService>().reportMapUsage();

          final response = await http.get(url);
          
          if (response.statusCode != 200) {
              return null;
          }
          
          final data = json.decode(response.body);
          final location = data['location'];
          final displayName = data['displayName']?['text'] ?? '';
          
          return PlaceResult(
              label: displayName,
              displayName: displayName,
              lat: location['latitude'],
              lng: location['longitude'],
              placeId: placeId,
          );
      } catch (e) {
          print('Get Place Details Error: $e');
          return null;
      }
  }

  Future<List<PlaceResult>> _searchWithPhoton(String query) async {
    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}'
        '&limit=5&lat=$defaultLat&lon=$defaultLng'
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'AirmassXpress-Mobile/1.0 (equipment-hire-app)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        print('Photon API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      final features = data['features'] as List? ?? [];

      return features
          .where((feature) {
            final country = feature['properties']?['country'] as String?;
            return country == null || 
                   country.toLowerCase() == 'zimbabwe' ||
                   country.toLowerCase() == 'south africa' ||
                   country.toLowerCase() == 'botswana' ||
                   country.toLowerCase() == 'zambia' ||
                   country.toLowerCase() == 'mozambique';
          })
          .map((feature) {
            final props = feature['properties'] ?? {};
            final coords = feature['geometry']?['coordinates'] as List? ?? [0, 0];

            final parts = [
              props['name'],
              props['street'],
              props['city'] ?? props['town'] ?? props['village'],
              props['state'],
              props['country'],
            ].where((p) => p != null && p.toString().isNotEmpty).toList();

            return PlaceResult(
              label: parts.join(', '),
              displayName: props['name'] ?? parts.firstOrNull ?? 'Unknown',
              lat: (coords[1] as num).toDouble(),
              lng: (coords[0] as num).toDouble(),
              city: props['city'] ?? props['town'] ?? props['village'],
              suburb: props['district'] ?? props['suburb'] ?? props['locality'] ?? props['quarter'] ?? props['hamlet'],
              country: props['country'],
            );
          })
          .toList()
          .cast<PlaceResult>();
    } catch (e) {
      print('Photon search error: $e');
      return [];
    }
  }

  Future<List<PlaceResult>> _searchWithNominatim(String query) async {
    try {
      // Add "Zimbabwe" to query for better results
      final searchQuery = query.toLowerCase().contains('zimbabwe') 
          ? query 
          : '$query, Zimbabwe';

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(searchQuery)}'
        '&format=json&addressdetails=1&limit=5'
        '&countrycodes=zw,za,bw,zm,mz'
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'AirmassXpress-Mobile/1.0 (equipment-hire-app)'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('Nominatim API error: ${response.statusCode}');
        return [];
      }

      final data = json.decode(response.body) as List;

      return data.map((item) {
        final address = item['address'] ?? {};
        final displayParts = [
          address['name'] ?? address['road'] ?? address['pedestrian'],
          address['suburb'] ?? address['neighbourhood'],
          address['city'] ?? address['town'] ?? address['village'],
          address['country'],
        ].where((p) => p != null).toList();

        return PlaceResult(
          label: item['display_name'] ?? '',
          displayName: displayParts.isNotEmpty ? displayParts.join(', ') : item['display_name'] ?? 'Unknown',
          lat: double.tryParse(item['lat']?.toString() ?? '0') ?? 0,
          lng: double.tryParse(item['lon']?.toString() ?? '0') ?? 0,
          city: address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'],
          suburb: address['suburb'] ?? address['neighbourhood'] ?? address['village'] ?? address['hamlet'] ?? address['quarter'] ?? address['subdivision'],
          country: address['country'],
        );
      }).toList();
    } catch (e) {
      print('Nominatim search error: $e');
      return [];
    }
  }


  /// Reverse geocode coordinates to get address
  Future<PlaceResult?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&addressdetails=1'
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'AirmassXpress-Mobile/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('Nominatim reverse geocode error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final address = data['address'] ?? {};

      final displayParts = [
        address['road'] ?? address['pedestrian'],
        address['suburb'] ?? address['neighbourhood'],
        address['city'] ?? address['town'] ?? address['village'],
      ].where((p) => p != null).toList();

      final suburb = address['suburb'] ?? 
                     address['neighbourhood'] ?? 
                     address['village'] ?? 
                     address['hamlet'] ?? 
                     address['quarter'] ?? 
                     address['residential'] ??
                     address['allotments'] ??
                     address['subdivision'];

      return PlaceResult(
        label: data['display_name'] ?? '',
        displayName: displayParts.join(', '),
        lat: lat,
        lng: lng,
        city: address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'],
        suburb: suburb,
        country: address['country'],
      );
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Get current device location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // Try to get last known position first for speed
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return position;
      }

      // Get current position (can be slow on emulators)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Lower accuracy is faster
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  void _addToCache(String key, List<PlaceResult> results) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = results;
  }

  void clearCache() {
    _cache.clear();
  }
}
