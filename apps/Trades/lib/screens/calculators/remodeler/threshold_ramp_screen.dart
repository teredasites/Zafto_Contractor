import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Threshold Ramp Calculator - Door threshold transition ramp sizing
class ThresholdRampScreen extends ConsumerStatefulWidget {
  const ThresholdRampScreen({super.key});
  @override
  ConsumerState<ThresholdRampScreen> createState() => _ThresholdRampScreenState();
}

class _ThresholdRampScreenState extends ConsumerState<ThresholdRampScreen> {
  final _heightController = TextEditingController(text: '1');
  final _doorWidthController = TextEditingController(text: '36');

  String _material = 'rubber';
  String _use = 'wheelchair';

  double? _rampLength;
  double? _slopePercent;
  String? _recommendation;
  String? _materialNote;

  @override
  void dispose() { _heightController.dispose(); _doorWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final height = double.tryParse(_heightController.text) ?? 1; // inches
    final doorWidth = double.tryParse(_doorWidthController.text) ?? 36; // inches

    // Slope requirements vary by use
    double slopeRatio;
    switch (_use) {
      case 'wheelchair':
        slopeRatio = 12; // ADA 1:12
        break;
      case 'walker':
        slopeRatio = 8; // Can be steeper
        break;
      case 'scooter':
        slopeRatio = 10; // Moderate
        break;
      case 'rolling':
        slopeRatio = 6; // Cart/dolly can handle steeper
        break;
      default:
        slopeRatio = 12;
    }

    final rampLength = height * slopeRatio; // inches
    final slopePercent = (1 / slopeRatio) * 100;

    // Recommendation based on height
    String recommendation;
    if (height <= 0.5) {
      recommendation = 'Beveled threshold may suffice. Rubber ramp or threshold reducer.';
    } else if (height <= 1) {
      recommendation = 'Rubber or aluminum modular ramp. No permit typically required.';
    } else if (height <= 2) {
      recommendation = 'Aluminum modular ramp or custom wood ramp. Consider folding options.';
    } else {
      recommendation = 'Custom ramp needed. Consider permanent installation or portable folding ramp.';
    }

    // Material notes
    String materialNote;
    switch (_material) {
      case 'rubber':
        materialNote = 'Rubber: Flexible, grips well, good for indoor/outdoor. Weight capacity varies.';
        break;
      case 'aluminum':
        materialNote = 'Aluminum: Lightweight, high capacity (600-800 lbs), weather resistant.';
        break;
      case 'wood':
        materialNote = 'Wood: Custom fit, can match decor, requires sealing for outdoor use.';
        break;
      case 'composite':
        materialNote = 'Composite: Durable, low maintenance, non-slip surface. Higher cost.';
        break;
      default:
        materialNote = 'Select material based on use location and permanence.';
    }

    setState(() {
      _rampLength = rampLength;
      _slopePercent = slopePercent;
      _recommendation = recommendation;
      _materialNote = materialNote;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _heightController.text = '1'; _doorWidthController.text = '36'; setState(() { _material = 'rubber'; _use = 'wheelchair'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Threshold Ramp', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PRIMARY USE', ['wheelchair', 'walker', 'scooter', 'rolling'], _use, {'wheelchair': 'Wheelchair', 'walker': 'Walker', 'scooter': 'Scooter', 'rolling': 'Cart/Dolly'}, (v) { setState(() => _use = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['rubber', 'aluminum', 'wood', 'composite'], _material, {'rubber': 'Rubber', 'aluminum': 'Aluminum', 'wood': 'Wood', 'composite': 'Composite'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Threshold Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Door Width', unit: 'inches', controller: _doorWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_rampLength != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RAMP LENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rampLength!.toStringAsFixed(1)}"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Slope', style: TextStyle(color: colors.textTertiary, fontSize: 12)), Text('${_slopePercent!.toStringAsFixed(1)}%', style: TextStyle(color: colors.textSecondary, fontSize: 12))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_materialNote!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD THRESHOLD RAMPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1/2" rise', '6" long'),
        _buildTableRow(colors, '1" rise', '12" long'),
        _buildTableRow(colors, '2" rise', '24" long'),
        _buildTableRow(colors, '3" rise', '36" long'),
        _buildTableRow(colors, 'ADA slope', '1:12 max'),
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
