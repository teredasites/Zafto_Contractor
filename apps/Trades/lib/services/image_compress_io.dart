/// Image compression for native platforms
/// NOTE: Disabled for web compatibility - image package uses dart:io
import 'dart:typed_data';

/// Compress image bytes (native only) - currently passes through
/// TODO: Re-enable when we have a web-compatible compression solution
Future<Uint8List> compressImageBytes(Uint8List bytes) async {
  // Skip compression for now - return original bytes
  // The image package causes dart:io issues on web compilation
  return bytes;
}
