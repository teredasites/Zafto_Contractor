/// Image compression stub for web (no-op)
import 'dart:typed_data';

/// Compress image bytes - returns unchanged on web
Future<Uint8List> compressImageBytes(Uint8List bytes) async {
  // No compression on web - AI scanning disabled anyway
  return bytes;
}
