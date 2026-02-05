import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/field_camera_service.dart';

/// Client Signature Capture - Digital signature for approvals, change orders, completion
class ClientSignatureScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final String? documentType;
  final String? documentTitle;

  const ClientSignatureScreen({
    super.key,
    this.jobId,
    this.documentType,
    this.documentTitle,
  });

  @override
  ConsumerState<ClientSignatureScreen> createState() => _ClientSignatureScreenState();
}

class _ClientSignatureScreenState extends ConsumerState<ClientSignatureScreen> {
  // Signature state
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSigned = false;

  // Form fields
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  _SignatureType _signatureType = _SignatureType.approval;

  // Location/time
  String? _currentAddress;
  final DateTime _signatureDate = DateTime.now();

  // Saving state
  bool _isSaving = false;
  Uint8List? _signatureImage;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    if (widget.documentType != null) {
      _signatureType = _SignatureType.values.firstWhere(
        (t) => t.name == widget.documentType,
        orElse: () => _SignatureType.approval,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final cameraService = ref.read(fieldCameraServiceProvider);
    final location = await cameraService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentAddress = location.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgElevated,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => _confirmExit(colors),
        ),
        title: Text('Signature Capture', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [
          if (_hasSigned)
            IconButton(
              icon: Icon(LucideIcons.rotateCcw, color: colors.textTertiary),
              onPressed: _clearSignature,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document type selector
            _buildDocumentTypeSelector(colors),
            const SizedBox(height: 20),

            // Document info
            _buildDocumentInfo(colors),
            const SizedBox(height: 20),

            // Signature pad
            _buildSignaturePad(colors),
            const SizedBox(height: 20),

            // Signer information
            _buildSignerInfo(colors),
            const SizedBox(height: 20),

            // Notes
            _buildNotesSection(colors),
            const SizedBox(height: 24),

            // Legal disclaimer
            _buildLegalDisclaimer(colors),
            const SizedBox(height: 24),

            // Submit button
            _buildSubmitButton(colors),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeSelector(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.fileSignature, size: 18, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Text(
              'DOCUMENT TYPE',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _SignatureType.values.map((type) {
              final isSelected = _signatureType == type;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _signatureType = type);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? type.color.withOpacity(0.2) : colors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? type.color : colors.borderSubtle,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(type.icon, size: 18, color: isSelected ? type.color : colors.textTertiary),
                      const SizedBox(width: 8),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? type.color : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _signatureType.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _signatureType.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _signatureType.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(_signatureType.icon, color: _signatureType.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.documentTitle ?? _signatureType.label,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _signatureType.description,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timestamp
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: colors.textTertiary),
              const SizedBox(width: 6),
              Text(
                FieldCameraService.formatTimestamp(_signatureDate),
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],
          ),
          if (_currentAddress != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 14, color: colors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _currentAddress!,
                    style: TextStyle(fontSize: 12, color: colors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (widget.jobId != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(LucideIcons.briefcase, size: 14, color: colors.textTertiary),
                const SizedBox(width: 6),
                Text('Job #${widget.jobId}', style: TextStyle(fontSize: 12, color: colors.textTertiary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignaturePad(ZaftoColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.penTool, size: 18, color: colors.accentPrimary),
            const SizedBox(width: 8),
            Text(
              'SIGNATURE',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
            ),
            const Spacer(),
            if (_hasSigned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentSuccess.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.check, size: 12, color: colors.accentSuccess),
                    const SizedBox(width: 4),
                    Text('Signed', style: TextStyle(fontSize: 11, color: colors.accentSuccess, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hasSigned ? colors.accentSuccess : colors.borderDefault, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Signature area
                GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentStroke = [details.localPosition];
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentStroke = [..._currentStroke, details.localPosition];
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      if (_currentStroke.isNotEmpty) {
                        _strokes.add(_currentStroke);
                        _currentStroke = [];
                        _hasSigned = true;
                      }
                    });
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      strokes: _strokes,
                      currentStroke: _currentStroke,
                    ),
                    size: Size.infinite,
                  ),
                ),
                // Signature line
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                ),
                // X marker
                Positioned(
                  bottom: 45,
                  left: 20,
                  child: Text(
                    'X',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                // Instruction
                if (!_hasSigned)
                  Center(
                    child: Text(
                      'Sign here',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: Icon(LucideIcons.eraser, size: 16, color: colors.textTertiary),
              label: Text('Clear', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
              onPressed: _hasSigned ? _clearSignature : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignerInfo(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.user, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'SIGNER INFORMATION',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            style: TextStyle(color: colors.textPrimary, fontSize: 15),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              labelStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
              hintText: 'Enter printed name',
              hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.6)),
              prefixIcon: Icon(LucideIcons.user, color: colors.textTertiary, size: 20),
              filled: true,
              fillColor: colors.fillDefault,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.accentPrimary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _titleController,
            style: TextStyle(color: colors.textPrimary, fontSize: 15),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Title/Relationship',
              labelStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
              hintText: 'e.g., Homeowner, Property Manager',
              hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.6)),
              prefixIcon: Icon(LucideIcons.briefcase, color: colors.textTertiary, size: 20),
              filled: true,
              fillColor: colors.fillDefault,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.accentPrimary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.messageSquare, size: 18, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                'ADDITIONAL NOTES',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Any conditions, exceptions, or comments...',
              hintStyle: TextStyle(color: colors.textTertiary.withOpacity(0.6), fontSize: 13),
              filled: true,
              fillColor: colors.fillDefault,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.accentPrimary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDisclaimer(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.fillDefault,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 16, color: colors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'By signing, I acknowledge that I have reviewed the ${_signatureType.label.toLowerCase()} and agree to its terms. '
              'This electronic signature has the same legal validity as a handwritten signature.',
              style: TextStyle(fontSize: 11, color: colors.textTertiary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ZaftoColors colors) {
    final isValid = _hasSigned && _nameController.text.trim().isNotEmpty;

    return ElevatedButton.icon(
      icon: _isSaving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.isDark ? Colors.black : Colors.white),
            )
          : const Icon(LucideIcons.checkCircle, size: 24),
      label: Text(
        _isSaving ? 'Saving...' : 'Complete Signature',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isValid ? colors.accentSuccess : colors.textTertiary,
        foregroundColor: colors.isDark ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        minimumSize: const Size(double.infinity, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: isValid && !_isSaving ? _saveSignature : null,
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _clearSignature() {
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _hasSigned = false;
      _signatureImage = null;
    });
  }

  Future<void> _saveSignature() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the signer\'s name'), backgroundColor: Colors.red),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSaving = true);

    try {
      // Generate signature image
      _signatureImage = await _generateSignatureImage();

      // TODO: BACKEND - Save signature
      // - Upload signature image to cloud storage
      // - Create signature record with:
      //   - Document type
      //   - Signer name and title
      //   - Timestamp
      //   - GPS location
      //   - Job ID if applicable
      //   - Notes
      //   - Signature image URL
      // - Update related document status
      // - Send confirmation to client

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('${_signatureType.label} signed by ${_nameController.text}')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, {
          'signed': true,
          'signerName': _nameController.text,
          'signerTitle': _titleController.text,
          'documentType': _signatureType.name,
          'timestamp': _signatureDate.toIso8601String(),
          'notes': _notesController.text,
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<Uint8List> _generateSignatureImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(600, 300);

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw signature
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Scale strokes to fit the image
    final scaleX = size.width / 400; // Assuming original pad was ~400 wide
    final scaleY = size.height / 200; // Assuming original pad was ~200 tall

    for (final stroke in _strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx * scaleX, stroke.first.dy * scaleY);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx * scaleX, stroke[i].dy * scaleY);
      }
      canvas.drawPath(path, paint);
    }

    // Draw signature line
    canvas.drawLine(
      Offset(40, size.height - 60),
      Offset(size.width - 40, size.height - 60),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 1,
    );

    // Add timestamp
    final textPainter = TextPainter(
      text: TextSpan(
        text: FieldCameraService.formatTimestamp(_signatureDate),
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(40, size.height - 40));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _confirmExit(ZaftoColors colors) {
    if (!_hasSigned && _nameController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgElevated,
        title: Text('Discard Signature?', style: TextStyle(color: colors.textPrimary)),
        content: Text('You have unsaved changes. Are you sure you want to exit?', style: TextStyle(color: colors.textSecondary)),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: colors.textTertiary)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Discard', style: TextStyle(color: colors.accentError)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIGNATURE PAINTER
// ============================================================

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path();
      path.moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

// ============================================================
// ENUMS
// ============================================================

enum _SignatureType {
  approval(
    label: 'Work Approval',
    description: 'Client approves proposed work scope and pricing',
    icon: LucideIcons.checkSquare,
    color: Colors.blue,
  ),
  changeOrder(
    label: 'Change Order',
    description: 'Approval for additional work or modifications',
    icon: LucideIcons.fileDiff,
    color: Colors.orange,
  ),
  completion(
    label: 'Job Completion',
    description: 'Client confirms work is complete and satisfactory',
    icon: LucideIcons.checkCircle,
    color: Colors.green,
  ),
  invoice(
    label: 'Invoice Acknowledgment',
    description: 'Receipt of invoice and payment terms',
    icon: LucideIcons.receipt,
    color: Colors.purple,
  ),
  waiver(
    label: 'Liability Waiver',
    description: 'Acknowledgment of risks and limitations',
    icon: LucideIcons.shieldAlert,
    color: Colors.red,
  );

  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _SignatureType({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}
