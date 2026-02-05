import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Transformer Sizing Calculator - Landscape lighting transformer
class TransformerSizingScreen extends ConsumerStatefulWidget {
  const TransformerSizingScreen({super.key});
  @override
  ConsumerState<TransformerSizingScreen> createState() => _TransformerSizingScreenState();
}

class _TransformerSizingScreenState extends ConsumerState<TransformerSizingScreen> {
  final _totalWattsController = TextEditingController(text: '200');

  double? _minTransformer;
  double? _recommendedTransformer;
  double? _loadPercent;
  List<int> _availableSizes = [];

  @override
  void dispose() { _totalWattsController.dispose(); super.dispose(); }

  void _calculate() {
    final totalWatts = double.tryParse(_totalWattsController.text) ?? 200;

    // Standard transformer sizes
    const sizes = [150, 300, 600, 900, 1200];

    // Minimum: must cover load
    // Recommended: 70-80% load for headroom
    final recommended = totalWatts / 0.75;

    // Find appropriate sizes
    final available = sizes.where((s) => s >= totalWatts).toList();
    final minSize = available.isNotEmpty ? available.first : sizes.last;
    final recSize = sizes.firstWhere((s) => s >= recommended, orElse: () => sizes.last);

    final loadPercent = (totalWatts / recSize) * 100;

    setState(() {
      _minTransformer = minSize.toDouble();
      _recommendedTransformer = recSize.toDouble();
      _loadPercent = loadPercent;
      _availableSizes = available;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _totalWattsController.text = '200'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Transformer Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Total Fixture Wattage', unit: 'W', controller: _totalWattsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedTransformer != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_recommendedTransformer!.toStringAsFixed(0)}W', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Minimum size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_minTransformer!.toStringAsFixed(0)}W', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Load at recommended', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_loadPercent!.toStringAsFixed(0)}%', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 16),
            if (_availableSizes.isNotEmpty) Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSizes.map((size) {
                final isRecommended = size == _recommendedTransformer;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRecommended ? colors.accentPrimary : colors.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isRecommended ? colors.accentPrimary : colors.borderSubtle),
                  ),
                  child: Text('${size}W', style: TextStyle(color: isRecommended ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _buildTransformerGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTransformerGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TRANSFORMER TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Optimal load', '70-80%'),
        _buildTableRow(colors, 'Max load', '90%'),
        _buildTableRow(colors, 'Multi-tap', '11, 12, 13, 14, 15V'),
        _buildTableRow(colors, 'Timer/photocell', 'Built-in preferred'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
