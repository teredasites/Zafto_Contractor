import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pond Liner Calculator - Liner size and underlayment
class PondLinerScreen extends ConsumerStatefulWidget {
  const PondLinerScreen({super.key});
  @override
  ConsumerState<PondLinerScreen> createState() => _PondLinerScreenState();
}

class _PondLinerScreenState extends ConsumerState<PondLinerScreen> {
  final _lengthController = TextEditingController(text: '10');
  final _widthController = TextEditingController(text: '8');
  final _depthController = TextEditingController(text: '2');

  double? _linerLength;
  double? _linerWidth;
  double? _linerSqFt;
  double? _gallons;
  double? _underlaymentSqFt;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 10;
    final width = double.tryParse(_widthController.text) ?? 8;
    final depth = double.tryParse(_depthController.text) ?? 2;

    // Liner formula: dimension + (2 × depth) + 2' overlap
    final linerLength = length + (2 * depth) + 2;
    final linerWidth = width + (2 * depth) + 2;
    final linerSqFt = linerLength * linerWidth;

    // Water volume (gallons)
    // Rough estimate assuming irregular shape factor of 0.8
    final cubicFeet = length * width * depth * 0.8;
    final gallons = cubicFeet * 7.48;

    // Underlayment matches liner size
    final underlaymentSqFt = linerSqFt;

    setState(() {
      _linerLength = linerLength;
      _linerWidth = linerWidth;
      _linerSqFt = linerSqFt;
      _gallons = gallons;
      _underlaymentSqFt = underlaymentSqFt;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '10'; _widthController.text = '8'; _depthController.text = '2'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Pond Liner', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Pond Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Pond Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max Depth', unit: 'ft', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Formula: Liner = Dimension + (2 × Depth) + 2\' overlap', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_linerLength != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LINER SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_linerLength!.toStringAsFixed(0)}' × ${_linerWidth!.toStringAsFixed(0)}'", style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Liner area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linerSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Underlayment', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_underlaymentSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gallons!.toStringAsFixed(0)} gal', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPondGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildPondGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('POND LINER TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'EPDM (45 mil)', 'Most common, 20+ yrs'),
        _buildTableRow(colors, 'EPDM (60 mil)', 'Heavy duty, rocks'),
        _buildTableRow(colors, 'PVC', 'Cheaper, 10-15 yrs'),
        _buildTableRow(colors, 'RPE', 'Lightweight, puncture resistant'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildTableRow(colors, 'Underlayment', 'Always use under liner'),
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
