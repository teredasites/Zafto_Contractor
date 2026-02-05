/// Field Scan - Design System v2.6
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/ai_service.dart';
import 'scan_result_screen.dart';
import 'credits_purchase_screen.dart';

class AIScannerScreen extends ConsumerStatefulWidget {
  const AIScannerScreen({super.key});
  @override
  ConsumerState<AIScannerScreen> createState() => _AIScannerScreenState();
}

class _AIScannerScreenState extends ConsumerState<AIScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isScanning = false;
  String? _selectedScanType;

  List<_ScanOption> _scanOptions(ZaftoColors colors) => [
    _ScanOption(id: 'smart', title: 'Smart Scan', subtitle: 'Auto-detect what\'s in the image', icon: LucideIcons.sparkles, color: colors.accentPrimary, credits: 1),
    _ScanOption(id: 'panel', title: 'Panel Analysis', subtitle: 'Analyze breakers, load, issues', icon: LucideIcons.layoutGrid, color: colors.textSecondary, credits: 1),
    _ScanOption(id: 'nameplate', title: 'Nameplate Reader', subtitle: 'Extract motor/equipment data', icon: LucideIcons.scanLine, color: colors.accentSuccess, credits: 1),
    _ScanOption(id: 'wire', title: 'Wire Identifier', subtitle: 'ID wire type, gauge, ampacity', icon: LucideIcons.plug, color: Colors.orange, credits: 1),
    _ScanOption(id: 'violation', title: 'Code Check', subtitle: 'Scan for NEC violations', icon: LucideIcons.shieldAlert, color: Colors.red, credits: 2),
  ];

  @override
  void initState() { super.initState(); _initializeService(); }
  Future<void> _initializeService() async { await aiService.initialize(); if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    final options = _scanOptions(colors);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0, leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Field Scan', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
        actions: [_buildCreditsChip(colors), const SizedBox(width: 12)]),
      body: SafeArea(child: Column(children: [_buildHeader(colors), Expanded(child: _buildScanOptions(colors, options)), _buildDisclaimerBanner(colors)])),
    );
  }

  Widget _buildCreditsChip(ZaftoColors colors) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreditsPurchaseScreen())),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.borderDefault)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.zap, color: colors.accentPrimary, size: 16), const SizedBox(width: 4), Text('${aiService.totalCredits}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 14))])),
    );
  }

  Widget _buildHeader(ZaftoColors colors) {
    return Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Snap a photo of any electrical equipment', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
      const SizedBox(height: 8),
      Row(children: [_buildQuickStat('${aiService.totalScans}', 'Scans', colors), const SizedBox(width: 16), _buildQuickStat('${aiService.freeCredits}', 'Free', colors), const SizedBox(width: 16), _buildQuickStat('${aiService.paidCredits}', 'Paid', colors)]),
    ]));
  }

  Widget _buildQuickStat(String value, String label, ZaftoColors colors) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)), Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12))]);

  Widget _buildScanOptions(ZaftoColors colors, List<_ScanOption> options) {
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: options.length, itemBuilder: (context, index) {
      final option = options[index];
      return _ScanOptionCard(option: option, colors: colors, isLoading: _isScanning && _selectedScanType == option.id, onTap: () => _showImageSourceDialog(option, colors));
    });
  }

  Widget _buildDisclaimerBanner(ZaftoColors colors) {
    return Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
      child: Row(children: [const Icon(LucideIcons.info, color: Colors.orange, size: 20), const SizedBox(width: 10), Expanded(child: Text('AI analysis is for reference only. Always verify with NEC and local codes.', style: TextStyle(color: Colors.orange, fontSize: 12)))]));
  }

  void _showImageSourceDialog(_ScanOption option, ZaftoColors colors) {
    if (aiService.totalCredits < option.credits) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Not enough credits'), backgroundColor: colors.bgElevated, action: SnackBarAction(label: 'Buy', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreditsPurchaseScreen())))));
      return;
    }
    showModalBottomSheet(context: context, backgroundColor: colors.bgElevated, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Select Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _SourceButton(icon: LucideIcons.camera, label: 'Camera', colors: colors, onTap: () { Navigator.pop(context); _captureImage(option, ImageSource.camera); })),
          const SizedBox(width: 16),
          Expanded(child: _SourceButton(icon: LucideIcons.image, label: 'Gallery', colors: colors, onTap: () { Navigator.pop(context); _captureImage(option, ImageSource.gallery); })),
        ]),
        const SizedBox(height: 16),
      ])));
  }

  Future<ScanResult> _performScan(XFile imageFile, String scanType) async {
    // Web: AI scanning not supported (needs native file access)
    if (kIsWeb) {
      return ScanResult.error(scanType, 'AI scanning is only available on mobile devices.');
    }
    return aiService.analyzeFromPath(imageFile.path, scanType);
  }

  Future<void> _captureImage(_ScanOption option, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 85);
      if (image == null) return;
      setState(() { _isScanning = true; _selectedScanType = option.id; });
      HapticFeedback.mediumImpact();
      final result = await _performScan(image, option.id);
      if (mounted) {
        setState(() { _isScanning = false; _selectedScanType = null; });
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScanResultScreen(result: result, imagePath: image.path)));
      }
    } catch (e) {
      setState(() { _isScanning = false; _selectedScanType = null; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
    }
  }
}

class _ScanOption { final String id; final String title; final String subtitle; final IconData icon; final Color color; final int credits; const _ScanOption({required this.id, required this.title, required this.subtitle, required this.icon, required this.color, required this.credits}); }

class _ScanOptionCard extends StatelessWidget {
  final _ScanOption option; final ZaftoColors colors; final bool isLoading; final VoidCallback onTap;
  const _ScanOptionCard({required this.option, required this.colors, required this.isLoading, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12), child: Material(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), child: InkWell(onTap: isLoading ? null : onTap, borderRadius: BorderRadius.circular(14),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: option.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: isLoading ? Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: option.color)) : Icon(option.icon, color: option.color, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(option.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary)), const SizedBox(height: 2), Text(option.subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 13))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.zap, size: 12, color: colors.accentPrimary), const SizedBox(width: 2), Text('${option.credits}', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600))])),
      ])))));
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon; final String label; final ZaftoColors colors; final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.colors, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 24), decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Icon(icon, size: 32, color: colors.accentPrimary), const SizedBox(height: 8), Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary))])));
  }
}
