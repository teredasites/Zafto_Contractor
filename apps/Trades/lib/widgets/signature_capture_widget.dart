import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

/// Widget for capturing customer signatures
class SignatureCaptureWidget extends StatefulWidget {
  final Function(String signatureData, Uint8List signatureImage)? onSignatureCaptured;
  final Function()? onClear;
  final double height;
  final Color penColor;
  final Color backgroundColor;
  final double strokeWidth;
  final bool showControls;
  final String? initialSignature; // Base64 encoded signature data

  const SignatureCaptureWidget({
    super.key,
    this.onSignatureCaptured,
    this.onClear,
    this.height = 200,
    this.penColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.strokeWidth = 3.0,
    this.showControls = true,
    this.initialSignature,
  });

  @override
  State<SignatureCaptureWidget> createState() => _SignatureCaptureWidgetState();
}

class _SignatureCaptureWidgetState extends State<SignatureCaptureWidget> {
  late SignatureController _controller;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: widget.strokeWidth,
      penColor: widget.penColor,
      exportBackgroundColor: widget.backgroundColor,
      onDrawStart: () => setState(() => _hasSignature = true),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDone() async {
    if (_controller.isEmpty) return;

    try {
      // Get signature as PNG image
      final signatureImage = await _controller.toPngBytes();
      if (signatureImage == null) return;

      // Get signature points as JSON
      final points = _controller.points;
      final signatureData = jsonEncode(points.map((p) {
        return {'x': p.offset.dx, 'y': p.offset.dy, 'p': p.pressure};
      }).toList());

      widget.onSignatureCaptured?.call(signatureData, signatureImage);
    } catch (e) {
      debugPrint('Error capturing signature: $e');
    }
  }

  void _handleClear() {
    _controller.clear();
    setState(() => _hasSignature = false);
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Signature pad
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                // Signature canvas
                Signature(
                  controller: _controller,
                  backgroundColor: widget.backgroundColor,
                ),

                // Signature line
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 50,
                  child: Container(
                    height: 1,
                    color: Colors.grey.shade400,
                  ),
                ),

                // "Sign here" label
                Positioned(
                  left: 20,
                  bottom: 30,
                  child: Text(
                    'Sign here',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                // X mark
                Positioned(
                  left: 20,
                  bottom: 55,
                  child: Text(
                    '✕',
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

        // Controls
        if (widget.showControls) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              // Clear button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _hasSignature ? _handleClear : null,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Done button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _hasSignature ? _handleDone : null,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept Signature'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Full screen signature capture dialog
class SignatureCaptureDialog extends StatelessWidget {
  final String title;
  final String? customerName;

  const SignatureCaptureDialog({
    super.key,
    this.title = 'Customer Signature',
    this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  if (customerName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'By signing, $customerName agrees to the terms and charges.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Signature pad
            Padding(
              padding: const EdgeInsets.all(20),
              child: SignatureCaptureWidget(
                height: 250,
                onSignatureCaptured: (data, image) {
                  Navigator.of(context).pop(SignatureResult(
                    data: data,
                    image: image,
                    signedByName: customerName,
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show signature capture dialog and return result
  static Future<SignatureResult?> show(
    BuildContext context, {
    String title = 'Customer Signature',
    String? customerName,
  }) async {
    return showDialog<SignatureResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignatureCaptureDialog(
        title: title,
        customerName: customerName,
      ),
    );
  }
}

/// Result from signature capture
class SignatureResult {
  final String data;        // JSON encoded point data
  final Uint8List image;    // PNG image bytes
  final String? signedByName;

  const SignatureResult({
    required this.data,
    required this.image,
    this.signedByName,
  });

  /// Get image as base64 string
  String get imageBase64 => base64Encode(image);
}

/// Compact signature preview widget
class SignaturePreview extends StatelessWidget {
  final Uint8List? signatureImage;
  final String? signedByName;
  final DateTime? signedAt;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const SignaturePreview({
    super.key,
    this.signatureImage,
    this.signedByName,
    this.signedAt,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasSignature = signatureImage != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: hasSignature ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSignature ? Colors.grey.shade300 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: hasSignature
            ? Stack(
                children: [
                  // Signature image
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.memory(
                        signatureImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Clear button
                  if (onClear != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: onClear,
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.all(4),
                          minimumSize: const Size(28, 28),
                        ),
                      ),
                    ),

                  // Signed by info
                  if (signedByName != null)
                    Positioned(
                      bottom: 8,
                      left: 12,
                      child: Text(
                        signedByName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),

                  if (signedAt != null)
                    Positioned(
                      bottom: 8,
                      right: 12,
                      child: Text(
                        _formatDateTime(signedAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.draw_outlined,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to capture signature',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
