import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/location_disclaimer_dialog.dart';

class LocationPermissionHelper {
  /// Check and request location permission with a mandatory disclaimer dialog
  /// before showing the system permission prompt if permission is denied.
  /// 
  /// Returns the final permission status.
  static Future<LocationPermission> checkAndRequestPermission(BuildContext context) async {
    // 1. Check current status
    LocationPermission permission = await Geolocator.checkPermission();
    
    // 2. If already granted, return immediately
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      return permission;
    }

    // 3. If denied (but not forever), show prominent disclosure
    if (permission == LocationPermission.denied) {
      if (!context.mounted) return permission;

      // Show prominent disclosure dialog
      final bool? accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LocationDisclaimerDialog(),
      );

      // If user declined the disclosure, do not request permission
      if (accepted != true) {
        return LocationPermission.denied;
      }

      // 4. Request system permission
      permission = await Geolocator.requestPermission();
    }
    
    // 5. If denied forever, we can't request again, but we return the status
    // The caller might want to show a dialog explaining how to enable it in settings
    
    return permission;
  }
}
