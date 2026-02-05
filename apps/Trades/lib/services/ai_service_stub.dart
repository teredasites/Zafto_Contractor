/// Web stub for file operations (dart:io not available on web)
/// 
/// Provides empty implementations that will show appropriate messages.

import 'dart:typed_data';

/// Read file bytes from path - not supported on web
Future<Uint8List> readFileBytes(String path) async {
  throw UnsupportedError('File operations not supported on web');
}
