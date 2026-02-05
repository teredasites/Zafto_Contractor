/// Scan Result Screen - Design System v2.6
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../services/ai_service.dart';
// Conditional import for File
import 'scan_result_stub.dart' if (dart.library.io) 'scan_result_io.dart';

class ScanResultScreen extends ConsumerWidget {
  final ScanResult result;
  final String imagePath;
  final String scanType;
  const ScanResultScreen({super.key, required this.result, required this.imagePath, this.scanType = 'smart'});

  String _getTitle() => {'panel': 'Panel Analysis', 'nameplate': 'Nameplate Data', 'wire': 'Wire Identification', 'violation': 'Code Check', 'smart': 'Smart Scan'}[scanType] ?? 'Scan Results';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0, leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(_getTitle(), style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
        actions: [IconButton(icon: Icon(LucideIcons.share2, color: colors.textPrimary), onPressed: () => _shareResults(context))]),
      body: result.success ? _buildSuccessContent(context, colors) : _buildErrorContent(context, colors),
    );
  }

  void _shareResults(BuildContext context) { HapticFeedback.mediumImpact(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share feature coming soon'))); }

  Widget _buildSuccessContent(BuildContext context, ZaftoColors colors) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildImagePreview(colors),
      const SizedBox(height: 16),
      _buildConfidenceIndicator(colors),
      const SizedBox(height: 20),
      _buildResultsSection(context, colors),
      const SizedBox(height: 16),
      _buildDisclaimerCard(colors),
      const SizedBox(height: 80),
    ]));
  }

  Widget _buildErrorContent(BuildContext context, ZaftoColors colors) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48)),
      const SizedBox(height: 24),
      Text('Analysis Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary)),
      const SizedBox(height: 8),
      Text(result.error ?? 'Unknown error occurred', textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
      const SizedBox(height: 24),
      ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.refreshCw), label: const Text('Try Again'), style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.bgBase)),
    ])));
  }

  Widget _buildImagePreview(ZaftoColors colors) => ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9, child: buildImageFromPath(imagePath, fit: BoxFit.cover)));

  Widget _buildConfidenceIndicator(ZaftoColors colors) {
    final confidence = result.confidence ?? 0.0;
    final percentage = (confidence * 100).round();
    Color color; String label;
    if (confidence >= 0.8) { color = colors.accentSuccess; label = 'High Confidence'; }
    else if (confidence >= 0.5) { color = Colors.orange; label = 'Medium Confidence'; }
    else { color = Colors.red; label = 'Low Confidence'; }
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [Icon(LucideIcons.brain, color: color, size: 20), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)), const SizedBox(height: 4), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: confidence, backgroundColor: color.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation(color), minHeight: 6))])), const SizedBox(width: 12), Text('$percentage%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18))]));
  }

  Widget _buildResultsSection(BuildContext context, ZaftoColors colors) {
    final analysis = result.analysis; if (analysis == null) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Analysis Results', colors),
      _ResultCard(colors: colors, children: analysis.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).take(12).map((e) => _ResultRow(e.key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}').trim(), e.value.toString(), colors)).toList()),
    ]);
  }

  Widget _buildSectionTitle(String title, ZaftoColors colors, {Color? color}) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title.toUpperCase(), style: TextStyle(color: color ?? colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)));

  Widget _buildDisclaimerCard(ZaftoColors colors) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
      child: Row(children: [const Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 18), const SizedBox(width: 10), Expanded(child: Text('AI analysis is for reference only. Always verify with NEC and local codes before proceeding.', style: TextStyle(color: Colors.orange, fontSize: 11)))]));
  }
}

class _ResultCard extends StatelessWidget {
  final List<Widget> children; final ZaftoColors colors;
  const _ResultCard({required this.children, required this.colors});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderDefault)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));
}

class _ResultRow extends StatelessWidget {
  final String label; final String value; final ZaftoColors colors;
  const _ResultRow(this.label, this.value, this.colors);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)), Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right))]));
}
