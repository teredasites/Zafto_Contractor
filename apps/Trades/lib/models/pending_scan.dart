import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'pending_scan.g.dart';

/// AI Scan types matching the scanner features
@HiveType(typeId: 20)
enum ScanType {
  @HiveField(0)
  panelIdentifier,
  @HiveField(1)
  nameplateReader,
  @HiveField(2)
  wireIdentifier,
  @HiveField(3)
  violationSpotter,
  @HiveField(4)
  labelScanner,
}

/// Extension for scan type display names and descriptions
extension ScanTypeExtension on ScanType {
  String get displayName {
    switch (this) {
      case ScanType.panelIdentifier:
        return 'Panel Identifier';
      case ScanType.nameplateReader:
        return 'Nameplate Reader';
      case ScanType.wireIdentifier:
        return 'Wire Identifier';
      case ScanType.violationSpotter:
        return 'Violation Spotter';
      case ScanType.labelScanner:
        return 'Label Scanner';
    }
  }

  String get description {
    switch (this) {
      case ScanType.panelIdentifier:
        return 'Identify breakers, flag issues, generate panel schedule';
      case ScanType.nameplateReader:
        return 'Extract motor specs: HP, voltage, FLA, frame';
      case ScanType.wireIdentifier:
        return 'Identify wire gauge, type, and markings';
      case ScanType.violationSpotter:
        return 'Flag potential code violations with NEC references';
      case ScanType.labelScanner:
        return 'Extract specs from any electrical label';
    }
  }

  String get iconName {
    switch (this) {
      case ScanType.panelIdentifier:
        return 'electric_bolt';
      case ScanType.nameplateReader:
        return 'settings';
      case ScanType.wireIdentifier:
        return 'cable';
      case ScanType.violationSpotter:
        return 'warning';
      case ScanType.labelScanner:
        return 'qr_code_scanner';
    }
  }
}

/// Status of a pending scan
@HiveType(typeId: 21)
enum PendingScanStatus {
  @HiveField(0)
  queued,
  @HiveField(1)
  processing,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
  @HiveField(4)
  cancelled,
}

/// A pending AI scan stored for offline processing
@HiveType(typeId: 22)
class PendingScan with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ScanType scanType;

  @HiveField(2)
  final String imagePath;

  @HiveField(3)
  final Uint8List? imageBytes;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final PendingScanStatus status;

  @HiveField(6)
  final String? jobId;

  @HiveField(7)
  final String? jobAddress;

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final int retryCount;

  @HiveField(10)
  final String? errorMessage;

  @HiveField(11)
  final DateTime? processedAt;

  @HiveField(12)
  final Map<String, dynamic>? result;

  const PendingScan({
    required this.id,
    required this.scanType,
    required this.imagePath,
    this.imageBytes,
    required this.createdAt,
    this.status = PendingScanStatus.queued,
    this.jobId,
    this.jobAddress,
    this.notes,
    this.retryCount = 0,
    this.errorMessage,
    this.processedAt,
    this.result,
  });

  /// Create a new pending scan
  factory PendingScan.create({
    required ScanType scanType,
    required String imagePath,
    Uint8List? imageBytes,
    String? jobId,
    String? jobAddress,
    String? notes,
  }) {
    return PendingScan(
      id: '${DateTime.now().millisecondsSinceEpoch}_${scanType.name}',
      scanType: scanType,
      imagePath: imagePath,
      imageBytes: imageBytes,
      createdAt: DateTime.now(),
      jobId: jobId,
      jobAddress: jobAddress,
      notes: notes,
    );
  }

  /// Copy with updated values
  PendingScan copyWith({
    String? id,
    ScanType? scanType,
    String? imagePath,
    Uint8List? imageBytes,
    DateTime? createdAt,
    PendingScanStatus? status,
    String? jobId,
    String? jobAddress,
    String? notes,
    int? retryCount,
    String? errorMessage,
    DateTime? processedAt,
    Map<String, dynamic>? result,
  }) {
    return PendingScan(
      id: id ?? this.id,
      scanType: scanType ?? this.scanType,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      jobId: jobId ?? this.jobId,
      jobAddress: jobAddress ?? this.jobAddress,
      notes: notes ?? this.notes,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage,
      processedAt: processedAt ?? this.processedAt,
      result: result ?? this.result,
    );
  }

  /// Mark as processing
  PendingScan markProcessing() => copyWith(
        status: PendingScanStatus.processing,
        errorMessage: null,
      );

  /// Mark as completed with result
  PendingScan markCompleted(Map<String, dynamic> scanResult) => copyWith(
        status: PendingScanStatus.completed,
        processedAt: DateTime.now(),
        result: scanResult,
        errorMessage: null,
      );

  /// Mark as failed
  PendingScan markFailed(String error) => copyWith(
        status: PendingScanStatus.failed,
        retryCount: retryCount + 1,
        errorMessage: error,
      );

  /// Mark as cancelled
  PendingScan markCancelled() => copyWith(
        status: PendingScanStatus.cancelled,
      );

  /// Check if can retry
  bool get canRetry => retryCount < 3 && status == PendingScanStatus.failed;

  /// Check if is pending (queued or failed but can retry)
  bool get isPending =>
      status == PendingScanStatus.queued ||
      (status == PendingScanStatus.failed && canRetry);

  /// Get display title
  String get displayTitle => scanType.displayName;

  /// Get status text
  String get statusText {
    switch (status) {
      case PendingScanStatus.queued:
        return 'Waiting to process';
      case PendingScanStatus.processing:
        return 'Processing...';
      case PendingScanStatus.completed:
        return 'Completed';
      case PendingScanStatus.failed:
        return canRetry ? 'Failed - tap to retry' : 'Failed';
      case PendingScanStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get time since created
  String get timeSinceCreated {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Convert to JSON for potential cloud backup
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scanType': scanType.name,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'jobId': jobId,
      'jobAddress': jobAddress,
      'notes': notes,
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'processedAt': processedAt?.toIso8601String(),
      // Note: imageBytes and result not included in JSON (too large)
    };
  }

  /// Create from JSON
  factory PendingScan.fromJson(Map<String, dynamic> json) {
    return PendingScan(
      id: json['id'] as String,
      scanType: ScanType.values.firstWhere(
        (e) => e.name == json['scanType'],
        orElse: () => ScanType.labelScanner,
      ),
      imagePath: json['imagePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: PendingScanStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PendingScanStatus.queued,
      ),
      jobId: json['jobId'] as String?,
      jobAddress: json['jobAddress'] as String?,
      notes: json['notes'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        scanType,
        imagePath,
        createdAt,
        status,
        jobId,
        jobAddress,
        notes,
        retryCount,
        errorMessage,
        processedAt,
      ];
}

/// Summary of offline queue for UI display
class OfflineQueueSummary {
  final int totalCount;
  final int queuedCount;
  final int processingCount;
  final int completedCount;
  final int failedCount;
  final DateTime? oldestPending;

  const OfflineQueueSummary({
    required this.totalCount,
    required this.queuedCount,
    required this.processingCount,
    required this.completedCount,
    required this.failedCount,
    this.oldestPending,
  });

  bool get hasPending => queuedCount > 0 || processingCount > 0;
  bool get hasFailures => failedCount > 0;
  bool get isEmpty => totalCount == 0;
}
