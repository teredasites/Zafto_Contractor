import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Before/After Comparison Tool - Side-by-side photo comparison with slider
class BeforeAfterScreen extends ConsumerStatefulWidget {
  final String? jobId;

  const BeforeAfterScreen({super.key, this.jobId});

  @override
  ConsumerState<BeforeAfterScreen> createState() => _BeforeAfterScreenState();
}

class _BeforeAfterScreenState extends ConsumerState<BeforeAfterScreen> {
  CapturedPhoto? _beforePhoto;
  CapturedPhoto? _afterPhoto;
  double _sliderPosition = 0.5; // 0.0 = all before, 1.0 = all after
  bool _isCapturing = false;
  bool _showComparisonMode = false;

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
        title: Text('Before / After', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (_beforePhoto != null && _afterPhoto != null)
            IconButton(
              icon: Icon(
                _showComparisonMode ? LucideIcons.columns : LucideIcons.slidersHorizontal,
                color: colors.accentPrimary,
              ),
              onPressed: () => setState(() => _showComparisonMode = !_showComparisonMode),
            ),
          if (_beforePhoto != null || _afterPhoto != null)
            IconButton(
              icon: Icon(LucideIcons.save, color: colors.accentPrimary),
              onPressed: _saveComparison,
            ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          if (_beforePhoto == null || _afterPhoto == null)
            _buildInstructions(colors),

          // Photo display area
          Expanded(
            child: _beforePhoto != null && _afterPhoto != null && _showComparisonMode
                ? _buildSliderComparison(colors)
                : _buildSideBySide(colors, cameraService),
          ),

          // Bottom actions
          if (_beforePhoto != null && _afterPhoto != null)
            _buildBottomActions(colors),
        ],
      ),
    );
  }

  Widget _buildInstructions(ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentInfo.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: colors.accentInfo, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _beforePhoto == null
                  ? 'Capture or select the BEFORE photo first'
                  : 'Now capture the AFTER photo from the same angle',
              style: TextStyle(fontSize: 13, color: colors.accentInfo, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySide(ZaftoColors colors, FieldCameraService cameraService) {
    return Row(
      children: [
        // Before section
        Expanded(
          child: _buildPhotoSection(
            colors,
            cameraService,
            label: 'BEFORE',
            photo: _beforePhoto,
            color: colors.accentInfo,
            onCapture: (photo) => setState(() => _beforePhoto = photo),
            onClear: () => setState(() => _beforePhoto = null),
          ),
        ),
        // Divider
        Container(
          width: 2,
          color: colors.borderSubtle,
        ),
        // After section
        Expanded(
          child: _buildPhotoSection(
            colors,
            cameraService,
            label: 'AFTER',
            photo: _afterPhoto,
            color: colors.accentSuccess,
            onCapture: (photo) => setState(() => _afterPhoto = photo),
            onClear: () => setState(() => _afterPhoto = null),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(
    ZaftoColors colors,
    FieldCameraService cameraService, {
    required String label,
    required CapturedPhoto? photo,
    required Color color,
    required Function(CapturedPhoto) onCapture,
    required VoidCallback onClear,
  }) {
    return Column(
      children: [
        // Label header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: color.withOpacity(0.15),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Photo or capture button
        Expanded(
          child: photo != null
              ? _buildPhotoDisplay(colors, photo, color, onClear)
              : _buildCapturePrompt(colors, cameraService, color, onCapture),
        ),
      ],
    );
  }

  Widget _buildPhotoDisplay(ZaftoColors colors, CapturedPhoto photo, Color accentColor, VoidCallback onClear) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo
        Image.memory(photo.bytes, fit: BoxFit.cover),

        // Timestamp overlay
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      photo.timestampDisplay,
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (photo.hasLocation) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          photo.locationDisplay,
                          style: const TextStyle(fontSize: 9, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Clear button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onClear();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapturePrompt(
    ZaftoColors colors,
    FieldCameraService cameraService,
    Color accentColor,
    Function(CapturedPhoto) onCapture,
  ) {
    return GestureDetector(
      onTap: () => _capturePhoto(cameraService, onCapture),
      child: Container(
        color: colors.fillDefault,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.camera, size: 32, color: accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to capture',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textSecondary),
              ),
              const SizedBox(height: 24),
              // Gallery option
              TextButton.icon(
                icon: Icon(LucideIcons.image, size: 18, color: colors.textTertiary),
                label: Text('Choose from gallery', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
                onPressed: () => _pickFromGallery(cameraService, onCapture),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderComparison(ZaftoColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderPosition = (_sliderPosition + details.delta.dx / constraints.maxWidth)
                  .clamp(0.0, 1.0);
            });
          },
          child: Stack(
            children: [
              // After image (full)
              Positioned.fill(
                child: Image.memory(_afterPhoto!.bytes, fit: BoxFit.cover),
              ),

              // Before image (clipped)
              Positioned.fill(
                child: ClipRect(
                  clipper: _SliderClipper(_sliderPosition),
                  child: Image.memory(_beforePhoto!.bytes, fit: BoxFit.cover),
                ),
              ),

              // Slider line
              Positioned(
                left: constraints.maxWidth * _sliderPosition - 2,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  color: Colors.white,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.moveHorizontal, size: 20, color: Colors.black),
                    ),
                  ),
                ),
              ),

              // Labels
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.accentInfo,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('BEFORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.accentSuccess,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('AFTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),

              // Timestamps
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildTimestampBadge(_beforePhoto!),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: _buildTimestampBadge(_afterPhoto!),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimestampBadge(CapturedPhoto photo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            photo.timestampDisplay,
            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          if (photo.hasLocation)
            Text(
              photo.locationDisplay,
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        border: Border(top: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(LucideIcons.refreshCw, color: colors.textSecondary),
              label: Text('Reset', style: TextStyle(color: colors.textSecondary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.borderDefault),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                setState(() {
                  _beforePhoto = null;
                  _afterPhoto = null;
                  _showComparisonMode = false;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.share),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _exportComparison,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _capturePhoto(FieldCameraService service, Function(CapturedPhoto) onCapture) async {
    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      final photo = await service.capturePhoto(
        source: ImageSource.camera,
        addDateStamp: true,
        addLocationStamp: true,
      );

      if (photo != null) {
        onCapture(photo);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showError('Failed to capture: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery(FieldCameraService service, Function(CapturedPhoto) onCapture) async {
    HapticFeedback.lightImpact();

    try {
      final photo = await service.capturePhoto(
        source: ImageSource.gallery,
        addDateStamp: true,
        addLocationStamp: true,
      );

      if (photo != null) {
        onCapture(photo);
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  Future<void> _saveComparison() async {
    // TODO: BACKEND - Save comparison to job
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comparison saved'), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _exportComparison() async {
    // TODO: Generate side-by-side image and share
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon'), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }
}

// ============================================================
// SLIDER CLIPPER
// ============================================================

class _SliderClipper extends CustomClipper<Rect> {
  final double position;

  _SliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) => position != oldClipper.position;
}
