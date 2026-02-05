import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Scale Drawing Calculator - Plan to actual measurements
class ScaleDrawingScreen extends ConsumerStatefulWidget {
  const ScaleDrawingScreen({super.key});
  @override
  ConsumerState<ScaleDrawingScreen> createState() => _ScaleDrawingScreenState();
}

class _ScaleDrawingScreenState extends ConsumerState<ScaleDrawingScreen> {
  final _planMeasureController = TextEditingController(text: '2.5');
  final _scaleController = TextEditingController(text: '20');

  String _scaleType = 'custom';
  String _planUnit = 'inches';

  double? _actualFeet;
  double? _actualInches;

  @override
  void dispose() { _planMeasureController.dispose(); _scaleController.dispose(); super.dispose(); }

  void _calculate() {
    final planMeasure = double.tryParse(_planMeasureController.text) ?? 2.5;
    double scale;

    switch (_scaleType) {
      case '1_10':
        scale = 10;
        break;
      case '1_20':
        scale = 20;
        break;
      case '1_30':
        scale = 30;
        break;
      case '1_50':
        scale = 50;
        break;
      case 'custom':
        scale = double.tryParse(_scaleController.text) ?? 20;
        break;
      default:
        scale = 20;
    }

    double actualFeet;
    if (_planUnit == 'inches') {
      actualFeet = planMeasure * scale / 12;
    } else {
      actualFeet = planMeasure * scale;
    }

    setState(() {
      _actualFeet = actualFeet;
      _actualInches = actualFeet * 12;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _planMeasureController.text = '2.5'; _scaleController.text = '20'; setState(() { _scaleType = 'custom'; _planUnit = 'inches'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Scale Drawing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'COMMON SCALES', ['1_10', '1_20', '1_30', '1_50', 'custom'], _scaleType, {'1_10': '1"=10\'', '1_20': '1"=20\'', '1_30': '1"=30\'', '1_50': '1"=50\'', 'custom': 'Custom'}, (v) { setState(() => _scaleType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'PLAN UNIT', ['inches', 'feet'], _planUnit, {'inches': 'Inches', 'feet': 'Feet'}, (v) { setState(() => _planUnit = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Plan Measurement', unit: _planUnit == 'inches' ? 'in' : 'ft', controller: _planMeasureController, onChanged: (_) => _calculate())),
              if (_scaleType == 'custom') ...[
                const SizedBox(width: 12),
                Expanded(child: ZaftoInputField(label: 'Scale (1" = X ft)', unit: 'ft', controller: _scaleController, onChanged: (_) => _calculate())),
              ],
            ]),
            const SizedBox(height: 32),
            if (_actualFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ACTUAL SIZE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_actualFeet!.toStringAsFixed(1)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('In Inches', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_actualInches!.toStringAsFixed(0)}"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Using scale: 1" = ${_scaleType == 'custom' ? _scaleController.text : _scaleType.replaceAll('1_', '')} feet', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildScaleTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: options.map((o) {
        final isSelected = selected == o;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildScaleTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON LANDSCAPE SCALES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1" = 10\'', 'Residential detail'),
        _buildTableRow(colors, '1" = 20\'', 'Small residential'),
        _buildTableRow(colors, '1" = 30\'', 'Medium residential'),
        _buildTableRow(colors, '1" = 40\'', 'Large residential'),
        _buildTableRow(colors, '1" = 50\'', 'Commercial'),
        _buildTableRow(colors, '1" = 100\'', 'Site overview'),
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
