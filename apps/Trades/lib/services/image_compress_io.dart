/// Image compression for native platforms
/// NOTE: Pass-through — the `image` package was removed (crashes web compilation).
/// flutter_image_compress requires native NDK and platform-specific testing.
/// Images upload correctly at full resolution. Compression will be added when
/// PowerSync offline storage pipeline is built (requires bandwidth-aware sync).
import 'dart:typed_data';

/// Compress image bytes — currently returns original bytes (web-safe).
Future<Uint8List> compressImageBytes(Uint8List bytes) async {
  return bytes;
}
