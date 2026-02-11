import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';


import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:latlong2/latlong.dart' as latlong;
import '../bloc/map_settings/map_settings_cubit.dart';
import '../config/theme.dart';

class DynamicMarker {
  final latlong.LatLng point;
  final Widget? child; // For OSM
  final double googleHue; // For Google (e.g. 0.0 for Red, 120.0 for Green)
  final VoidCallback? onTap;
  final String id;
  final double width;
  final double height;
  final Alignment alignment;

  DynamicMarker({
    required this.point,
    required this.id,
    this.child,
    this.googleHue = 0.0,
    this.onTap,
    this.width = 25.0,
    this.height = 25.0,
    this.alignment = Alignment.center,
  });
}

class DynamicMap extends StatefulWidget {
  final latlong.LatLng initialCenter;
  final double initialZoom;
  final Function(latlong.LatLng)? onTap;
  final List<DynamicMarker> markers;
  final osm.MapController? osmController;
  final Function(google.GoogleMapController)? onGoogleMapCreated;
  final Function(latlong.LatLng)? onCameraMove;
  final MapProvider? forceProvider;
  final String? tileUrl;
  final bool showCircle;
  final double circleRadius; // in meters

  const DynamicMap({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.onTap,
    this.markers = const [],
    this.osmController,
    this.onGoogleMapCreated,
    this.onCameraMove,
    this.forceProvider,
    this.tileUrl,
    this.showCircle = false,
    this.circleRadius = 500,
  });

  @override
  State<DynamicMap> createState() => _DynamicMapState();
}

class _DynamicMapState extends State<DynamicMap> {
  Map<double, google.BitmapDescriptor> _customIcons = {};

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
  }

  Future<void> _loadCustomIcons() async {
    final red = await _getCircleBitmap(AppTheme.accentRed);
    final green = await _getCircleBitmap(Colors.green);
    if (mounted) {
      setState(() {
        _customIcons[0.0] = red;
        _customIcons[120.0] = green;
      });
    }
  }

  Future<google.BitmapDescriptor> _getCircleBitmap(Color color) async {
    const double size = 32.0; // Increased recording size for better resolution
    const double displaySize = 12.0; // Desired display size in logical pixels
    
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Scale for high resolution
    final double scale = size / displaySize;
    canvas.scale(scale);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    canvas.drawCircle(const Offset(displaySize / 2, displaySize / 2 + 0.5), displaySize / 2 - 0.5, shadowPaint);

    // White border
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(displaySize / 2, displaySize / 2), displaySize / 2 - 0.5, whitePaint);

    // Inner color
    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(displaySize / 2, displaySize / 2), displaySize / 2 - 2.0, paint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return google.BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }



  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapSettingsCubit, MapSettingsState>(
      builder: (context, state) {
        final currentProvider = widget.forceProvider ?? state.provider;
        if (currentProvider == MapProvider.google) {
          return google.GoogleMap(
            initialCameraPosition: google.CameraPosition(
              target: google.LatLng(widget.initialCenter.latitude, widget.initialCenter.longitude),
              zoom: widget.initialZoom,
            ),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onMapCreated: (controller) {
              if (widget.onGoogleMapCreated != null) {
                widget.onGoogleMapCreated!(controller);
              }
            },
            onCameraMove: (position) {
               if (widget.onCameraMove != null) {
                  widget.onCameraMove!(latlong.LatLng(position.target.latitude, position.target.longitude));
               }
            },
            onTap: (latLng) {
              if (widget.onTap != null) {
                widget.onTap!(latlong.LatLng(latLng.latitude, latLng.longitude));
              }
            },
            markers: widget.markers.map((m) {
              return google.Marker(
                markerId: google.MarkerId(m.id),
                position: google.LatLng(m.point.latitude, m.point.longitude),
                icon: _customIcons[m.googleHue] ?? google.BitmapDescriptor.defaultMarkerWithHue(m.googleHue),
                onTap: m.onTap,
                consumeTapEvents: true, // Prevents auto-centering/moving on click
              );
            }).toSet(),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            mapType: google.MapType.normal,
            circles: widget.showCircle ? {
              google.Circle(
                circleId: const google.CircleId('task_radius'),
                center: google.LatLng(widget.initialCenter.latitude, widget.initialCenter.longitude),
                radius: widget.circleRadius,
                fillColor: AppTheme.primary.withOpacity(0.1),
                strokeColor: AppTheme.primary.withOpacity(0.4),
                strokeWidth: 1,
              ),
            } : {},
          );
        } else {
          return osm.FlutterMap(
            mapController: widget.osmController,
            options: osm.MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
              onTap: widget.onTap != null ? (tapPosition, latLng) => widget.onTap!(latLng) : null,
            ),
            children: [
              osm.TileLayer(
                urlTemplate: widget.tileUrl ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.airmassxpress.mobile',
                maxZoom: 19,
              ),
              osm.MarkerLayer(
                markers: widget.markers.map((m) {
                  return osm.Marker(
                    point: m.point,
                    width: m.width,
                    height: m.height,
                    alignment: m.alignment,
                    child: GestureDetector(
                      onTap: m.onTap,
                      child: m.child ?? Icon(
                        Icons.location_pin,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (widget.showCircle)
                osm.CircleLayer(
                  circles: [
                    osm.CircleMarker(
                      point: widget.initialCenter,
                      radius: widget.circleRadius,
                      useRadiusInMeter: true,
                      color: AppTheme.primary.withOpacity(0.1),
                      borderColor: AppTheme.primary.withOpacity(0.4),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
            ],
          );
        }
      },
    );
  }
}
