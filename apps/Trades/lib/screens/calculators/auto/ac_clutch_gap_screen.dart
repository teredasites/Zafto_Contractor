import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// A/C Clutch Air Gap Measurement Calculator
/// Measures and analyzes compressor clutch air gap
class AcClutchGapScreen extends ConsumerStatefulWidget {
  const AcClutchGapScreen({super.key});
  @override
  ConsumerState<AcClutchGapScreen> createState() => _AcClutchGapScreenState();
}

class _AcClutchGapScreenState extends ConsumerState<AcClutchGapScreen> {
  final _gap1Controller = TextEditingController();
  final _gap2Controller = TextEditingController();
  final _gap3Controller = TextEditingController();
  final _specMinController = TextEditingController(text: '0.016');
  final _specMaxController = TextEditingController(text: '0.031');

  double? _averageGap;
  double? _gapVariation;
  String? _status;
  String? _diagnosis;
  String? _action;

  void _calculate() {
    final gap1 = double.tryParse(_gap1Controller.text);
    final gap2 = double.tryParse(_gap2Controller.text);
    final gap3 = double.tryParse(_gap3Controller.text);
    final specMin = double.tryParse(_specMinController.text) ?? 0.016;
    final specMax = double.tryParse(_specMaxController.text) ?? 0.031;

    if (gap1 == null) {
      setState(() { _averageGap = null; });
      return;
    }

    // Calculate with available measurements
    List<double> gaps = [gap1];
    if (gap2 != null) gaps.add(gap2);
    if (gap3 != null) gaps.add(gap3);

    final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
    final maxGap = gaps.reduce((a, b) => a > b ? a : b);
    final minGap = gaps.reduce((a, b) => a < b ? a : b);
    final variation = maxGap - minGap;

    String status;
    String diag;
    String action;

    if (avgGap < specMin) {
      status = 'TOO SMALL';
      diag = 'Air gap below minimum specification';
      action = 'Add shims to clutch plate or replace clutch assembly';
    } else if (avgGap > specMax) {
      status = 'TOO LARGE';
      diag = 'Air gap exceeds maximum specification';
      action = 'Remove shims or replace worn clutch components';
    } else if (variation > 0.008) {
      status = 'UNEVEN';
      diag = 'Gap variation too large - indicates wear or warping';
      action = 'Inspect clutch plate for warping, check hub for wear';
    } else {
      status = 'WITHIN SPEC';
      diag = 'Air gap is within acceptable range';
      action = 'No adjustment needed';
    }

    // Additional warnings
    if (avgGap > specMax * 0.9 && status == 'WITHIN SPEC') {
      diag = 'Gap near upper limit - monitor for wear';
    }
    if (avgGap < specMin * 1.1 && status == 'WITHIN SPEC') {
      diag = 'Gap near lower limit - ensure proper clutch release';
    }

    setState(() {
      _averageGap = avgGap;
      _gapVariation = variation;
      _status = status;
      _diagnosis = diag;
      _action = action;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _gap1Controller.clear();
    _gap2Controller.clear();
    _gap3Controller.clear();
    _specMinController.text = '0.016';
    _specMaxController.text = '0.031';
    setState(() { _averageGap = null; });
  }

  @override
  void dispose() {
    _gap1Controller.dispose();
    _gap2Controller.dispose();
    _gap3Controller.dispose();
    _specMinController.dispose();
    _specMaxController.dispose();
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
        title: Text('Clutch Air Gap', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Gap Measurements (3 positions)', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Gap 1', unit: 'in', hint: '120°', controller: _gap1Controller, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: 'Gap 2', unit: 'in', hint: '240°', controller: _gap2Controller, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: 'Gap 3', unit: 'in', hint: '360°', controller: _gap3Controller, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 20),
            Text('Specification Range', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Min Spec', unit: 'in', hint: 'Minimum', controller: _specMinController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Max Spec', unit: 'in', hint: 'Maximum', controller: _specMaxController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_averageGap != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildMeasurementGuide(colors),
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
        Text('Typical Clutch Gap: 0.016" - 0.031"', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Measure at 3 points around clutch using feeler gauge', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    switch (_status) {
      case 'WITHIN SPEC':
        statusColor = colors.accentPrimary;
        break;
      case 'UNEVEN':
        statusColor = Colors.orange;
        break;
      case 'TOO SMALL':
      case 'TOO LARGE':
        statusColor = Colors.red;
        break;
      default:
        statusColor = colors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(_status!, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Average Gap', '${_averageGap!.toStringAsFixed(4)}"', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Gap Variation', '${_gapVariation!.toStringAsFixed(4)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Spec Range', '${_specMinController.text}" - ${_specMaxController.text}"'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(_diagnosis!, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_action!, style: TextStyle(color: colors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMeasurementGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Measurement Procedure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        _buildStep(colors, '1', 'Ensure A/C is off and clutch is disengaged'),
        const SizedBox(height: 8),
        _buildStep(colors, '2', 'Use feeler gauge between clutch plate and pulley'),
        const SizedBox(height: 8),
        _buildStep(colors, '3', 'Measure at 3 equally spaced points (120° apart)'),
        const SizedBox(height: 8),
        _buildStep(colors, '4', 'All measurements should be consistent'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Always verify OEM spec - values vary by manufacturer', style: TextStyle(color: Colors.orange, fontSize: 12))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStep(ZaftoColors colors, String num, String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.2), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(num, style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
    ]);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
