/// Web stub for Platform class and exceptions from dart:io
///
/// Since dart:io is not available on web, we provide stub implementations.

import 'dart:typed_data';

class Platform {
  static bool get isIOS => false;
  static bool get isAndroid => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;
  static String get operatingSystem => 'web';
}

/// Stub for SocketException
class SocketException implements Exception {
  final String message;
  final OSError? osError;
  final InternetAddress? address;
  final int? port;
  
  const SocketException(this.message, {this.osError, this.address, this.port});
  
  @override
  String toString() => 'SocketException: $message';
}

/// Stub for OSError
class OSError {
  final String message;
  final int errorCode;
  const OSError([this.message = '', this.errorCode = -1]);
}

/// Stub for InternetAddress
class InternetAddress {
  final String address;
  const InternetAddress(this.address);
  
  /// Stub for rawAddress
  List<int> get rawAddress => [];
  
  /// Stub for lookup - always throws on web
  static Future<List<InternetAddress>> lookup(String host) async {
    throw UnsupportedError('InternetAddress.lookup not supported on web');
  }
}

/// Stub for HttpException
class HttpException implements Exception {
  final String message;
  final Uri? uri;
  
  const HttpException(this.message, {this.uri});
  
  @override
  String toString() => 'HttpException: $message';
}

/// Stub for File class
class File {
  final String path;
  const File(this.path);
  
  Future<bool> exists() async => false;
  
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('File operations not supported on web');
  }
  
  Future<String> readAsString() async {
    throw UnsupportedError('File operations not supported on web');
  }
  
  Future<File> writeAsString(String contents) async {
    throw UnsupportedError('File operations not supported on web');
  }
  
  Future<File> writeAsBytes(List<int> bytes) async {
    throw UnsupportedError('File operations not supported on web');
  }
  
  Future<void> delete() async {
    throw UnsupportedError('File operations not supported on web');
  }
}

/// Stub for Directory class
class Directory {
  final String path;
  const Directory(this.path);

  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Future<void> delete({bool recursive = false}) async {
    throw UnsupportedError('Directory operations not supported on web');
  }
}
