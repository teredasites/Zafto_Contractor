import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Defect Markup Tool - Photo capture with drawing/annotation overlay
class DefectMarkupScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const DefectMarkupScreen({super.key, this.jobId});

  @override
  ConsumerState<DefectMarkupScreen> createState() => _DefectMarkupScreenState();
}

class _DefectMarkupScreenState extends ConsumerState<DefectMarkupScreen> {
  CapturedPhoto? _photo;
  final List<_DrawingPath> _paths = [];
  final List<_TextAnnotation> _textAnnotations = [];
  _DrawingPath? _currentPath;
  _MarkupTool _selectedTool = _MarkupTool.arrow;
  Color _selectedColor = const Color(0xFFFF3B30); // Red
  double _strokeWidth = 4.0;
  bool _isCapturing = false;
  final GlobalKey _canvasKey = GlobalKey();

  final List<Color> _colorOptions = const [
    Color(0xFFFF3B30), // Red
    Color(0xFFFFD60A), // Yellow
    Color(0xFF30D158), // Green
    Color(0xFF007AFF), // Blue
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Black
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final cameraService = ref.watch(fieldCameraServiceProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Defect Markup', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (_photo != null && (_paths.isNotEmpty || _textAnnotations.isNotEmpty)) ...[
            IconButton(
              icon: Icon(LucideIcons.undo, color: colors.textSecondary),
              onPressed: _undo,
            ),
            IconButton(
              icon: Icon(LucideIcons.trash2, color: colors.accentError),
              onPressed: _clearAll,
            ),
          ],
          if (_photo != null)
            IconButton(
              icon: Icon(LucideIcons.save, color: colors.accentPrimary),
              onPressed: _saveMarkup,
            ),
        ],
      ),
      body: _photo == null
          ? _buildCapturePrompt(colors, cameraService)
          : Column(
              children: [
                // Tool bar
                _buildToolBar(colors),
                // Canvas
                Expanded(child: _buildCanvas(colors)),
                // Color picker
                _buildColorPicker(colors),
              ],
            ),
    );
  }

  Widget _buildCapturePrompt(ZaftoColors colors, FieldCameraService cameraService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.penTool, size: 56, color: colors.textTertiary),
          ),
          const SizedBox(height: 24),
          Text(
            'Capture a photo to mark up',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Draw arrows, circles, and text to\nhighlight defects or issues',
            style: TextStyle(fontSize: 14, color: colors.textTertiary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.camera),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () => _capturePhoto(cameraService, ImageSource.camera),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: Icon(LucideIcons.image, color: colors.textSecondary),
                label: Text('Gallery', style: TextStyle(color: colors.textSecondary)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.borderDefault),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                onPressed: () => _capturePhoto(cameraService, ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolBar(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          _buildToolButton(colors, _MarkupTool.arrow, LucideIcons.moveUpRight, 'Arrow'),
          _buildToolButton(colors, _MarkupTool.circle, LucideIcons.circle, 'Circle'),
          _buildToolButton(colors, _MarkupTool.freehand, LucideIcons.pencil, 'Draw'),
          _buildToolButton(colors, _MarkupTool.text, LucideIcons.type, 'Text'),
          const Spacer(),
          // Stroke width
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.fillDefault,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_strokeWidth > 2) setState(() => _strokeWidth -= 1);
                  },
                  child: Icon(LucideIcons.minus, size: 16, color: colors.textSecondary),
                ),
                const SizedBox(width: 8),
                Container(
                  width: _strokeWidth * 2,
                  height: _strokeWidth * 2,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_strokeWidth < 12) setState(() => _strokeWidth += 1);
                  },
                  child: Icon(LucideIcons.plus, size: 16, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(ZaftoColors colors, _MarkupTool tool, IconData icon, String label) {
    final isSelected = _selectedTool == tool;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTool = tool);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _selectedColor : colors.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? _selectedColor : colors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _selectedColor : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas(ZaftoColors colors) {
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
            // Photo
            Image.memory(_photo!.bytes, fit: BoxFit.contain),

            // Drawing overlay
            CustomPaint(
              painter: _MarkupPainter(
                paths: _paths,
                currentPath: _currentPath,
                textAnnotations: _textAnnotations,
              ),
              size: Size.infinite,
            ),

            // Timestamp badge
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.calendar, size: 12, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(_photo!.timestampDisplay, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (_photo!.hasLocation) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.mapPin, size: 12, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(_photo!.locationDisplay, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _colorOptions.map((color) {
          final isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedColor = color);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.accentPrimary : (color == Colors.white ? Colors.grey : Colors.transparent),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      LucideIcons.check,
                      size: 18,
                      color: color == Colors.white || color == const Color(0xFFFFD60A) ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // DRAWING HANDLERS
  // ============================================================

  void _onPanStart(DragStartDetails details) {
    if (_selectedTool == _MarkupTool.text) return;

    setState(() {
      _currentPath = _DrawingPath(
        tool: _selectedTool,
        color: _selectedColor,
        strokeWidth: _strokeWidth,
        points: [details.localPosition],
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentPath == null) return;

    setState(() {
      _currentPath!.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPath != null) {
      setState(() {
        _paths.add(_currentPath!);
        _currentPath = null;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_selectedTool == _MarkupTool.text) {
      _showTextDialog(details.localPosition);
    }
  }

  void _showTextDialog(Offset position) {
    final colors = ref.read(zaftoColorsProvider);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Add Label', style: TextStyle(color: colors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter text...',
            hintStyle: TextStyle(color: colors.textTertiary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.accentPrimary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _textAnnotations.add(_TextAnnotation(
                    text: controller.text,
                    position: position,
                    color: _selectedColor,
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: Text('Add', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _capturePhoto(FieldCameraService service, ImageSource source) async {
    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      final photo = await service.capturePhoto(source: source);
      if (photo != null) {
        setState(() => _photo = photo);
      }
    } catch (e) {
      _showError('Failed to capture: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  void _undo() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_textAnnotations.isNotEmpty) {
        _textAnnotations.removeLast();
      } else if (_paths.isNotEmpty) {
        _paths.removeLast();
      }
    });
  }

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _paths.clear();
      _textAnnotations.clear();
    });
  }

  Future<void> _saveMarkup() async {
    // TODO: BACKEND - Render canvas to image and save
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Markup saved'), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

enum _MarkupTool { arrow, circle, freehand, text }

class _DrawingPath {
  final _MarkupTool tool;
  final Color color;
  final double strokeWidth;
  final List<Offset> points;

  _DrawingPath({
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.points,
  });
}

class _TextAnnotation {
  final String text;
  final Offset position;
  final Color color;

  _TextAnnotation({
    required this.text,
    required this.position,
    required this.color,
  });
}

// ============================================================
// CUSTOM PAINTER
// ============================================================

class _MarkupPainter extends CustomPainter {
  final List<_DrawingPath> paths;
  final _DrawingPath? currentPath;
  final List<_TextAnnotation> textAnnotations;

  _MarkupPainter({
    required this.paths,
    this.currentPath,
    required this.textAnnotations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all completed paths
    for (final path in paths) {
      _drawPath(canvas, path);
    }

    // Draw current path being drawn
    if (currentPath != null) {
      _drawPath(canvas, currentPath!);
    }

    // Draw text annotations
    for (final annotation in textAnnotations) {
      _drawText(canvas, annotation);
    }
  }

  void _drawPath(Canvas canvas, _DrawingPath path) {
    if (path.points.isEmpty) return;

    final paint = Paint()
      ..color = path.color
      ..strokeWidth = path.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (path.tool) {
      case _MarkupTool.arrow:
        _drawArrow(canvas, path, paint);
        break;
      case _MarkupTool.circle:
        _drawCircle(canvas, path, paint);
        break;
      case _MarkupTool.freehand:
        _drawFreehand(canvas, path, paint);
        break;
      case _MarkupTool.text:
        break; // Text handled separately
    }
  }

  void _drawArrow(Canvas canvas, _DrawingPath path, Paint paint) {
    if (path.points.length < 2) return;

    final start = path.points.first;
    final end = path.points.last;

    // Draw line
    canvas.drawLine(start, end, paint);

    // Draw arrowhead
    final angle = (end - start).direction;
    final arrowSize = path.strokeWidth * 4;

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * 1.5 * (end - start).normalized.dx + arrowSize * 0.6 * (end - start).normalized.dy,
        end.dy - arrowSize * 1.5 * (end - start).normalized.dy - arrowSize * 0.6 * (end - start).normalized.dx,
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * 1.5 * (end - start).normalized.dx - arrowSize * 0.6 * (end - start).normalized.dy,
        end.dy - arrowSize * 1.5 * (end - start).normalized.dy + arrowSize * 0.6 * (end - start).normalized.dx,
      );

    canvas.drawPath(arrowPath, paint);
  }

  void _drawCircle(Canvas canvas, _DrawingPath path, Paint paint) {
    if (path.points.length < 2) return;

    final start = path.points.first;
    final end = path.points.last;
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final radius = (end - start).distance / 2;

    canvas.drawCircle(center, radius, paint);
  }

  void _drawFreehand(Canvas canvas, _DrawingPath path, Paint paint) {
    if (path.points.length < 2) return;

    final drawPath = Path()..moveTo(path.points.first.dx, path.points.first.dy);

    for (int i = 1; i < path.points.length; i++) {
      drawPath.lineTo(path.points[i].dx, path.points[i].dy);
    }

    canvas.drawPath(drawPath, paint);
  }

  void _drawText(Canvas canvas, _TextAnnotation annotation) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: annotation.text,
        style: TextStyle(
          color: annotation.color,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4, offset: const Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final bgRect = Rect.fromLTWH(
      annotation.position.dx - 4,
      annotation.position.dy - 4,
      textPainter.width + 8,
      textPainter.height + 8,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(4)), bgPaint);

    textPainter.paint(canvas, annotation.position);
  }

  @override
  bool shouldRepaint(_MarkupPainter oldDelegate) => true;
}

extension on Offset {
  Offset get normalized {
    final len = distance;
    return len > 0 ? this / len : Offset.zero;
  }
}
