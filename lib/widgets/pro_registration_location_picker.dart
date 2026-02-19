import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../services/geocoding_service.dart';
import '../services/api_service.dart';
import '../core/service_locator.dart';
import 'dynamic_map.dart';
import 'full_screen_map_picker.dart';
import '../bloc/map_settings/map_settings_cubit.dart';
import '../utils/location_permission_helper.dart';

/// Specialized location picker for Pro Registration
/// Features:
/// 1. "Use my current location" prominent button
/// 2. Search field with auto-complete
/// 3. "Choose on map" option that expands map view
/// 4. Addresses race conditions in location setting
class ProRegistrationLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;
  final Function(ProRegistrationLocationResult) onLocationSelected;

  const ProRegistrationLocationPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<ProRegistrationLocationPicker> createState() => _ProRegistrationLocationPickerState();
}

class ProRegistrationLocationResult {
  final String city;
  final String suburb;
  final String addressDetails;
  final double latitude;
  final double longitude;
  final String fullAddress;

  ProRegistrationLocationResult({
    required this.city,
    required this.suburb,
    required this.addressDetails,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });
}

class _ProRegistrationLocationPickerState extends State<ProRegistrationLocationPicker> {
  final _geocodingService = GeocodingService();
  final _searchController = TextEditingController();


  // State
  bool _isLocating = false;

  LatLng? _pinPosition;
  String? _selectedAddress;
  
  // Search state
  List<PlaceResult> _searchResults = [];
  bool _showSearchResults = false;
  Timer? _debounceTimer;
  String? _currentSessionToken;
  final _uuid = const Uuid();



  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _pinPosition = LatLng(widget.initialLat!, widget.initialLng!);
      if (widget.initialAddress != null) {
        _selectedAddress = widget.initialAddress;
        _searchController.text = widget.initialAddress!;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();

    super.dispose();
  }

  void _notifyLocationSelected(String fullAddress, double lat, double lng, {String? city, String? suburb}) {
    // If city/suburb not provided, we might need to extract them from address or use defaults
    // For now, passing empty strings if unknown, backend might infer or we rely on reverse geocoding result
    widget.onLocationSelected(ProRegistrationLocationResult(
      city: city ?? '',
      suburb: suburb ?? '',
      addressDetails: fullAddress,
      latitude: lat,
      longitude: lng,
      fullAddress: fullAddress,
    ));
  }

  // --- Current Location Logic ---

  Future<void> _useCurrentLocation() async {
    final permission = await LocationPermissionHelper.checkAndRequestPermission(context);
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    setState(() => _isLocating = true);

    try {
      final position = await _geocodingService.getCurrentLocation();
      if (position == null) throw Exception('Could not get location');

      final lat = position.latitude;
      final lng = position.longitude;
      
      // Move map first
      final target = LatLng(lat, lng);


      // Reverse geocode
      final result = await _geocodingService.reverseGeocode(lat, lng);
      
      if (mounted) {
        setState(() {
          _pinPosition = target;
          _selectedAddress = result?.displayName ?? "$lat, $lng";
          _searchController.text = _selectedAddress!; // Update search field
          _isLocating = false;
        });

        _notifyLocationSelected(
          _selectedAddress!,
          lat,
          lng,
          city: result?.city,
          suburb: result?.suburb,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  // --- Search Logic ---

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    _currentSessionToken ??= _uuid.v4();
    try {
      final results = await _geocodingService.searchPlaces(query, sessionToken: _currentSessionToken);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = true;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  Future<void> _selectSearchResult(PlaceResult place) async {
    LatLng target;
    PlaceResult effectivePlace = place;
    
    if (place.lat == 0 && place.lng == 0 && place.placeId != null) {
      // Need to fetch details — use the enriched result for city/suburb/label
      final details = await _geocodingService.getGooglePlaceDetails(place.placeId!);
      if (details != null) {
        target = LatLng(details.lat, details.lng);
        effectivePlace = details;
      } else {
        return; // Failed to get details
      }
    } else {
      target = LatLng(place.lat, place.lng);
    }

    final displayName = effectivePlace.label.isNotEmpty 
        ? effectivePlace.label 
        : effectivePlace.displayName;

    setState(() {
      _pinPosition = target;
      _selectedAddress = displayName;
      _searchController.text = displayName;
      _showSearchResults = false;
      _currentSessionToken = null;
    });

    _notifyLocationSelected(
      displayName,
      target.latitude,
      target.longitude,
      city: effectivePlace.city,
      suburb: effectivePlace.suburb,
    );
  }

  // --- Map Logic ---



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Current Location Button
        _buildCurrentLocationButton(),
        const SizedBox(height: 16),

        // 2. Search Field
        _buildSearchField(),
        
        // Search Results Overlay
        if (_showSearchResults)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.place, size: 20, color: AppTheme.neutral500),
                  title: Text(place.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(place.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => _selectSearchResult(place),
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        // 3. Choose on Map Option
        _buildMapOption(),

        // 4. Counts/Manual Details (if needed, maybe hidden if map is enough)
        // For now, let's keep it simple as requested
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLocating ? null : _useCurrentLocation,
        icon: _isLocating 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
          : const Icon(Icons.my_location, color: AppTheme.primary),
        label: Text(
          _isLocating ? 'Locating...' : 'Use my current location',
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          foregroundColor: AppTheme.primary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Or search for an address',
          style: TextStyle(
            color: AppTheme.neutral600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Enter city, suburb or street...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.neutral400),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.neutral200),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMapOption() {
    return InkWell(
      onTap: _openMapPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.neutral200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.map, color: AppTheme.navy),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Choose on map',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.navy,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.neutral500),
          ],
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<ProRegistrationLocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMapPicker(
          initialLat: _pinPosition?.latitude,
          initialLng: _pinPosition?.longitude,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _pinPosition = LatLng(result.latitude, result.longitude);
        _selectedAddress = result.fullAddress;
        _searchController.text = result.fullAddress;
      });

      widget.onLocationSelected(result);
    }
  }
}
