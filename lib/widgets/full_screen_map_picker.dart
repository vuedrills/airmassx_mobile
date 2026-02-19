import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:geolocator/geolocator.dart';

import '../config/theme.dart';
import '../utils/location_permission_helper.dart';
import '../services/geocoding_service.dart';
import 'dynamic_map.dart';
import 'pro_registration_location_picker.dart'; // For result type

class FullScreenMapPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const FullScreenMapPicker({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<FullScreenMapPicker> createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<FullScreenMapPicker> {
  final _geocodingService = GeocodingService();
  final _mapController = MapController();
  google.GoogleMapController? _googleMapController;

  // Default: zoomed-out Zimbabwe center (not Harare zoomed in)
  static const _zimbabweCenter = LatLng(-19.0154, 29.1549);
  static const _defaultZoom = 6.0; // Country-level zoom
  static const _streetZoom = 15.0;

  late LatLng _center;
  late double _currentZoom;
  bool _isGeocoding = false;
  // Show hint until user moves map or we have a known position
  String _address = "Move the map to set your location";
  ProRegistrationLocationResult? _result;
  Timer? _debounceTimer;
  bool _isProgrammaticMove = false;
  bool _hasInitialPosition = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialLat != null && widget.initialLng != null) {
      // Caller provided a known position — use it and geocode immediately
      _center = LatLng(widget.initialLat!, widget.initialLng!);
      _currentZoom = _streetZoom;
      _hasInitialPosition = true;
      _triggerReverseGeocode(_center);
    } else {
      // No known position — start zoomed out, then try GPS silently
      _center = _zimbabweCenter;
      _currentZoom = _defaultZoom;
      _tryGetGpsLocation();
    }
  }

  /// Silently tries to get GPS without showing a permission dialog.
  /// Only moves the map if permission is already granted.
  Future<void> _tryGetGpsLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Don't request — just stay on zoomed-out Zimbabwe view
        return;
      }

      final position = await _geocodingService.getCurrentLocation();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);
        _isProgrammaticMove = true;
        setState(() {
          _center = latLng;
          _currentZoom = _streetZoom;
        });
        try {
          _mapController.move(latLng, _streetZoom);
        } catch (_) {}
        _googleMapController?.animateCamera(
          google.CameraUpdate.newLatLngZoom(
            google.LatLng(latLng.latitude, latLng.longitude),
            _streetZoom,
          ),
        );
        // Geocode the GPS position so the user sees their address
        await _triggerReverseGeocode(latLng);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _isProgrammaticMove = false;
        });
      }
    } catch (_) {
      // Silently ignore — user stays on zoomed-out view
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onCameraMove(LatLng newCenter) {
    if (_isProgrammaticMove) return;

    // Reset state immediately so user sees feedback
    if (mounted && !_isGeocoding) {
      setState(() {
        _isGeocoding = true;
        _address = "Locating...";
        _result = null;
      });
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _triggerReverseGeocode(newCenter);
    });
  }

  Future<void> _triggerReverseGeocode(LatLng pos) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      final result = await _geocodingService.reverseGeocode(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          _isGeocoding = false;
          _center = pos;
          if (result != null) {
            _address = result.displayName;
            _result = ProRegistrationLocationResult(
              city: result.city ?? '',
              suburb: result.suburb ?? '',
              addressDetails: result.displayName,
              latitude: pos.latitude,
              longitude: pos.longitude,
              fullAddress: result.displayName,
            );
          } else {
            _address = "Unknown location";
            _result = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
          _address = "Error fetching address";
          _result = null;
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    // Use the helper which shows the prominent disclosure dialog first (Google Play policy)
    final permission = await LocationPermissionHelper.checkAndRequestPermission(context);
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted && permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permission denied. Enable it in Settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isGeocoding = true;
      _address = "Getting current location...";
    });

    try {
      final position = await _geocodingService.getCurrentLocation();
      if (position != null && mounted) {
        final latLng = LatLng(position.latitude, position.longitude);

        _isProgrammaticMove = true;
        try {
          _mapController.move(latLng, _streetZoom);
        } catch (e) {
          debugPrint('OSM Controller not attached: $e');
        }
        _googleMapController?.animateCamera(
          google.CameraUpdate.newLatLngZoom(
            google.LatLng(latLng.latitude, latLng.longitude),
            _streetZoom,
          ),
        );

        await _triggerReverseGeocode(latLng);

        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _isProgrammaticMove = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isGeocoding = false;
            // Only show error if we actually had permission but failed to get location
            // The user already knows if they denied permission
            if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
               _address = "Could not get current location";
            } else {
               _address = "Location permission required";
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
          _address = "Error getting location";
        });
      }
    }
  }

  void _onDone() {
    if (_result != null) {
      Navigator.pop(context, _result);
    }
  }

  void _zoomIn() {
    setState(() => _currentZoom++);
    try {
      _mapController.move(_center, _currentZoom);
    } catch (e) {
      debugPrint('OSM Controller not attached: $e');
    }
    _googleMapController?.animateCamera(
      google.CameraUpdate.newLatLngZoom(
        google.LatLng(_center.latitude, _center.longitude),
        _currentZoom,
      ),
    );
  }

  void _zoomOut() {
    setState(() => _currentZoom--);
    try {
      _mapController.move(_center, _currentZoom);
    } catch (e) {
      debugPrint('OSM Controller not attached: $e');
    }
    _googleMapController?.animateCamera(
      google.CameraUpdate.newLatLngZoom(
        google.LatLng(_center.latitude, _center.longitude),
        _currentZoom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map
          DynamicMap(
            initialCenter: _center,
            initialZoom: _currentZoom,
            osmController: _mapController,
            markers: [],
            onGoogleMapCreated: (c) => _googleMapController = c,
            onCameraMove: _onCameraMove,
          ),

          // 2. Center Pin (Fixed)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_pin, size: 50, color: AppTheme.primary),
            ),
          ),

          // 3. Back Button (Floating)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 4. Use My Location button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.my_location, color: AppTheme.primary),
                onPressed: _useCurrentLocation,
                tooltip: 'Use my location',
              ),
            ),
          ),

          // 5. Zoom Controls
          Positioned(
            bottom: 200,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // 6. Bottom Sheet (Floating Card)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          color: _result != null ? AppTheme.primary : AppTheme.neutral500,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _address,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _result != null ? AppTheme.navy : AppTheme.neutral500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isGeocoding)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isGeocoding || _result == null) ? null : _onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: AppTheme.neutral300,
                        ),
                        child: Text(
                          _isGeocoding ? 'Locating...' : 'Confirm Location',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
