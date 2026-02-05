import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Fertilizer Calculator - Lbs per 1000 sq ft
class FertilizerScreen extends ConsumerStatefulWidget {
  const FertilizerScreen({super.key});
  @override
  ConsumerState<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends ConsumerState<FertilizerScreen> {
  final _areaController = TextEditingController(text: '5000');
  final _nController = TextEditingController(text: '24');
  final _targetNController = TextEditingController(text: '1');

  double? _productLbs;
  double? _actualN;
  double? _actualP;
  double? _actualK;

  @override
  void dispose() { _areaController.dispose(); _nController.dispose(); _targetNController.dispose(); super.dispose(); }

  void _calculate() {
    final area = double.tryParse(_areaController.text) ?? 5000;
    final nPercent = double.tryParse(_nController.text) ?? 24;
    final targetN = double.tryParse(_targetNController.text) ?? 1;

    if (nPercent <= 0) {
      setState(() { _productLbs = null; });
      return;
    }

    // Lbs of product per 1000 sq ft = (target N lbs) / (N% / 100)
    final lbsPer1000 = targetN / (nPercent / 100);
    final totalLbs = lbsPer1000 * (area / 1000);

    // Actual nutrients applied
    final actualN = (totalLbs * nPercent / 100);

    setState(() {
      _productLbs = totalLbs;
      _actualN = actualN;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaController.text = '5000'; _nController.text = '24'; _targetNController.text = '1'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Fertilizer', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Lawn Area', unit: 'sq ft', controller: _areaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'N% (first number)', unit: '%', controller: _nController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Target N', unit: 'lbs/1000', controller: _targetNController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Target: 0.5-1 lb N per 1000 sq ft per application. Max 1 lb N to avoid burn.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_productLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PRODUCT NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_productLbs!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Actual N applied', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_actualN!.toStringAsFixed(2)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per 1000 sq ft', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${(_productLbs! / (double.tryParse(_areaController.text) ?? 5000) * 1000).toStringAsFixed(1)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildNpkGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildNpkGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('NPK GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'N (Nitrogen)', 'Leaf/blade growth, green color'),
        _buildTableRow(colors, 'P (Phosphorus)', 'Root development, flowering'),
        _buildTableRow(colors, 'K (Potassium)', 'Disease resistance, stress'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildTableRow(colors, '24-0-10', 'Lawn maintenance'),
        _buildTableRow(colors, '10-10-10', 'Balanced/starter'),
        _buildTableRow(colors, '0-0-50', 'Winterizer potash'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
