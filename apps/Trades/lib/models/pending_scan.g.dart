// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_scan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanTypeAdapter extends TypeAdapter<ScanType> {
  @override
  final int typeId = 20;

  @override
  ScanType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScanType.panelIdentifier;
      case 1:
        return ScanType.nameplateReader;
      case 2:
        return ScanType.wireIdentifier;
      case 3:
        return ScanType.violationSpotter;
      case 4:
        return ScanType.labelScanner;
      default:
        return ScanType.labelScanner;
    }
  }

  @override
  void write(BinaryWriter writer, ScanType obj) {
    switch (obj) {
      case ScanType.panelIdentifier:
        writer.writeByte(0);
        break;
      case ScanType.nameplateReader:
        writer.writeByte(1);
        break;
      case ScanType.wireIdentifier:
        writer.writeByte(2);
        break;
      case ScanType.violationSpotter:
        writer.writeByte(3);
        break;
      case ScanType.labelScanner:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PendingScanStatusAdapter extends TypeAdapter<PendingScanStatus> {
  @override
  final int typeId = 21;

  @override
  PendingScanStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PendingScanStatus.queued;
      case 1:
        return PendingScanStatus.processing;
      case 2:
        return PendingScanStatus.completed;
      case 3:
        return PendingScanStatus.failed;
      case 4:
        return PendingScanStatus.cancelled;
      default:
        return PendingScanStatus.queued;
    }
  }

  @override
  void write(BinaryWriter writer, PendingScanStatus obj) {
    switch (obj) {
      case PendingScanStatus.queued:
        writer.writeByte(0);
        break;
      case PendingScanStatus.processing:
        writer.writeByte(1);
        break;
      case PendingScanStatus.completed:
        writer.writeByte(2);
        break;
      case PendingScanStatus.failed:
        writer.writeByte(3);
        break;
      case PendingScanStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingScanStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PendingScanAdapter extends TypeAdapter<PendingScan> {
  @override
  final int typeId = 22;

  @override
  PendingScan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingScan(
      id: fields[0] as String,
      scanType: fields[1] as ScanType,
      imagePath: fields[2] as String,
      imageBytes: fields[3] as Uint8List?,
      createdAt: fields[4] as DateTime,
      status: fields[5] as PendingScanStatus? ?? PendingScanStatus.queued,
      jobId: fields[6] as String?,
      jobAddress: fields[7] as String?,
      notes: fields[8] as String?,
      retryCount: fields[9] as int? ?? 0,
      errorMessage: fields[10] as String?,
      processedAt: fields[11] as DateTime?,
      result: (fields[12] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, PendingScan obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scanType)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.imageBytes)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.jobId)
      ..writeByte(7)
      ..write(obj.jobAddress)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.retryCount)
      ..writeByte(10)
      ..write(obj.errorMessage)
      ..writeByte(11)
      ..write(obj.processedAt)
      ..writeByte(12)
      ..write(obj.result);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingScanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
