import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Field Camera Service - Handles photo capture with date/location stamps
/// Used by all field tools that require camera functionality
class FieldCameraService {
  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // CAPTURE WITH METADATA
  // ============================================================

  /// Capture a photo and return with metadata
  Future<CapturedPhoto?> capturePhoto({
    bool addDateStamp = true,
    bool addLocationStamp = true,
    ImageSource source = ImageSource.camera,
    int imageQuality = 85,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final now = DateTime.now();

      // Get location if requested
      Position? position;
      String? address;
      if (addLocationStamp) {
        position = await _getCurrentPosition();
        if (position != null) {
          address = await _getAddressFromPosition(position);
        }
      }

      return CapturedPhoto(
        bytes: bytes,
        fileName: image.name,
        capturedAt: now,
        latitude: position?.latitude,
        longitude: position?.longitude,
        address: address,
        accuracy: position?.accuracy,
        altitude: position?.altitude,
      );
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return null;
    }
  }

  /// Capture multiple photos
  Future<List<CapturedPhoto>> captureMultiplePhotos({
    bool addDateStamp = true,
    bool addLocationStamp = true,
    int imageQuality = 85,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isEmpty) return [];

      final now = DateTime.now();
      Position? position;
      String? address;

      if (addLocationStamp) {
        position = await _getCurrentPosition();
        if (position != null) {
          address = await _getAddressFromPosition(position);
        }
      }

      final photos = <CapturedPhoto>[];
      for (final image in images) {
        final bytes = await image.readAsBytes();
        photos.add(CapturedPhoto(
          bytes: bytes,
          fileName: image.name,
          capturedAt: now,
          latitude: position?.latitude,
          longitude: position?.longitude,
          address: address,
          accuracy: position?.accuracy,
          altitude: position?.altitude,
        ));
      }

      return photos;
    } catch (e) {
      debugPrint('Error capturing photos: $e');
      return [];
    }
  }

  // ============================================================
  // LOCATION SERVICES
  // ============================================================

  /// Get current GPS position
  Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled');
        return null;
      }

      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }

      // Get position with high accuracy
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Reverse geocode position to address
  Future<String?> _getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];

        if (place.street?.isNotEmpty ?? false) parts.add(place.street!);
        if (place.locality?.isNotEmpty ?? false) parts.add(place.locality!);
        if (place.administrativeArea?.isNotEmpty ?? false) parts.add(place.administrativeArea!);

        return parts.join(', ');
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  /// Get current location without photo
  Future<LocationData?> getCurrentLocation() async {
    final position = await _getCurrentPosition();
    if (position == null) return null;

    final address = await _getAddressFromPosition(position);

    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      address: address,
      timestamp: DateTime.now(),
    );
  }

  // ============================================================
  // STAMP OVERLAY RENDERING
  // ============================================================

  /// Generate a date/location stamp overlay image
  /// Returns the stamp as a transparent PNG that can be composited
  static Future<Uint8List?> generateStampOverlay({
    required int width,
    required int height,
    required DateTime timestamp,
    String? address,
    double? latitude,
    double? longitude,
    String? projectName,
    StampPosition position = StampPosition.bottomRight,
    StampStyle style = StampStyle.standard,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(width.toDouble(), height.toDouble());

      // Calculate stamp dimensions
      final stampHeight = height * 0.12; // 12% of image height
      final padding = stampHeight * 0.15;
      final fontSize = stampHeight * 0.22;

      // Build stamp text lines
      final lines = <String>[];

      // Line 1: Date and time
      final dateFormat = DateFormat('MMM d, yyyy  h:mm a');
      lines.add(dateFormat.format(timestamp));

      // Line 2: Address or coordinates
      if (address != null && address.isNotEmpty) {
        lines.add(address);
      } else if (latitude != null && longitude != null) {
        lines.add('${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}');
      }

      // Line 3: Project name if provided
      if (projectName != null && projectName.isNotEmpty) {
        lines.add(projectName);
      }

      // Calculate stamp box size
      final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
      double maxTextWidth = 0;

      for (final line in lines) {
        textPainter.text = TextSpan(
          text: line,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        );
        textPainter.layout();
        if (textPainter.width > maxTextWidth) {
          maxTextWidth = textPainter.width;
        }
      }

      final stampWidth = maxTextWidth + padding * 2;
      final totalStampHeight = (fontSize * 1.4 * lines.length) + padding * 2;

      // Calculate position
      double left, top;
      switch (position) {
        case StampPosition.topLeft:
          left = padding;
          top = padding;
          break;
        case StampPosition.topRight:
          left = size.width - stampWidth - padding;
          top = padding;
          break;
        case StampPosition.bottomLeft:
          left = padding;
          top = size.height - totalStampHeight - padding;
          break;
        case StampPosition.bottomRight:
          left = size.width - stampWidth - padding;
          top = size.height - totalStampHeight - padding;
          break;
      }

      // Draw background
      final bgPaint = Paint()
        ..color = style == StampStyle.standard
            ? const Color(0xCC000000) // Semi-transparent black
            : const Color(0xCCFFD700); // Semi-transparent yellow

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, stampWidth, totalStampHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(bgRect, bgPaint);

      // Draw text
      final textColor = style == StampStyle.standard
          ? Colors.white
          : Colors.black;

      double yOffset = top + padding;
      for (final line in lines) {
        final span = TextSpan(
          text: line,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.5,
          ),
        );
        textPainter.text = span;
        textPainter.layout();
        textPainter.paint(canvas, Offset(left + padding, yOffset));
        yOffset += fontSize * 1.4;
      }

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error generating stamp: $e');
      return null;
    }
  }

  // ============================================================
  // DATE/TIME FORMATTING UTILITIES
  // ============================================================

  /// Format timestamp for display
  static String formatTimestamp(DateTime dt) {
    return DateFormat('MMM d, yyyy  h:mm a').format(dt);
  }

  /// Format date only
  static String formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }

  /// Format time only
  static String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  /// Format coordinates for display
  static String formatCoordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(6)}$latDir, ${lng.abs().toStringAsFixed(6)}$lngDir';
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

/// Captured photo with metadata
class CapturedPhoto {
  final Uint8List bytes;
  final String fileName;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double? accuracy; // GPS accuracy in meters
  final double? altitude;

  const CapturedPhoto({
    required this.bytes,
    required this.fileName,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.address,
    this.accuracy,
    this.altitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String get locationDisplay {
    if (address != null && address!.isNotEmpty) return address!;
    if (hasLocation) {
      return FieldCameraService.formatCoordinates(latitude!, longitude!);
    }
    return 'No location';
  }

  String get timestampDisplay => FieldCameraService.formatTimestamp(capturedAt);
}

/// Location data without photo
class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final String? address;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.address,
    required this.timestamp,
  });

  String get coordinatesDisplay =>
      FieldCameraService.formatCoordinates(latitude, longitude);
}

/// Stamp position on image
enum StampPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Stamp visual style
enum StampStyle {
  standard, // Black bg, white text
  hazard,   // Yellow bg, black text (matches Zafto brand)
}

// ============================================================
// PROVIDERS
// ============================================================

/// Provider for FieldCameraService
final fieldCameraServiceProvider = Provider<FieldCameraService>((ref) {
  return FieldCameraService();
});

/// Provider for current location
final currentLocationProvider = FutureProvider<LocationData?>((ref) {
  return ref.watch(fieldCameraServiceProvider).getCurrentLocation();
});
