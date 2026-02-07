// ZAFTO Before/After Photo Viewer — Side-by-Side Comparison
// Interactive slider to reveal before/after walkthrough photos.
// Supports landscape (side-by-side) and portrait (stacked with slider)
// viewing modes. Both photos can be annotated independently.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import 'photo_annotation_screen.dart';

// Before/After comparison viewer screen
class BeforeAfterViewer extends ConsumerStatefulWidget {
  final String beforeUrl;
  final String afterUrl;
  final String? beforeDate;
  final String? afterDate;
  final String? title;
  final Map<String, dynamic>? beforeAnnotations;
  final Map<String, dynamic>? afterAnnotations;

  const BeforeAfterViewer({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
    this.beforeDate,
    this.afterDate,
    this.title,
    this.beforeAnnotations,
    this.afterAnnotations,
  });

  @override
  ConsumerState<BeforeAfterViewer> createState() =>
      _BeforeAfterViewerState();
}

class _BeforeAfterViewerState
    extends ConsumerState<BeforeAfterViewer> {
  // Slider position (0.0 = full before, 1.0 = full after)
  double _sliderPosition = 0.5;
  _ViewMode _viewMode = _ViewMode.slider;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title ?? 'Before / After',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // View mode toggle
          _buildViewModeButton(
              _ViewMode.slider, LucideIcons.columns, 'Slider'),
          _buildViewModeButton(
              _ViewMode.sideBySide, LucideIcons.layoutGrid, 'Split'),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _viewMode == _ViewMode.slider
            ? _buildSliderView(colors, isLandscape)
            : _buildSideBySideView(colors, isLandscape),
      ),
    );
  }

  Widget _buildViewModeButton(
      _ViewMode mode, IconData icon, String tooltip) {
    final isSelected = _viewMode == mode;
    return IconButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _viewMode = mode);
      },
      icon: Icon(
        icon,
        size: 18,
        color: isSelected ? const Color(0xFFF59E0B) : Colors.white54,
      ),
      tooltip: tooltip,
    );
  }

  // ============================================================
  // SLIDER VIEW — Drag divider to reveal before/after
  // ============================================================

  Widget _buildSliderView(ZaftoColors colors, bool isLandscape) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final dividerX = width * _sliderPosition;

              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _sliderPosition =
                        (details.localPosition.dx / width)
                            .clamp(0.0, 1.0);
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // After image (full, behind)
                    Positioned.fill(
                      child: Image.network(
                        widget.afterUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            _buildImageError(colors, 'After'),
                      ),
                    ),

                    // Before image (clipped to slider position)
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _SliderClipper(dividerX),
                        child: Image.network(
                          widget.beforeUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              _buildImageError(colors, 'Before'),
                        ),
                      ),
                    ),

                    // Divider line
                    Positioned(
                      left: dividerX - 1.5,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 3,
                        color: Colors.white,
                      ),
                    ),

                    // Divider handle
                    Positioned(
                      left: dividerX - 20,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.chevronLeft,
                                  size: 14, color: Colors.black54),
                              Icon(LucideIcons.chevronRight,
                                  size: 14, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // "BEFORE" label (left side)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _buildLabel('BEFORE', widget.beforeDate),
                    ),

                    // "AFTER" label (right side)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _buildLabel('AFTER', widget.afterDate),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom actions bar
        _buildActionsBar(colors),
      ],
    );
  }

  // ============================================================
  // SIDE-BY-SIDE VIEW
  // ============================================================

  Widget _buildSideBySideView(
      ZaftoColors colors, bool isLandscape) {
    return Column(
      children: [
        Expanded(
          child: isLandscape
              ? Row(
                  children: [
                    Expanded(child: _buildPhotoCard(colors, true)),
                    Container(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.15)),
                    Expanded(child: _buildPhotoCard(colors, false)),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildPhotoCard(colors, true)),
                    Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.15)),
                    Expanded(child: _buildPhotoCard(colors, false)),
                  ],
                ),
        ),
        _buildActionsBar(colors),
      ],
    );
  }

  Widget _buildPhotoCard(ZaftoColors colors, bool isBefore) {
    final url = isBefore ? widget.beforeUrl : widget.afterUrl;
    final date = isBefore ? widget.beforeDate : widget.afterDate;
    final label = isBefore ? 'BEFORE' : 'AFTER';

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              _buildImageError(colors, label),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: _buildLabel(label, date),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildLabel(String label, String? date) {
    final isBefore = label == 'BEFORE';
    final bgColor = isBefore
        ? const Color(0xFFEF4444).withValues(alpha: 0.85)
        : const Color(0xFF22C55E).withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          if (date != null && date.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              date,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageError(ZaftoColors colors, String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.imageOff,
              size: 32, color: colors.textTertiary),
          const SizedBox(height: 8),
          Text(
            '$label photo unavailable',
            style:
                TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsBar(ZaftoColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Annotate Before
          _buildActionButton(
            icon: LucideIcons.penTool,
            label: 'Annotate Before',
            onTap: () => _openAnnotation(
              widget.beforeUrl,
              widget.beforeAnnotations,
            ),
          ),
          const SizedBox(width: 16),
          // Annotate After
          _buildActionButton(
            icon: LucideIcons.penTool,
            label: 'Annotate After',
            onTap: () => _openAnnotation(
              widget.afterUrl,
              widget.afterAnnotations,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _openAnnotation(
    String imageUrl,
    Map<String, dynamic>? existingAnnotations,
  ) {
    Navigator.push<AnnotationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoAnnotationScreen(
          imageUrl: imageUrl,
          existingAnnotations: existingAnnotations,
        ),
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

enum _ViewMode { slider, sideBySide }

// Custom clipper that clips the before image to the slider position
class _SliderClipper extends CustomClipper<Rect> {
  final double dividerX;

  _SliderClipper(this.dividerX);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, dividerX, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) {
    return oldClipper.dividerX != dividerX;
  }
}
