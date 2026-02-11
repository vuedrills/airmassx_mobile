import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'location_disclaimer_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../services/geocoding_service.dart';
import '../../services/api_service.dart';
import '../core/service_locator.dart';
import 'dynamic_map.dart';
import '../bloc/map_settings/map_settings_cubit.dart';
import '../utils/location_permission_helper.dart';

/// Zimbabwe cities with coordinates
class ZimbabweCity {
  final String name;
  final double lat;
  final double lng;
  
  const ZimbabweCity(this.name, this.lat, this.lng);
}

const List<ZimbabweCity> ZIMBABWE_CITIES = [
  ZimbabweCity('Harare', -17.8252, 31.0335),
  ZimbabweCity('Bulawayo', -20.1325, 28.5262),
  ZimbabweCity('Chitungwiza', -18.0127, 31.0755),
  ZimbabweCity('Mutare', -18.9707, 32.6509),
  ZimbabweCity('Gweru', -19.4500, 29.8167),
  ZimbabweCity('Kwekwe', -18.9281, 29.8149),
  ZimbabweCity('Kadoma', -18.3333, 29.9167),
  ZimbabweCity('Masvingo', -20.0744, 30.8328),
  ZimbabweCity('Chinhoyi', -17.3667, 30.2000),
  ZimbabweCity('Marondera', -18.1853, 31.5519),
  ZimbabweCity('Victoria Falls', -17.9244, 25.8567),
  ZimbabweCity('Hwange', -18.3647, 25.9964),
  ZimbabweCity('Zvishavane', -20.3333, 30.0333),
  ZimbabweCity('Kariba', -16.5167, 28.8000),
  ZimbabweCity('Beitbridge', -22.2167, 30.0000),
  ZimbabweCity('Bindura', -17.3000, 31.3333),
  ZimbabweCity('Rusape', -18.5333, 32.1333),
  ZimbabweCity('Chiredzi', -21.0500, 31.6667),
  ZimbabweCity('Norton', -17.8833, 30.7000),
];

/// Enhanced location picker with city dropdown + suburb search + map
class EnhancedLocationPicker extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;
  final String? initialCity;
  final String? hintText;
  final double? height;
  final Function(EnhancedLocationResult) onLocationSelected;

  const EnhancedLocationPicker({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
    this.initialCity,
    this.hintText,
    this.height = 500,
    required this.onLocationSelected,
  });

  @override
  State<EnhancedLocationPicker> createState() => _EnhancedLocationPickerState();
}

class EnhancedLocationResult {
  final String city;
  final String suburb;
  final String addressDetails;
  final double latitude;
  final double longitude;
  final String fullAddress;

  EnhancedLocationResult({
    required this.city,
    required this.suburb,
    required this.addressDetails,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });
}

class _EnhancedLocationPickerState extends State<EnhancedLocationPicker> {
  final _geocodingService = GeocodingService();
  final _suburbController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressDetailsController = TextEditingController();
  final _googleSearchController = TextEditingController();
  final _mapController = MapController();
  google.GoogleMapController? _googleMapController;
  
  String? _selectedCity;
  String? _selectedCityId;
  String? _selectedSuburb;
  bool _isOtherSuburb = false;
  bool _isOtherCity = false;
  LatLng? _pinPosition;
  bool _isSearching = false;
  bool _isLocating = false;
  bool _hasConfirmedPin = false;
  List<Marker> _markers = [];
  
  // Curated data from API
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _suburbs = [];
  bool _isLoadingCities = true;
  bool _isLoadingSuburbs = false;
  
  // Debounce
  Timer? _debounceTimer;
  
  // Google Search Results
  List<PlaceResult> _googleSearchResults = [];
  bool _showGoogleResults = false;
  String? _currentSessionToken;
  final _uuid = const Uuid();
  Timer? _reverseGeocodeTimer;
  bool _initialLoad = true;
  bool _manuallyMoved = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    if (widget.initialLat != null && widget.initialLng != null) {
      _pinPosition = LatLng(widget.initialLat!, widget.initialLng!);
      _updateMarker(_pinPosition!);
    } else if (_selectedCity != null) {
      // If we have a city but no coordinates yet, we'll wait for _loadCities to center the map
    }
    _loadCities();
    
    // Auto-notify on text changes
    _suburbController.addListener(_notifyChanges);
    _addressDetailsController.addListener(_notifyChanges);
    
    // Force refresh settings to ensure we have the latest toggle value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MapSettingsCubit>().loadSettings();
    });
  }

  void _notifyChanges() {
    final city = _isOtherCity ? _cityController.text.trim() : _selectedCity;
    final suburb = _isOtherSuburb ? _suburbController.text.trim() : _selectedSuburb;

    if (city == null || city.isEmpty || suburb == null || suburb.isEmpty || _pinPosition == null) {
      return;
    }
    
    // Check if we are in "Other" mode and the text field is empty
    if (_isOtherSuburb && _suburbController.text.trim().isEmpty) {
      return;
    }

    final fullAddress = [
      suburb,
      city,
      if (_addressDetailsController.text.trim().isNotEmpty) _addressDetailsController.text.trim(),
    ].join(', ');

    widget.onLocationSelected(EnhancedLocationResult(
      city: city,
      suburb: suburb,
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
        
        // Default to Harare if no initial city selected
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
          
          final lat = (harare['latitude'] as num?)?.toDouble() ?? -17.8252;
          final lng = (harare['longitude'] as num?)?.toDouble() ?? 31.0335;
          
          // Only overwrite pin if not set by props
          if (_pinPosition == null) {
             _pinPosition = LatLng(lat, lng);
             _updateMarker(_pinPosition!);
          }

          // Center map logic
          if (_pinPosition != null) {
             _moveMapTo(_pinPosition!);
          }
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
  
  void _moveMapTo(LatLng pos) {
      // Move Flutter Map (OSM)
      try {
        _mapController.move(pos, 13.0);
      } catch (e) {
        // Map controller might not be ready
      }
      
      // Move Google Map
      _googleMapController?.animateCamera(
        google.CameraUpdate.newLatLngZoom(
          google.LatLng(pos.latitude, pos.longitude), 
          15.0
        )
      );
  }

  Future<void> _loadSuburbs(String cityId) async {
    setState(() => _isLoadingSuburbs = true);
    final apiService = getIt<ApiService>();
    final suburbs = await apiService.getLocations(type: 'suburb', parentId: cityId);
    if (mounted) {
      setState(() {
        _suburbs = suburbs;
        _isLoadingSuburbs = false;
        
        if (_selectedSuburb != null) {
          final exists = suburbs.any((s) => (s['name'] as String).toLowerCase() == _selectedSuburb!.toLowerCase());
          if (!exists) {
            _isOtherSuburb = true;
          } else {
            _selectedSuburb = suburbs.firstWhere((s) => (s['name'] as String).toLowerCase() == _selectedSuburb!.toLowerCase())['name'];
            _isOtherSuburb = false;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _suburbController.dispose();
    _cityController.dispose();
    _addressDetailsController.dispose();
    _googleSearchController.dispose();
    _debounceTimer?.cancel();
    _reverseGeocodeTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedCityData => 
    _selectedCity != null && _cities.isNotEmpty
      ? _cities.firstWhere((c) => c['name'] == _selectedCity, orElse: () => _cities.first)
      : null;

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
      });
      _notifyChanges();
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
      _hasConfirmedPin = false;
      _suburbController.clear();
      _updateMarker(_pinPosition!);
      _notifyChanges();
    });
    
    _loadSuburbs(cityData['id']);
    _moveMapTo(_pinPosition!);
  }

  void _onSuburbChanged(String? suburb) {
    if (suburb == null) return;
    
    if (suburb == 'Other') {
      setState(() {
        _isOtherSuburb = true;
        _selectedSuburb = null;
      });
      _notifyChanges();
      return;
    }
    
    final suburbData = _suburbs.firstWhere((s) => s['name'] == suburb, orElse: () => <String, dynamic>{});
    
    setState(() {
      _isOtherSuburb = false;
      _selectedSuburb = suburb;
      _suburbController.text = suburb;
      _notifyChanges();
    });
    
    if (suburbData.isNotEmpty && suburbData['latitude'] != null && suburbData['longitude'] != null) {
      final lat = suburbData['latitude'] as double;
      final lng = suburbData['longitude'] as double;
      setState(() {
        _pinPosition = LatLng(lat, lng);
        _hasConfirmedPin = false;
        _updateMarker(_pinPosition!);
      });
      _moveMapTo(_pinPosition!);
    }
  }

  Future<void> _searchSuburb() async {
    if (_suburbController.text.isEmpty || _selectedCity == null) return;
    
    setState(() => _isSearching = true);
    
    try {
      final query = '${_suburbController.text}, $_selectedCity, Zimbabwe';
      final results = await _geocodingService.searchPlaces(query);
      
      if (results.isNotEmpty && mounted) {
        final result = results.first;
        final newPosition = LatLng(result.lat, result.lng);
        setState(() {
          _pinPosition = newPosition;
          _hasConfirmedPin = false;
          _updateMarker(newPosition);
        });
        _moveMapTo(newPosition);
      }
    } catch (e) {
      debugPrint('Suburb search failed: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // --- Google Search Logic ---
   void _onGoogleSearchChanged(String query) {
     if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

     // Invalidate current selection while user is typing
     // This ensures they must select a suggestion or move the map to get valid coords
     if (query.isNotEmpty) {
       widget.onLocationSelected(EnhancedLocationResult(
         city: '',
         suburb: '',
         addressDetails: '',
         latitude: 0,
         longitude: 0,
         fullAddress: '',
       ));
     }

     _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (query.length > 2) {
           // Start a new session if we don't have one
           _currentSessionToken ??= _uuid.v4();
           _performGoogleSearch(query);
        } else {
           _currentSessionToken = null; // Clear if search is cleared
           setState(() => _showGoogleResults = false);
        }
     });
   }

  Future<void> _performGoogleSearch(String query) async {
      try {
          final results = await _geocodingService.searchPlaces(query, sessionToken: _currentSessionToken);
          if (mounted) {
             setState(() {
                _googleSearchResults = results;
                // Always show results container if we have query > 2, so we can show "Use pin location"
                _showGoogleResults = true;
             });
          }
      } catch (e) {
          debugPrint('Google Search Error: $e');
      }
  }

  Future<void> _selectGooglePlace(PlaceResult place) async {
       setState(() {
          _showGoogleResults = false;
          _googleSearchController.text = place.displayName;
          _currentSessionToken = null; // Consume token
       });
       
       // For Google Places, we might lack coordinates if we only did Autocomplete.
       // Ideally we do GetPlaceDetails. But for now if lat/lng is 0, we can fallback or alert.
       // Current GeocodingService implementation for Autocomplete returns 0,0 placeholders.
       // We'll trust the user to pan the map which updates coordinates.
       
       // However, to be useful, we need to geocode the name if coords are missing.
       if (place.lat == 0 && place.lng == 0) {
           if (place.placeId != null) {
               final details = await _geocodingService.getGooglePlaceDetails(place.placeId!);
               if (details != null && mounted) {
                   final pos = LatLng(details.lat, details.lng);
                   setState(() {
                      _pinPosition = pos;
                   });
                   _moveMapTo(pos);
                   return;
               }
           }
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Drag map to exact location")));
       } else {
           final pos = LatLng(place.lat, place.lng);
           setState(() {
              _pinPosition = pos;
           });
           _moveMapTo(pos);
       }
       
       // Also try to populate address fields from the result
       // The user will confirm via the button
  }

  Future<void> _useCurrentLocation() async {
    // Check permission status via helper
    final permission = await LocationPermissionHelper.checkAndRequestPermission(context);
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
       return;
    }

    setState(() => _isLocating = true);
    
    final position = await _geocodingService.getCurrentLocation();
    
    if (position == null) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get current location. Please enable GPS.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    final latLng = LatLng(position.latitude, position.longitude);
    
    // Reverse geocode
    final reverseResult = await _geocodingService.reverseGeocode(position.latitude, position.longitude);
    
    if (mounted) {
      setState(() {
        _pinPosition = latLng;
        _hasConfirmedPin = false;
        _updateMarker(latLng);
        
        if (reverseResult != null) {
          // Logic to pre-fill form fields (Osm Form)
          if (reverseResult.city != null) {
             // Try to match city
             final cityMatch = _cities.firstWhere(
               (c) => (c['name'] as String).toLowerCase() == reverseResult.city!.toLowerCase(),
               orElse: () => <String, dynamic>{},
             );
             
             if (cityMatch.isNotEmpty) {
               _selectedCity = cityMatch['name'];
               _selectedCityId = cityMatch['id'];
               _isOtherCity = false;
               _loadSuburbs(_selectedCityId!); 
             } else {
               _isOtherCity = true;
               _selectedCity = null;
               _cityController.text = reverseResult.city!;
             }
          } 
          
          if (reverseResult.suburb != null) {
             final String gpsSuburb = reverseResult.suburb!;
             // Try to match in existing list if loaded
             final match = _suburbs.firstWhere(
               (s) => (s['name'] as String).toLowerCase() == gpsSuburb.toLowerCase(),
               orElse: () => <String, dynamic>{},
             );
             
             if (match.isNotEmpty) {
                _selectedSuburb = match['name'];
                _suburbController.text = _selectedSuburb!;
                _isOtherSuburb = false;
             } else {
                _isOtherSuburb = true;
                _selectedSuburb = null;
                _suburbController.text = gpsSuburb;
             }
          }
          
          // Pre-fill Google Form field
          _googleSearchController.text = reverseResult.displayName;
        }
        
        _isLocating = false;
        _notifyChanges(); // Trigger update
      });
      _moveMapTo(latLng);
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pinPosition = position;
      _hasConfirmedPin = false;
      _updateMarker(position);
      _notifyChanges();
    });
  }
  
  void _onGoogleCameraIdle() async {
      // Called when map stops moving
      // We can reverse geocode center to get address text for the search bar?
      // Optional enhancement.
  }

  void _updateMarker(LatLng position) {
    _markers = [
      Marker(
        point: position,
        width: 50,
        height: 50,
        child: Icon(
          Icons.location_pin,
          color: AppTheme.primary,
          size: 50,
        ),
      ),
    ];
  }

  String? _decodedAddress;
  bool _isReverseGeocoding = false;

  void _reverseGeocodeCurrentPosition() async {
      if (_pinPosition == null || _isReverseGeocoding) return;
      
      // Don't auto-fill if we haven't manually moved or if we're still in initial load
      // This prevents the search bar from being filled with the default Harare address on start
      if (!_manuallyMoved || _initialLoad) return;
      
      setState(() => _isReverseGeocoding = true);
      
      try {
        final reverseResult = await _geocodingService.reverseGeocode(_pinPosition!.latitude, _pinPosition!.longitude);
        
        if (mounted && reverseResult != null) {
          final city = reverseResult.city ?? '';
          final suburb = reverseResult.suburb ?? '';
          final full = reverseResult.displayName ?? 
              (suburb.isNotEmpty ? (city.isNotEmpty ? '$suburb, $city' : suburb) : city);
          
          setState(() {
            _decodedAddress = full;
            _googleSearchController.text = full;
            _hasConfirmedPin = true;
          });
          
          widget.onLocationSelected(EnhancedLocationResult(
            city: city,
            suburb: suburb,
            addressDetails: _addressDetailsController.text,
            latitude: _pinPosition!.latitude,
            longitude: _pinPosition!.longitude,
            fullAddress: full,
          ));
        }
      } catch (e) {
        debugPrint('Reverse geocode failed: $e');
        // Still mark as confirmed even if geocoding fails
        if (mounted) {
          setState(() => _hasConfirmedPin = true);
        }
      } finally {
        if (mounted) {
          setState(() => _isReverseGeocoding = false);
        }
      }
  }

  void _confirmGoogleLocation() async {
      _reverseGeocodeCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
      Widget picker = BlocBuilder<MapSettingsCubit, MapSettingsState>(
          builder: (context, state) {
              if (state.provider == MapProvider.google) {
                  return _buildGoogleInterface();
              }
              return _buildOsmForm();
          },
      );

      if (widget.height != null) {
          return SizedBox(height: widget.height, child: picker);
      }
      return picker;
  }

  // --- GOOGLE INTERFACE (UBER STYLE) ---
  Widget _buildGoogleInterface() {
      return Stack(
          children: [
               // Full Screen Map
               DynamicMap(
                initialCenter: _pinPosition ?? LatLng(-17.8252, 31.0335),
                initialZoom: 15.0,
                osmController: _mapController, // Not used but required
                markers: [], // We use center pin, not markers on map
                onTap: (pos) {}, // Disable tap in favor of pan
                onGoogleMapCreated: (controller) {
                    _googleMapController = controller;
                    if (_pinPosition != null) {
                         controller.moveCamera(google.CameraUpdate.newLatLng(
                             google.LatLng(_pinPosition!.latitude, _pinPosition!.longitude)
                         ));
                    }
                },
                onCameraMove: (pos) {
                    setState(() {
                      _pinPosition = pos;
                      _hasConfirmedPin = false; // Reset when user moves map
                    });
                    
                    // Debounce reverse geocoding
                    _reverseGeocodeTimer?.cancel();
                    
                    // Skip reverse geocode on initial load/map setup
                    if (_initialLoad) {
                        // After entry, we wait for the first real movement
                        _initialLoad = false;
                        return;
                    }

                    _reverseGeocodeTimer = Timer(const Duration(milliseconds: 1000), () {
                        if (mounted) {
                            setState(() => _manuallyMoved = true);
                            _confirmGoogleLocation();
                        }
                    });
                },
               ),
               
               // Center Pin (Fixed)
               Center(
                   child: Padding(
                       padding: const EdgeInsets.only(bottom: 50), // Adjust for pin tip
                       child: Icon(Icons.location_pin, size: 50, color: AppTheme.primary),
                   ),
               ),
               
               // Top Search Bar
               Positioned(
                   top: 0,
                   left: 0,
                   right: 0,
                   child: SafeArea(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       child: Column(
                       children: [
                           Container(
                               decoration: BoxDecoration(
                                   color: Colors.white,
                                   borderRadius: BorderRadius.circular(8),
                                   boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
                               ),
                               child: TextField(
                                   controller: _googleSearchController,
                                   decoration: InputDecoration(
                                       hintText: "Search location...",
                                       prefixIcon: const Icon(Icons.search),
                                       border: InputBorder.none,
                                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                       suffixIcon: _isLocating 
                                         ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                                         : IconButton(icon: const Icon(Icons.my_location), onPressed: _useCurrentLocation)
                                   ),
                                   onChanged: _onGoogleSearchChanged,
                               ),
                           ),
                           if (_showGoogleResults) 
                               Container(
                                   margin: const EdgeInsets.only(top: 4),
                                   decoration: BoxDecoration(
                                       color: Colors.white,
                                       borderRadius: BorderRadius.circular(8),
                                       boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
                                   ),
                                   child: Column(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       if (_googleSearchResults.isNotEmpty)
                                         ListView.builder(
                                             shrinkWrap: true,
                                             padding: EdgeInsets.zero,
                                             itemCount: _googleSearchResults.length,
                                             itemBuilder: (context, index) {
                                                 final place = _googleSearchResults[index];
                                                 return ListTile(
                                                     title: Text(place.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                     subtitle: Text(place.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                                                     leading: const Icon(Icons.place, size: 20),
                                                     onTap: () => _selectGooglePlace(place),
                                                 );
                                             },
                                         ),
                                        // Add "Use pin location" option
                                       if (_googleSearchController.text.isNotEmpty)
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                               if (_googleSearchResults.isNotEmpty) const Divider(height: 1),
                                               ListTile(
                                                 title: const Text("Use location on map", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                                 subtitle: Text("Use '${_googleSearchController.text}' at current pin position", maxLines: 1, overflow: TextOverflow.ellipsis),
                                                 leading: const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                                                 onTap: () {
                                                     setState(() {
                                                       _showGoogleResults = false;
                                                       _currentSessionToken = null;
                                                     });
                                                     
                                                     if (_pinPosition != null) {
                                                         // Explicitly set the result using typed text + pin coords
                                                         widget.onLocationSelected(EnhancedLocationResult(
                                                           city: '', // Backend caninfer
                                                           suburb: '',
                                                           addressDetails: '',
                                                           latitude: _pinPosition!.latitude,
                                                           longitude: _pinPosition!.longitude,
                                                           fullAddress: _googleSearchController.text,
                                                         ));
                                                         
                                                         setState(() => _hasConfirmedPin = true);
                                                     }
                                                 },
                                               ),
                                            ],
                                          ),
                                     ],
                                   ),
                               )
                       ],
                   ),
               ),
             ),
           ),
               // Bottom Coordinates Display
                Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: SafeArea(
                      bottom: true,
                      top: false,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Coordinates Display
                            if (_pinPosition != null)
                              Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: _hasConfirmedPin ? AppTheme.navy : Colors.black87,
                                      borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isReverseGeocoding)
                                        const SizedBox(
                                          width: 14, height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      else if (_hasConfirmedPin)
                                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16)
                                      else
                                        const Icon(Icons.location_on, color: Colors.white, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                          "${_pinPosition!.latitude.toStringAsFixed(5)}, ${_pinPosition!.longitude.toStringAsFixed(5)}",
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                              ),
                          ],
                      ),
                    ),
                )
          ],
      );
  }


  // --- ORIGINAL OSM FORM ---
  Widget _buildOsmForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24), // Added padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City Selection
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
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
                  ),
                ),
                if (_selectedCity != null || _isOtherCity) ...[
                  const SizedBox(width: 12),
                  // GPS Button moved here to be inline with City
                  InkWell(
                    onTap: _isLocating ? null : _useCurrentLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: _isLocating
                          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                          : Icon(Icons.my_location, color: AppTheme.primary, size: 24),
                    ),
                  ),
                ],
              ],
            ),
            
            if (_selectedCity != null || _isOtherCity) ...[
            const SizedBox(height: 20),
            
            // Suburb Selection
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
              // No suburbs found - show text field
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
                onChanged: (val) {
                  _notifyChanges();
                  if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                     _searchSuburb();
                  });
                },
              )
            else ...[
              // Dropdown with suburbs
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
                  onChanged: (val) {
                    _notifyChanges();
                    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                       _searchSuburb();
                    });
                  },
                ),
              ],
            ],
            
            const SizedBox(height: 20),
            
            // Map
            Text(
              'Pin Your Exact Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap on the map or drag the pin to your exact location.',
              style: TextStyle(fontSize: 12, color: AppTheme.neutral500),
            ),
            const SizedBox(height: 12),
            
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.neutral200),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.05),
                     blurRadius: 10,
                     spreadRadius: 0,
                     offset: const Offset(0, 4), 
                   ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                children: [
                  DynamicMap(
                    initialCenter: _pinPosition ?? LatLng(
                      _selectedCityData?['latitude'] as double? ?? -17.8252,
                      _selectedCityData?['longitude'] as double? ?? 31.0335,
                    ),
                    initialZoom: _pinPosition != null ? 15.0 : 13.0,
                    osmController: _mapController,
                    markers: _pinPosition != null ? [DynamicMarker(id: 'pin', point: _pinPosition!)] : [],
                    onTap: (latLng) => _onMapTap(latLng),
                    onGoogleMapCreated: (controller) {
                      _googleMapController = controller;
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
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
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
            ),
            
            const SizedBox(height: 20),
            
            // Address Details
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
            
            const SizedBox(height: 40), // Extra space at bottom
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildGpsButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Locate',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.navy,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isLocating ? null : _useCurrentLocation,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.neutral200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLocating)
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                else
                  Icon(Icons.navigation, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text('GPS', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
