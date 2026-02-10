import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';
import '../services/geocoding_service.dart';
import '../services/api_service.dart';
import '../core/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'dynamic_map.dart';
import '../bloc/map_settings/map_settings_cubit.dart';

/// Result object returned by GpsFirstLocationPicker
class GpsFirstLocationResult {
  final String city;
  final String suburb;
  final String addressDetails;
  final double latitude;
  final double longitude;
  final String fullAddress;

  GpsFirstLocationResult({
    required this.city,
    required this.suburb,
    required this.addressDetails,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });
}

/// GPS-first location picker with prominent GPS button and auto-geocode for custom suburbs
class GpsFirstLocationPicker extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;
  final String? initialCity;
  final String? hintText;
  final Function(GpsFirstLocationResult) onLocationSelected;

  const GpsFirstLocationPicker({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
    this.initialCity,
    this.hintText,
    required this.onLocationSelected,
  });

  @override
  State<GpsFirstLocationPicker> createState() => _GpsFirstLocationPickerState();
}

class _GpsFirstLocationPickerState extends State<GpsFirstLocationPicker> {
  final _geocodingService = GeocodingService();
  final _suburbController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _mapController = MapController();
  
  String? _selectedCity;
  String? _selectedCityId;
  String? _selectedSuburb;
  bool _isOtherSuburb = false;
  bool _isOtherCity = false;
  LatLng? _pinPosition;
  bool _isLocating = false;
  bool _locationConfirmed = false;
  List<Marker> _markers = [];
  
  // Curated data from API
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _suburbs = [];
  bool _isLoadingCities = true;
  bool _isLoadingSuburbs = false;
  
  // Debounce timer for auto-geocode
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    if (widget.initialLat != null && widget.initialLng != null) {
      _pinPosition = LatLng(widget.initialLat!, widget.initialLng!);
      _updateMarker(_pinPosition!);
      _locationConfirmed = true;
    }
    _loadCities();
    
    // Auto-notify on text changes
    _addressDetailsController.addListener(_notifyChanges);
  }

  void _notifyChanges() {
    final city = _isOtherCity ? _cityController.text.trim() : _selectedCity;
    final suburb = _isOtherSuburb ? _suburbController.text.trim() : _selectedSuburb;

    if (city == null || city.isEmpty || _pinPosition == null) {
      return;
    }

    final fullAddress = [
      if (suburb != null && suburb.isNotEmpty) suburb,
      city,
      if (_addressDetailsController.text.trim().isNotEmpty) _addressDetailsController.text.trim(),
    ].join(', ');

    widget.onLocationSelected(GpsFirstLocationResult(
      city: city,
      suburb: suburb ?? '',
      addressDetails: _addressDetailsController.text.trim(),
      latitude: _pinPosition!.latitude,
      longitude: _pinPosition!.longitude,
      fullAddress: fullAddress,
    ));
  }

  Future<void> _loadCities() async {
    final apiService = getIt<ApiService>();
    final cities = await apiService.getLocations(type: 'city');
    if (mounted) {
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
        
        if (_selectedCity == null && cities.isNotEmpty) {
          final harare = cities.firstWhere(
            (c) => c['name'] == 'Harare',
            orElse: () => cities.first,
          );
          _selectedCity = harare['name'] as String? ?? 'Harare';
          _selectedCityId = harare['id'] as String?;
          if (_selectedCityId != null) {
            _loadSuburbs(_selectedCityId!);
          }
          
          // Don't set pin yet - wait for user to use GPS or select suburb
        } else if (_selectedCity != null) {
          final cityData = cities.firstWhere(
            (c) => c['name'] == _selectedCity,
            orElse: () => <String, dynamic>{},
          );
          if (cityData.isNotEmpty) {
            _selectedCityId = cityData['id'];
            _loadSuburbs(cityData['id']);
          }
        }
      });
    }
  }

  Future<void> _loadSuburbs(String cityId) async {
    setState(() => _isLoadingSuburbs = true);
    final apiService = getIt<ApiService>();
    final suburbs = await apiService.getLocations(type: 'suburb', parentId: cityId);
    if (mounted) {
      setState(() {
        _suburbs = suburbs;
        _isLoadingSuburbs = false;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _suburbController.dispose();
    _cityController.dispose();
    _addressDetailsController.dispose();
    super.dispose();
  }

  void _onCityChanged(String? city) {
    if (city == null) return;
    
    if (city == 'Other') {
      setState(() {
        _isOtherCity = true;
        _selectedCity = null;
        _selectedCityId = null;
        _selectedSuburb = null;
        _isOtherSuburb = true;
        _suburbController.clear();
        _cityController.clear();
        _locationConfirmed = false;
      });
      return;
    }

    final cityData = _cities.firstWhere((c) => c['name'] == city, orElse: () => <String, dynamic>{});
    if (cityData.isEmpty) return;
    
    final lat = cityData['latitude'] as double? ?? -17.8252;
    final lng = cityData['longitude'] as double? ?? 31.0335;
    
    setState(() {
      _selectedCity = city;
      _selectedCityId = cityData['id'];
      _isOtherCity = false;
      _selectedSuburb = null;
      _isOtherSuburb = false;
      _pinPosition = LatLng(lat, lng);
      _locationConfirmed = false;
      _suburbController.clear();
      _updateMarker(_pinPosition!);
    });
    
    _loadSuburbs(cityData['id']);
    try {
      _mapController.move(_pinPosition!, 13.0);
    } catch (e) {
      debugPrint('Map not ready for move yet: $e');
    }
  }

  void _onSuburbChanged(String? suburb) {
    if (suburb == null) return;
    
    if (suburb == 'Other') {
      setState(() {
        _isOtherSuburb = true;
        _selectedSuburb = null;
        _locationConfirmed = false;
      });
      return;
    }
    
    final suburbData = _suburbs.firstWhere((s) => s['name'] == suburb, orElse: () => <String, dynamic>{});
    
    setState(() {
      _isOtherSuburb = false;
      _selectedSuburb = suburb;
      _suburbController.text = suburb;
    });
    
    // If suburb has coordinates, move to it
    if (suburbData.isNotEmpty && suburbData['latitude'] != null && suburbData['longitude'] != null) {
      final lat = suburbData['latitude'] as double;
      final lng = suburbData['longitude'] as double;
      setState(() {
        _pinPosition = LatLng(lat, lng);
        _locationConfirmed = true;
        _updateMarker(_pinPosition!);
      });
      try {
        _mapController.move(_pinPosition!, 15.0);
      } catch (e) {
        debugPrint('Map not ready for move: $e');
      }
      _notifyChanges();
    }
  }

  void _onCustomSuburbChanged(String value) {
    // Debounce auto-geocode
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _autoGeocodeSuburb(value);
    });
  }

  Future<void> _autoGeocodeSuburb(String suburb) async {
    if (suburb.isEmpty) return;
    
    final city = _isOtherCity ? _cityController.text.trim() : _selectedCity;
    if (city == null || city.isEmpty) return;
    
    try {
      final query = '$suburb, $city, Zimbabwe';
      final results = await _geocodingService.searchPlaces(query);
      
      if (results.isNotEmpty && mounted) {
        final result = results.first;
        final newPosition = LatLng(result.lat, result.lng);
        setState(() {
          _pinPosition = newPosition;
          _selectedSuburb = suburb;
          _locationConfirmed = true;
          _updateMarker(newPosition);
        });
        try {
          _mapController.move(newPosition, 15.0);
        } catch (e) {
          debugPrint('Map not ready for move: $e');
        }
        _notifyChanges();
      }
    } catch (e) {
      debugPrint('Auto-geocode failed: $e');
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    
    final position = await _geocodingService.getCurrentLocation();
    
    if (position == null) {
      if (mounted) {
        setState(() => _isLocating = false);
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
    
    // Reverse geocode to get city and suburb names
    final reverseResult = await _geocodingService.reverseGeocode(position.latitude, position.longitude);
    
    if (mounted) {
      setState(() {
        _pinPosition = latLng;
        _locationConfirmed = true;
        _updateMarker(latLng);
        
        if (reverseResult != null) {
          // Try to match and set City
          if (reverseResult.city != null) {
            final cityMatch = _cities.firstWhere(
              (c) => (c['name'] as String).toLowerCase() == reverseResult.city!.toLowerCase(),
              orElse: () => <String, dynamic>{},
            );
            
            if (cityMatch.isNotEmpty) {
              final oldCityId = _selectedCityId;
              _selectedCity = cityMatch['name'];
              _selectedCityId = cityMatch['id'];
              _isOtherCity = false;
              
              if (oldCityId != cityMatch['id']) {
                _loadSuburbs(cityMatch['id']);
              }
            } else {
              _isOtherCity = true;
              _selectedCity = null;
              _selectedCityId = null;
              _cityController.text = reverseResult.city!;
              _isOtherSuburb = true;
            }
          }
          
          // Set Suburb text
          if (reverseResult.suburb != null) {
            _suburbController.text = reverseResult.suburb!;
            _selectedSuburb = reverseResult.suburb;
            
            // Check if suburb is in the list
            final exists = _suburbs.any((s) => (s['name'] as String).toLowerCase() == reverseResult.suburb!.toLowerCase());
            _isOtherSuburb = !exists;
          }
        }
        
        _isLocating = false;
      });
      
      try {
        _mapController.move(latLng, 16.0);
      } catch (e) {
        debugPrint('Map not ready for move: $e');
      }
      
      _notifyChanges();
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pinPosition = position;
      _locationConfirmed = true;
      _updateMarker(position);
    });
    _notifyChanges();
  }

  void _updateMarker(LatLng position) {
    _markers = [
      Marker(
        point: position,
        width: 50,
        height: 50,
        child: const Icon(
          Icons.location_pin,
          color: AppTheme.primary,
          size: 50,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // GPS Button - Primary CTA
          _buildGpsButton(),
          
          const SizedBox(height: 20),
          
          // Divider with "or search manually"
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or search manually',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // City Dropdown
          _buildCityDropdown(),
          
          if (_selectedCity != null || _isOtherCity) ...[
            const SizedBox(height: 16),
            
            // Suburb Dropdown/TextField
            _buildSuburbField(),
            
            const SizedBox(height: 20),
            
            // Map
            _buildMap(),
            
            const SizedBox(height: 16),
            
            // Address Details
            _buildAddressDetails(),
            
            // Confirmation Badge
            if (_locationConfirmed && _pinPosition != null)
              _buildConfirmationBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildGpsButton() {
    return GestureDetector(
      onTap: _isLocating ? null : _useCurrentLocation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLocating)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.my_location, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              _isLocating ? 'Getting your location...' : 'Use my current location',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City / Town',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neutral200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: _isLoadingCities
              ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              : DropdownButton<String>(
                  value: _isOtherCity ? 'Other' : _selectedCity,
                  hint: Text('Select your city', style: TextStyle(color: AppTheme.neutral400)),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.navy),
                  items: [
                    ..._cities.map((city) => DropdownMenuItem(
                      value: city['name'] as String,
                      child: Text(city['name'] as String),
                    )),
                    const DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other (type below)', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ],
                  onChanged: _onCityChanged,
                ),
          ),
        ),
        if (_isOtherCity) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              hintText: 'Enter city name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.neutral200),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onChanged: (val) => _notifyChanges(),
          ),
        ],
      ],
    );
  }

  Widget _buildSuburbField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suburb / Area',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingSuburbs && !_isOtherCity)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_isOtherCity || _suburbs.isEmpty)
          TextField(
            controller: _suburbController,
            decoration: InputDecoration(
              hintText: 'Enter suburb name...',
              prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.neutral400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.neutral200),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onChanged: _onCustomSuburbChanged,
          )
        else ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neutral200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _isOtherSuburb ? 'Other' : _selectedSuburb,
                hint: Text('Select suburb', style: TextStyle(color: AppTheme.neutral400)),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: AppTheme.navy),
                items: [
                  ..._suburbs.map((s) {
                    final name = s['name'] as String? ?? 'Unknown';
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }),
                  const DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other (type below)', style: TextStyle(fontStyle: FontStyle.italic)),
                  ),
                ],
                onChanged: _onSuburbChanged,
              ),
            ),
          ),
          if (_isOtherSuburb) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _suburbController,
              decoration: InputDecoration(
                hintText: 'Enter suburb name...',
                prefixIcon: Icon(Icons.edit_location, color: AppTheme.neutral400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.neutral200),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onChanged: _onCustomSuburbChanged,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildMap() {
    final defaultCenter = _pinPosition ?? LatLng(-17.8252, 31.0335);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pin Your Exact Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.navy,
              ),
            ),
            const Spacer(),
            if (!_locationConfirmed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Tap map to set',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap on the map or drag the pin to your exact location.',
          style: TextStyle(fontSize: 12, color: AppTheme.neutral500),
        ),
        const SizedBox(height: 12),
        
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: _locationConfirmed ? AppTheme.success.withOpacity(0.5) : AppTheme.neutral200,
                width: 1,
              ),
            ),
          ),
          child: Stack(
            children: [
              DynamicMap(
                initialCenter: defaultCenter,
                initialZoom: _pinPosition != null ? 15.0 : 12.0,
                osmController: _mapController,
                markers: _pinPosition != null ? [DynamicMarker(id: 'pin', point: _pinPosition!)] : [],
                onTap: (latLng) => _onMapTap(latLng),
                onGoogleMapCreated: (controller) {
                  if (_pinPosition != null) {
                    controller.animateCamera(
                      google.CameraUpdate.newLatLngZoom(
                        google.LatLng(_pinPosition!.latitude, _pinPosition!.longitude),
                        15.0,
                      ),
                    );
                  }
                },
              ),
              
              // City indicator
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        _isOtherCity 
                            ? (_cityController.text.isEmpty ? 'Custom City' : _cityController.text)
                            : (_selectedCity ?? 'Harare'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navy),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Coordinates
              if (_pinPosition != null)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_pinPosition!.latitude.toStringAsFixed(5)}, ${_pinPosition!.longitude.toStringAsFixed(5)}',
                      style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              
              // Loading overlay
              if (_isLocating)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Address Details (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressDetailsController,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'e.g., 123 Main Street, near OK Supermarket',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.neutral200),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          minLines: 2,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildConfirmationBadge() {
    final suburb = _isOtherSuburb ? _suburbController.text.trim() : _selectedSuburb;
    final city = _isOtherCity ? _cityController.text.trim() : _selectedCity;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Location set: ${suburb ?? ''}, ${city ?? ''}',
              style: TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
