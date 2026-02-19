import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../widgets/location_disclaimer_dialog.dart';

class LocationPermissionHelper {
  /// Full pre-flight check: ensures location services are on AND permission is granted.
  /// 
  /// Flow:
  /// 1. Check if device GPS/location services are enabled → prompt to enable if not.
  /// 2. Check if app has location permission → show disclosure + request if not.
  /// 3. Handle "denied forever" → guide user to app settings.
  /// 
  /// Returns the final permission status.
  static Future<LocationPermission> checkAndRequestPermission(BuildContext context) async {
    // ─── Step 1: Check if location services (GPS) are turned on ───
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return LocationPermission.denied;

      final bool? userWantsToEnable = await _showEnableLocationServicesDialog(context);

      if (userWantsToEnable == true) {
        // Open device location settings
        await Geolocator.openLocationSettings();

        // Wait a moment for the user to return, then re-check
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are needed to get your current location.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return LocationPermission.denied;
      }
    }

    // ─── Step 2: Check current permission status ───
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      return permission;
    }

    // ─── Step 3: If denied (but not forever), show disclosure then request ───
    if (permission == LocationPermission.denied) {
      if (!context.mounted) return permission;

      final bool? accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LocationDisclaimerDialog(),
      );

      if (accepted != true) {
        return LocationPermission.denied;
      }

      permission = await Geolocator.requestPermission();
    }
    
    // ─── Step 4: Handle "denied forever" → guide to app settings ───
    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return permission;

      final bool? openSettings = await _showDeniedForeverDialog(context);
      if (openSettings == true) {
        await Geolocator.openAppSettings();
      }
    }

    return permission;
  }

  // ─── Dialog: Enable Location Services (GPS) ───

  static Future<bool?> _showEnableLocationServicesDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.location_off_rounded, color: AppTheme.primary, size: 36),
        ),
        title: const Text(
          'Location Services Disabled',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.navy,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Airmass Xpress uses your device\'s GPS to get your current location. This is used to set your primary location so we can show you jobs and tasks nearby.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Go to Settings → Turn on Location/GPS',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dialog: Permission Denied Forever ───

  static Future<bool?> _showDeniedForeverDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.block_rounded, color: Colors.orange, size: 36),
        ),
        title: const Text(
          'Permission Required',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.navy,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Location permission was permanently denied. Please enable it in your device settings so we can get your current location and show you nearby jobs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Settings → Airmass Xpress → Location → Allow',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
