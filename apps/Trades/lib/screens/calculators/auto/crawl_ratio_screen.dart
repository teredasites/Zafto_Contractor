import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Crawl Ratio Calculator - Off-road low-range gearing
class CrawlRatioScreen extends ConsumerStatefulWidget {
  const CrawlRatioScreen({super.key});
  @override
  ConsumerState<CrawlRatioScreen> createState() => _CrawlRatioScreenState();
}

class _CrawlRatioScreenState extends ConsumerState<CrawlRatioScreen> {
  final _firstGearController = TextEditingController();
  final _transferCaseLowController = TextEditingController();
  final _diffRatioController = TextEditingController();

  double? _crawlRatio;

  void _calculate() {
    final firstGear = double.tryParse(_firstGearController.text);
    final tcLow = double.tryParse(_transferCaseLowController.text);
    final diffRatio = double.tryParse(_diffRatioController.text);

    if (firstGear == null || tcLow == null || diffRatio == null) {
      setState(() { _crawlRatio = null; });
      return;
    }

    setState(() {
      _crawlRatio = firstGear * tcLow * diffRatio;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _firstGearController.clear();
    _transferCaseLowController.clear();
    _diffRatioController.clear();
    setState(() { _crawlRatio = null; });
  }

  @override
  void dispose() {
    _firstGearController.dispose();
    _transferCaseLowController.dispose();
    _diffRatioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Crawl Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'First Gear Ratio', unit: ':1', hint: 'Transmission 1st', controller: _firstGearController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Transfer Case Low', unit: ':1', hint: '4Lo ratio', controller: _transferCaseLowController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Differential Ratio', unit: ':1', hint: 'Final drive', controller: _diffRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_crawlRatio != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildReferenceCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Crawl = 1st × T-Case Low × Diff', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Maximum gear reduction for rock crawling', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_crawlRatio! > 100) {
      analysis = 'Competition crawler - extreme low-speed control';
    } else if (_crawlRatio! > 60) {
      analysis = 'Serious off-road - excellent technical capability';
    } else if (_crawlRatio! > 40) {
      analysis = 'Good trail ratio - handles most obstacles';
    } else {
      analysis = 'Mild off-road - may struggle on steep technical terrain';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Crawl Ratio', '${_crawlRatio!.toStringAsFixed(1)}:1', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildReferenceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON TRANSFER CASES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRefRow(colors, 'NP231', '2.72:1'),
        _buildRefRow(colors, 'NP241OR', '4.0:1'),
        _buildRefRow(colors, 'NP242', '2.72:1'),
        _buildRefRow(colors, 'Atlas II', '3.0-5.0:1'),
        _buildRefRow(colors, 'Rubicon (MP3022)', '4.0:1'),
      ]),
    );
  }

  Widget _buildRefRow(ZaftoColors colors, String name, String ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(name, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(ratio, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
