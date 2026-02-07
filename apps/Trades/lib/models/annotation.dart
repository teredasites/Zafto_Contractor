// ZAFTO Photo Annotation Model — Supabase Backend
// Stored as JSON in walkthrough_photos.annotations column.
// Supports freehand drawing, arrows, shapes, text, measurements, and stamps.

import 'dart:ui';

import 'package:uuid/uuid.dart';

// Annotation tool types available in the photo annotation editor
enum AnnotationType {
  draw,
  arrow,
  circle,
  rectangle,
  text,
  measurement,
  stamp;

  String get label {
    switch (this) {
      case AnnotationType.draw:
        return 'Draw';
      case AnnotationType.arrow:
        return 'Arrow';
      case AnnotationType.circle:
        return 'Circle';
      case AnnotationType.rectangle:
        return 'Rectangle';
      case AnnotationType.text:
        return 'Text';
      case AnnotationType.measurement:
        return 'Measure';
      case AnnotationType.stamp:
        return 'Stamp';
    }
  }

  static AnnotationType fromString(String? value) {
    if (value == null) return AnnotationType.draw;
    return AnnotationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AnnotationType.draw,
    );
  }
}

// Preset stamp types for field annotations
enum StampType {
  damage,
  ok,
  issue,
  note;

  String get label {
    switch (this) {
      case StampType.damage:
        return 'DAMAGE';
      case StampType.ok:
        return 'OK';
      case StampType.issue:
        return 'ISSUE';
      case StampType.note:
        return 'NOTE';
    }
  }

  Color get color {
    switch (this) {
      case StampType.damage:
        return const Color(0xFFEF4444); // Red
      case StampType.ok:
        return const Color(0xFF22C55E); // Green
      case StampType.issue:
        return const Color(0xFFF59E0B); // Amber
      case StampType.note:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  static StampType fromString(String? value) {
    if (value == null) return StampType.note;
    return StampType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StampType.note,
    );
  }
}

// Single annotation placed on a photo
class PhotoAnnotation {
  final String id;
  final AnnotationType type;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String? text;
  final double? fontSize;
  final Map<String, dynamic> metadata;

  PhotoAnnotation({
    String? id,
    required this.type,
    required this.points,
    this.color = const Color(0xFFFF3B30),
    this.strokeWidth = 4.0,
    this.text,
    this.fontSize,
    this.metadata = const {},
  }) : id = id ?? const Uuid().v4();

  PhotoAnnotation copyWith({
    String? id,
    AnnotationType? type,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    String? text,
    double? fontSize,
    Map<String, dynamic>? metadata,
  }) {
    return PhotoAnnotation(
      id: id ?? this.id,
      type: type ?? this.type,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'color': color.toARGB32(),
        'strokeWidth': strokeWidth,
        if (text != null) 'text': text,
        if (fontSize != null) 'fontSize': fontSize,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory PhotoAnnotation.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((p) {
      final map = p as Map<String, dynamic>;
      return Offset(
        (map['x'] as num).toDouble(),
        (map['y'] as num).toDouble(),
      );
    }).toList();

    return PhotoAnnotation(
      id: json['id'] as String?,
      type: AnnotationType.fromString(json['type'] as String?),
      points: points,
      color: Color(json['color'] as int? ?? 0xFFFF3B30),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 4.0,
      text: json['text'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

// Container for all annotations on a single photo, with image dimensions
// for coordinate normalization across different display sizes
class AnnotationLayer {
  final List<PhotoAnnotation> annotations;
  final int imageWidth;
  final int imageHeight;

  const AnnotationLayer({
    this.annotations = const [],
    required this.imageWidth,
    required this.imageHeight,
  });

  // Add an annotation and return a new layer
  AnnotationLayer addAnnotation(PhotoAnnotation annotation) {
    return AnnotationLayer(
      annotations: [...annotations, annotation],
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  // Remove an annotation by id and return a new layer
  AnnotationLayer removeAnnotation(String annotationId) {
    return AnnotationLayer(
      annotations:
          annotations.where((a) => a.id != annotationId).toList(),
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  // Remove the last annotation (for undo)
  AnnotationLayer removeLast() {
    if (annotations.isEmpty) return this;
    return AnnotationLayer(
      annotations: annotations.sublist(0, annotations.length - 1),
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  // Clear all annotations
  AnnotationLayer clear() {
    return AnnotationLayer(
      annotations: const [],
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  bool get isEmpty => annotations.isEmpty;
  bool get isNotEmpty => annotations.isNotEmpty;
  int get count => annotations.length;

  Map<String, dynamic> toJson() => {
        'annotations': annotations.map((a) => a.toJson()).toList(),
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
      };

  factory AnnotationLayer.fromJson(Map<String, dynamic> json) {
    final rawAnnotations = json['annotations'] as List<dynamic>? ?? [];
    return AnnotationLayer(
      annotations: rawAnnotations
          .map((a) =>
              PhotoAnnotation.fromJson(a as Map<String, dynamic>))
          .toList(),
      imageWidth: json['imageWidth'] as int? ?? 0,
      imageHeight: json['imageHeight'] as int? ?? 0,
    );
  }
}
