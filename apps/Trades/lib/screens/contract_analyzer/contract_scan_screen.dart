/// ZAFTO Contract Scan Screen
/// Sprint P0 - February 2026
/// Camera and file upload interface for contract scanning

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../models/contract_analysis.dart';
import '../../services/contract_analyzer_service.dart';
import 'analysis_result_screen.dart';

class ContractScanScreen extends ConsumerStatefulWidget {
  const ContractScanScreen({super.key});

  @override
  ConsumerState<ContractScanScreen> createState() => _ContractScanScreenState();
}

class _ContractScanScreenState extends ConsumerState<ContractScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _capturedImages = [];
  bool _isAnalyzing = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: _isAnalyzing
            ? _buildAnalyzingState(colors)
            : _buildCaptureState(colors),
      ),
    );
  }

  Widget _buildCaptureState(ZaftoColors colors) {
    return Column(
      children: [
        _buildHeader(colors),
        Expanded(
          child: _capturedImages.isEmpty
              ? _buildUploadOptions(colors)
              : _buildCapturedPreview(colors),
        ),
        if (_capturedImages.isNotEmpty) _buildBottomActions(colors),
      ],
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Icon(LucideIcons.x, size: 20, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _capturedImages.isEmpty ? 'Scan Contract' : 'Review Pages',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  _capturedImages.isEmpty
                      ? 'Take photos or upload a PDF'
                      : '${_capturedImages.length} page${_capturedImages.length != 1 ? 's' : ''} captured',
                  style: TextStyle(fontSize: 14, color: colors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOptions(ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera option
          _buildOptionCard(
            colors,
            icon: LucideIcons.camera,
            title: 'Take Photos',
            subtitle: 'Scan contract pages with camera',
            color: colors.accentPrimary,
            onTap: _captureFromCamera,
          ),
          const SizedBox(height: 16),
          // Gallery option
          _buildOptionCard(
            colors,
            icon: LucideIcons.image,
            title: 'Choose from Photos',
            subtitle: 'Select existing images',
            color: colors.accentInfo,
            onTap: _selectFromGallery,
          ),
          const SizedBox(height: 16),
          // PDF option
          _buildOptionCard(
            colors,
            icon: LucideIcons.fileText,
            title: 'Upload PDF',
            subtitle: 'Select a PDF document',
            color: colors.accentSuccess,
            onTap: _selectPdf,
          ),
          const SizedBox(height: 40),
          // Tips
          Container(
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
                    Icon(LucideIcons.lightbulb, size: 16, color: colors.accentWarning),
                    const SizedBox(width: 8),
                    Text(
                      'Tips for best results',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTip(colors, 'Good lighting - avoid shadows'),
                _buildTip(colors, 'Keep pages flat and straight'),
                _buildTip(colors, 'Include all pages of the contract'),
                _buildTip(colors, 'Make sure text is legible'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    ZaftoColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: colors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(ZaftoColors colors, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.check, size: 14, color: colors.accentSuccess),
          const SizedBox(width: 8),
          Text(
            tip,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedPreview(ZaftoColors colors) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _capturedImages.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == _capturedImages.length) {
                return _buildAddMoreButton(colors);
              }
              return _buildImageTile(colors, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageTile(ZaftoColors colors, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.file(
              File(_capturedImages[index]),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        // Page number
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgBase.withOpacity(0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Page ${index + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
        // Delete button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _capturedImages.removeAt(index));
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.accentDestructive,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreButton(ZaftoColors colors) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showAddOptions(colors);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.fillDefault,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.plus, size: 24, color: colors.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Page',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
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
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _capturedImages.clear());
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.fillDefault,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _startAnalysis,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.sparkles, size: 20, color: colors.textOnAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Analyze Contract',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textOnAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingState(ZaftoColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated AI indicator
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Analyzing Contract',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
            // Analysis stages
            _buildAnalysisStage(colors, 'Extracting text from images', _statusMessage.contains('Extracting')),
            _buildAnalysisStage(colors, 'Identifying contract type', _statusMessage.contains('Identifying')),
            _buildAnalysisStage(colors, 'Scanning for red flags', _statusMessage.contains('Scanning')),
            _buildAnalysisStage(colors, 'Checking missing protections', _statusMessage.contains('Checking')),
            _buildAnalysisStage(colors, 'Generating recommendations', _statusMessage.contains('Generating')),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisStage(ZaftoColors colors, String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? colors.accentPrimary.withOpacity(0.15) : colors.fillDefault,
              shape: BoxShape.circle,
            ),
            child: isActive
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                      ),
                    ),
                  )
                : Icon(LucideIcons.circle, size: 12, color: colors.textQuaternary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive ? colors.textPrimary : colors.textTertiary,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddOptions(ZaftoColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildSheetOption(
              colors,
              LucideIcons.camera,
              'Take Photo',
              () {
                Navigator.pop(context);
                _captureFromCamera();
              },
            ),
            _buildSheetOption(
              colors,
              LucideIcons.image,
              'Choose from Photos',
              () {
                Navigator.pop(context);
                _selectFromGallery();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption(ZaftoColors colors, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.fillDefault,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: colors.textSecondary),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(LucideIcons.chevronRight, size: 18, color: colors.textQuaternary),
          ],
        ),
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image != null) {
        setState(() => _capturedImages.add(image.path));
      }
    } catch (e) {
      _showError('Failed to capture image');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 90);
      if (images.isNotEmpty) {
        setState(() {
          _capturedImages.addAll(images.map((i) => i.path));
        });
      }
    } catch (e) {
      _showError('Failed to select images');
    }
  }

  Future<void> _selectPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        _analyzePdf(result.files.single.path!, result.files.single.name);
      }
    } catch (e) {
      _showError('Failed to select PDF');
    }
  }

  Future<void> _startAnalysis() async {
    if (_capturedImages.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Extracting text from images...';
    });

    try {
      final service = ref.read(contractAnalyzerServiceProvider);

      // Simulate analysis stages
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _statusMessage = 'Identifying contract type...');

      await Future.delayed(const Duration(seconds: 1));
      setState(() => _statusMessage = 'Scanning for red flags...');

      await Future.delayed(const Duration(seconds: 1));
      setState(() => _statusMessage = 'Checking missing protections...');

      await Future.delayed(const Duration(seconds: 1));
      setState(() => _statusMessage = 'Generating recommendations...');

      // Run actual analysis
      final analysis = await service.analyzeFromImages(
        imagePaths: _capturedImages,
        fileName: 'Contract_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Refresh analyses list
      ref.read(contractAnalysesProvider.notifier).refresh();

      // Navigate to results
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AnalysisResultScreen(analysis: analysis)),
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showError('Analysis failed: $e');
    }
  }

  Future<void> _analyzePdf(String path, String fileName) async {
    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Processing PDF...';
    });

    try {
      final service = ref.read(contractAnalyzerServiceProvider);

      await Future.delayed(const Duration(seconds: 1));
      setState(() => _statusMessage = 'Extracting text from PDF...');

      await Future.delayed(const Duration(seconds: 1));
      setState(() => _statusMessage = 'Scanning for red flags...');

      await Future.delayed(const Duration(seconds: 1));
      setState(() => _statusMessage = 'Generating recommendations...');

      final analysis = await service.analyzeFromPdf(
        pdfPath: path,
        fileName: fileName,
      );

      // Refresh analyses list
      ref.read(contractAnalysesProvider.notifier).refresh();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AnalysisResultScreen(analysis: analysis)),
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showError('Analysis failed: $e');
    }
  }

  void _showError(String message) {
    final colors = ref.read(zaftoColorsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.accentDestructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
