import 'package:geolocator/geolocator.dart';

// ============================================================
// Inspection GPS Service
//
// Captures GPS coordinates for inspection check-in/check-out.
// Handles permissions gracefully — if denied, returns null
// instead of crashing.
// ============================================================

class InspectionGpsService {
  /// Get current position, or null if unavailable/denied.
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Get position with reasonable accuracy and timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      return null; // Graceful — GPS just won't be recorded
    }
  }

  /// Quick lat/lng pair, or null.
  static Future<({double lat, double lng})?> getLatLng() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;
    return (lat: pos.latitude, lng: pos.longitude);
  }
}
