// ZAFTO Photo Annotation Screen — Full-Screen Photo Markup Editor
// Lets field technicians annotate walkthrough photos with drawings, arrows,
// text, measurements, shapes, and stamps. Saves annotations as JSON and
// renders an annotated PNG for export/sharing.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../models/annotation.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'annotation_painter.dart';

// Result returned when the user saves annotations
class AnnotationResult {
  final Map<String, dynamic> annotationJson;
  final Uint8List? renderedBytes;

  const AnnotationResult({
    required this.annotationJson,
    this.renderedBytes,
  });
}

// Full-screen photo annotation editor
class PhotoAnnotationScreen extends ConsumerStatefulWidget {
  final String imageUrl;
  final String? photoId;
  final Map<String, dynamic>? existingAnnotations;

  const PhotoAnnotationScreen({
    super.key,
    required this.imageUrl,
    this.photoId,
    this.existingAnnotations,
  });

  @override
  ConsumerState<PhotoAnnotationScreen> createState() =>
      _PhotoAnnotationScreenState();
}

class _PhotoAnnotationScreenState
    extends ConsumerState<PhotoAnnotationScreen> {
  // Annotation state
  AnnotationLayer _layer = const AnnotationLayer(
    imageWidth: 0,
    imageHeight: 0,
  );
  PhotoAnnotation? _currentAnnotation;

  // Undo/redo stacks
  final List<AnnotationLayer> _undoStack = [];
  final List<AnnotationLayer> _redoStack = [];

  // Tool state
  AnnotationType _selectedTool = AnnotationType.draw;
  Color _selectedColor = const Color(0xFFFF3B30);
  double _strokeWidth = 4.0;
  double _fontSize = 18.0;
  StampType _selectedStamp = StampType.damage;
  bool _showSidePanel = false;

  // Image state
  bool _imageLoaded = false;
  final GlobalKey _canvasKey = GlobalKey();
  bool _isSaving = false;

  // Two-tap tools state (arrow, measurement)
  Offset? _firstTapPoint;

  final List<Color> _colorOptions = const [
    Color(0xFFFF3B30), // Red
    Color(0xFFFFD60A), // Yellow
    Color(0xFF30D158), // Green
    Color(0xFF007AFF), // Blue
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Black
  ];

  @override
  void initState() {
    super.initState();
    _loadImage();
    _loadExistingAnnotations();
  }

  void _loadExistingAnnotations() {
    if (widget.existingAnnotations != null) {
      try {
        _layer = AnnotationLayer.fromJson(widget.existingAnnotations!);
      } catch (_) {
        // If parsing fails, start fresh
      }
    }
  }

  Future<void> _loadImage() async {
    try {
      final imageProvider = NetworkImage(widget.imageUrl);
      final stream = imageProvider.resolve(ImageConfiguration.empty);
      final completer = Completer<ui.Image>();

      stream.addListener(ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) {
            completer.complete(info.image);
          }
        },
        onError: (error, _) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      ));

      final image = await completer.future;
      if (mounted) {
        setState(() {
          _imageLoaded = true;
          if (_layer.imageWidth == 0) {
            _layer = AnnotationLayer(
              annotations: _layer.annotations,
              imageWidth: image.width,
              imageHeight: image.height,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _imageLoaded = true);
      }
    }
  }

  // Push current state to undo stack before making a change
  void _pushUndo() {
    _undoStack.add(_layer);
    _redoStack.clear();
    // Limit undo stack to 50 entries
    if (_undoStack.length > 50) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _redoStack.add(_layer);
      _layer = _undoStack.removeLast();
      _currentAnnotation = null;
      _firstTapPoint = null;
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _undoStack.add(_layer);
      _layer = _redoStack.removeLast();
      _currentAnnotation = null;
      _firstTapPoint = null;
    });
  }

  void _clearAll() {
    if (_layer.isEmpty) return;
    HapticFeedback.mediumImpact();
    _pushUndo();
    setState(() {
      _layer = _layer.clear();
      _currentAnnotation = null;
      _firstTapPoint = null;
    });
  }

  // Add completed annotation to layer
  void _commitAnnotation(PhotoAnnotation annotation) {
    _pushUndo();
    setState(() {
      _layer = _layer.addAnnotation(annotation);
      _currentAnnotation = null;
      _firstTapPoint = null;
    });
  }

  // ============================================================
  // GESTURE HANDLERS
  // ============================================================

  void _onPanStart(DragStartDetails details) {
    // Pan gestures for draw, circle, rectangle
    if (_selectedTool == AnnotationType.text ||
        _selectedTool == AnnotationType.stamp ||
        _selectedTool == AnnotationType.arrow ||
        _selectedTool == AnnotationType.measurement) {
      return;
    }

    setState(() {
      _currentAnnotation = PhotoAnnotation(
        type: _selectedTool,
        points: [details.localPosition],
        color: _selectedColor,
        strokeWidth: _strokeWidth,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentAnnotation == null) return;

    setState(() {
      if (_selectedTool == AnnotationType.draw) {
        // Freehand — append every point
        _currentAnnotation = _currentAnnotation!.copyWith(
          points: [..._currentAnnotation!.points, details.localPosition],
        );
      } else {
        // Circle/Rectangle — update second point (start + current)
        _currentAnnotation = _currentAnnotation!.copyWith(
          points: [_currentAnnotation!.points.first, details.localPosition],
        );
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentAnnotation != null &&
        _currentAnnotation!.points.length >= 2) {
      _commitAnnotation(_currentAnnotation!);
    } else {
      setState(() => _currentAnnotation = null);
    }
  }

  void _onTapUp(TapUpDetails details) {
    final pos = details.localPosition;

    switch (_selectedTool) {
      case AnnotationType.text:
        _showTextInputDialog(pos);
        break;

      case AnnotationType.stamp:
        _commitAnnotation(PhotoAnnotation(
          type: AnnotationType.stamp,
          points: [pos],
          color: _selectedStamp.color,
          text: _selectedStamp.label,
          metadata: {'stampType': _selectedStamp.name},
        ));
        HapticFeedback.mediumImpact();
        break;

      case AnnotationType.arrow:
      case AnnotationType.measurement:
        if (_firstTapPoint == null) {
          // First tap — store start point
          HapticFeedback.selectionClick();
          setState(() => _firstTapPoint = pos);
        } else {
          // Second tap — commit
          HapticFeedback.mediumImpact();
          _commitAnnotation(PhotoAnnotation(
            type: _selectedTool,
            points: [_firstTapPoint!, pos],
            color: _selectedColor,
            strokeWidth: _strokeWidth,
          ));
        }
        break;

      default:
        break;
    }
  }

  void _showTextInputDialog(Offset position) {
    final colors = ref.read(zaftoColorsProvider);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text(
          'Add Text',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter annotation text...',
            hintStyle: TextStyle(color: colors.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: colors.accentPrimary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentPrimary,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.isNotEmpty) {
                _commitAnnotation(PhotoAnnotation(
                  type: AnnotationType.text,
                  points: [position],
                  color: _selectedColor,
                  text: controller.text,
                  fontSize: _fontSize,
                ));
              }
            },
            child: Text(
              'Add',
              style: TextStyle(
                color: colors.isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TODO:BACKEND — Wire measurement edit dialog when tapping existing
  // measurement annotations to set real-world dimensions (e.g. "12 ft")

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      Uint8List? renderedBytes;

      // Render the annotated image via RepaintBoundary
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          renderedBytes = byteData.buffer.asUint8List();
        }
      }

      final result = AnnotationResult(
        annotationJson: _layer.toJson(),
        renderedBytes: renderedBytes,
      );

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save annotations: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopToolbar(colors),
            Expanded(child: _buildCanvas(colors)),
            _buildBottomToolbar(colors),
            if (_showSidePanel) _buildOptionsPanel(colors),
          ],
        ),
      ),
    );
  }

  // Top toolbar: Back, Undo, Redo, Clear, Save
  Widget _buildTopToolbar(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Back
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.arrowLeft,
                size: 20, color: Colors.white),
            tooltip: 'Back',
          ),
          const Spacer(),
          // Undo
          IconButton(
            onPressed: _undoStack.isNotEmpty ? _undo : null,
            icon: Icon(
              LucideIcons.undo,
              size: 20,
              color: _undoStack.isNotEmpty
                  ? Colors.white
                  : Colors.white24,
            ),
            tooltip: 'Undo',
          ),
          // Redo
          IconButton(
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            icon: Icon(
              LucideIcons.redo,
              size: 20,
              color: _redoStack.isNotEmpty
                  ? Colors.white
                  : Colors.white24,
            ),
            tooltip: 'Redo',
          ),
          // Clear
          IconButton(
            onPressed: _layer.isNotEmpty ? _clearAll : null,
            icon: Icon(
              LucideIcons.trash2,
              size: 20,
              color: _layer.isNotEmpty
                  ? const Color(0xFFEF4444)
                  : Colors.white24,
            ),
            tooltip: 'Clear all',
          ),
          const SizedBox(width: 8),
          // Save
          _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFF59E0B),
                  ),
                )
              : GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // Canvas: image background + annotation overlay + gesture input
  Widget _buildCanvas(ZaftoColors colors) {
    if (!_imageLoaded) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFF59E0B),
        ),
      );
    }

    return RepaintBoundary(
      key: _canvasKey,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapUp: _onTapUp,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo background
            Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.imageOff,
                        size: 48, color: colors.textTertiary),
                    const SizedBox(height: 8),
                    Text(
                      'Could not load image',
                      style: TextStyle(
                          color: colors.textTertiary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // Annotation overlay
            CustomPaint(
              painter: AnnotationPainter(
                annotations: _layer.annotations,
                currentAnnotation: _currentAnnotation,
              ),
              size: Size.infinite,
            ),

            // First-tap indicator for arrow/measurement
            if (_firstTapPoint != null)
              Positioned(
                left: _firstTapPoint!.dx - 8,
                top: _firstTapPoint!.dy - 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedColor.withValues(alpha: 0.5),
                    border:
                        Border.all(color: _selectedColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Bottom toolbar: tool selection
  Widget _buildBottomToolbar(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildToolButton(
                AnnotationType.draw, LucideIcons.pencil, 'Draw'),
            _buildToolButton(
                AnnotationType.arrow, LucideIcons.moveUpRight, 'Arrow'),
            _buildToolButton(
                AnnotationType.circle, LucideIcons.circle, 'Circle'),
            _buildToolButton(
                AnnotationType.rectangle, LucideIcons.square, 'Rect'),
            _buildToolButton(
                AnnotationType.text, LucideIcons.type, 'Text'),
            _buildToolButton(AnnotationType.measurement,
                LucideIcons.ruler, 'Measure'),
            _buildToolButton(
                AnnotationType.stamp, LucideIcons.stamp, 'Stamp'),
            const SizedBox(width: 8),
            // Toggle options panel
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _showSidePanel = !_showSidePanel);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _showSidePanel
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  LucideIcons.settings2,
                  size: 18,
                  color: _showSidePanel
                      ? const Color(0xFFF59E0B)
                      : Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(
      AnnotationType tool, IconData icon, String label) {
    final isSelected = _selectedTool == tool;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTool = tool;
          _firstTapPoint = null;
          _currentAnnotation = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFFF59E0B)
                  : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFF59E0B)
                    : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Options panel: colors, stroke width, font size, stamp type
  Widget _buildOptionsPanel(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color picker
          const Text(
            'Color',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _colorOptions.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedColor = color);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF59E0B)
                          : (color == Colors.black
                              ? Colors.white24
                              : Colors.transparent),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: 16,
                          color: (color == Colors.white ||
                                  color == const Color(0xFFFFD60A))
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Stroke width
          Row(
            children: [
              const Text(
                'Stroke',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_strokeWidth.toStringAsFixed(0)}px',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 2,
                    thumbShape:
                        RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: Color(0xFFF59E0B),
                    inactiveTrackColor: Colors.white12,
                    thumbColor: Color(0xFFF59E0B),
                  ),
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 16,
                    onChanged: (val) =>
                        setState(() => _strokeWidth = val),
                  ),
                ),
              ),
            ],
          ),

          // Font size (for text tool)
          if (_selectedTool == AnnotationType.text) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Font',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_fontSize.toStringAsFixed(0)}pt',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SliderTheme(
                    data: const SliderThemeData(
                      trackHeight: 2,
                      thumbShape:
                          RoundSliderThumbShape(enabledThumbRadius: 8),
                      activeTrackColor: Color(0xFFF59E0B),
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Color(0xFFF59E0B),
                    ),
                    child: Slider(
                      value: _fontSize,
                      min: 10,
                      max: 48,
                      onChanged: (val) =>
                          setState(() => _fontSize = val),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Stamp type selector
          if (_selectedTool == AnnotationType.stamp) ...[
            const SizedBox(height: 12),
            const Text(
              'Stamp Type',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: StampType.values.map((stamp) {
                final isSelected = _selectedStamp == stamp;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedStamp = stamp);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? stamp.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            isSelected ? stamp.color : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      stamp.label,
                      style: TextStyle(
                        color:
                            isSelected ? stamp.color : Colors.white60,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Instruction hint
          const SizedBox(height: 12),
          Text(
            _getToolHint(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _getToolHint() {
    switch (_selectedTool) {
      case AnnotationType.draw:
        return 'Drag to draw freehand on the photo.';
      case AnnotationType.arrow:
        return _firstTapPoint == null
            ? 'Tap the start point for the arrow.'
            : 'Tap the end point to complete the arrow.';
      case AnnotationType.circle:
        return 'Tap center and drag to set radius.';
      case AnnotationType.rectangle:
        return 'Tap a corner and drag to the opposite corner.';
      case AnnotationType.text:
        return 'Tap where you want to place text.';
      case AnnotationType.measurement:
        return _firstTapPoint == null
            ? 'Tap the start point for the measurement line.'
            : 'Tap the end point to complete the measurement.';
      case AnnotationType.stamp:
        return 'Tap to place the stamp badge.';
    }
  }
}

