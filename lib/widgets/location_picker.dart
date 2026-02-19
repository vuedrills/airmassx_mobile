import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../services/geocoding_service.dart';
import 'dynamic_map.dart';
import '../bloc/map_settings/map_settings_cubit.dart';
import '../../utils/location_permission_helper.dart';
import 'package:geolocator/geolocator.dart';

/// A comprehensive location picker with 3 input methods:
/// 1. Use current GPS location
/// 2. Choose location on map
/// 3. Search with autocomplete
///
/// Returns a LocationResult with address string AND coordinates (lat/lng)
/// for easy database storage and map plotting.
class LocationPicker extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;
  final String? currentLocationLabel;
  final String? mapTapLabel;
  final Function(LocationResult) onLocationSelected;

  const LocationPicker({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
    this.currentLocationLabel,
    this.mapTapLabel,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class LocationResult {
  final String address;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class _LocationPickerState extends State<LocationPicker> {
  final _geocodingService = GeocodingService();
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _searchFocusNode = FocusNode();
  
  Timer? _debounceTimer;
  List<PlaceResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  bool _showSearchResults = false;
  
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  List<Marker> _markers = [];

  // Default center (Zimbabwe, zoomed out)
  static const _defaultCenter = LatLng(-19.0154, 29.1549);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _updateMarker(_selectedLocation!);
    } else {
      _tryGetGpsLocation();
    }

    if (widget.initialAddress != null) {
      _selectedAddress = widget.initialAddress!;
      _searchController.text = widget.initialAddress!;
    }
    
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() => _showSearchResults = false);
      }
    });
  }

  Future<void> _tryGetGpsLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await _geocodingService.getCurrentLocation();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedLocation = latLng;
          _updateMarker(latLng);
        });
        try {
          _mapController.move(latLng, 15.0);
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await _geocodingService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = results.isNotEmpty;
          _isSearching = false;
        });
      }
    });
  }

  void _selectPlace(PlaceResult place) async {
    // If we have a placeId but no coordinates (Google Autocomplete), fetch details
    if (place.placeId != null && (place.lat == 0 && place.lng == 0)) {
      setState(() => _isLoadingLocation = true);
      final details = await _geocodingService.getGooglePlaceDetails(place.placeId!);
      
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        if (details != null) {
          place = details;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load place details')),
          );
          return;
        }
      } else {
        return;
      }
    }

    setState(() {
      _selectedLocation = LatLng(place.lat, place.lng);
      _selectedAddress = place.label;
      _searchController.text = place.displayName;
      _showSearchResults = false;
      _updateMarker(_selectedLocation!);
    });

    try {
      _mapController.move(_selectedLocation!, 15.0);
    } catch (e) {
      debugPrint('OSM Controller not attached: $e');
    }
    _searchFocusNode.unfocus();

    widget.onLocationSelected(LocationResult(
      address: place.label,
      latitude: place.lat,
      longitude: place.lng,
    ));
  }

  void _onMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _updateMarker(position);
      _isLoadingLocation = true;
    });

    // Reverse geocode to get address
    final result = await _geocodingService.reverseGeocode(position.latitude, position.longitude);
    
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        if (result != null) {
          _selectedAddress = result.label;
          _searchController.text = result.displayName;
        } else {
          _selectedAddress = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
          _searchController.text = _selectedAddress;
        }
      });

      widget.onLocationSelected(LocationResult(
        address: _selectedAddress,
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    }
  }

  void _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    // Check precision using helper
    final permission = await LocationPermissionHelper.checkAndRequestPermission(context);
    
    // If denied, stop (helper already showed dialog if needed)
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        // Only show snackbar if permanently denied, as helper handles the other case
        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission is permanently denied. Please enable it in settings.'),
              backgroundColor: Colors.red.shade600,
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
      }
      return;
    }

    // Permission granted, proceed
    final position = await _geocodingService.getCurrentLocation();
    
    if (position == null) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not get current location. Please enable GPS.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final latLng = LatLng(position.latitude, position.longitude);
    
    setState(() {
      _selectedLocation = latLng;
      _updateMarker(latLng);
    });

    try {
      _mapController.move(latLng, 16.0);
    } catch (e) {
      debugPrint('OSM Controller not attached: $e');
    }

    // Reverse geocode to get address
    final result = await _geocodingService.reverseGeocode(latLng.latitude, latLng.longitude);
    
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        if (result != null) {
          _selectedAddress = result.label;
          _searchController.text = result.displayName;
        } else {
          _selectedAddress = '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
          _searchController.text = _selectedAddress;
        }
      });

      widget.onLocationSelected(LocationResult(
        address: _selectedAddress,
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      ));
    }
  }

  void _updateMarker(LatLng position) {
    _markers = [
      Marker(
        point: position,
        width: 50,
        height: 50,
        child: Icon(
          Icons.location_pin,
          color: AppTheme.navy,
          size: 50,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick Action Buttons
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QuickActionButton(
              icon: Icons.my_location,
              label: widget.currentLocationLabel ?? 'Current Location',
              isLoading: _isLoadingLocation,
              onTap: _isLoadingLocation ? null : _useCurrentLocation,
            ),
            const SizedBox(height: 12),
            _QuickActionButton(
              icon: Icons.map,
              label: widget.mapTapLabel ?? 'Tap on Map',
              onTap: () {
                _searchFocusNode.unfocus();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.mapTapLabel != null 
                      ? 'Tap anywhere on the map to ${widget.mapTapLabel!.toLowerCase()}'
                      : 'Tap anywhere on the map to select location'),
                    backgroundColor: AppTheme.navy,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search Field with Autocomplete
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: AppTheme.navy),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _showSearchResults = false;
                                });
                              },
                            )
                          : null,
                  hintText: 'Search for an address...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _onSearchChanged,
                onTap: () {
                  if (_searchResults.isNotEmpty) {
                    setState(() => _showSearchResults = true);
                  }
                },
              ),
            ),

            // Autocomplete Results Dropdown
            if (_showSearchResults)
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      return ListTile(
                        leading: Icon(Icons.location_on, color: AppTheme.navy),
                        title: Text(
                          place.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          place.label,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectPlace(place),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Map
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                DynamicMap(
                  initialCenter: _selectedLocation ?? _defaultCenter,
                  initialZoom: _selectedLocation != null ? 15.0 : 6.0,
                  osmController: _mapController,
                  markers: _selectedLocation != null 
                    ? [DynamicMarker(id: 'pin', point: _selectedLocation!)] 
                    : [],
                  onTap: (latLng) => _onMapTap(latLng),
                  onGoogleMapCreated: (controller) {
                    // We can store this controller if needed for programmatic moves
                    if (_selectedLocation != null) {
                      controller.animateCamera(
                        google.CameraUpdate.newLatLngZoom(
                          google.LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude),
                          15.0,
                        ),
                      );
                    }
                  },
                ),

                // Map Attribution
                Positioned(
                  bottom: _selectedLocation != null ? 70 : 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '© CARTO, © OpenStreetMap',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                    ),
                  ),
                ),

                // Selected Location Info
                if (_selectedLocation != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Location Selected',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  _searchController.text.isNotEmpty 
                                    ? _searchController.text
                                    : '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Loading overlay
                if (_isLoadingLocation)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.navy,
                  ),
                )
              else
                Icon(icon, size: 18, color: AppTheme.navy),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
