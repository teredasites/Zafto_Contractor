import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Turf Conversion Calculator - Area unit conversions
class TurfConversionScreen extends ConsumerStatefulWidget {
  const TurfConversionScreen({super.key});
  @override
  ConsumerState<TurfConversionScreen> createState() => _TurfConversionScreenState();
}

class _TurfConversionScreenState extends ConsumerState<TurfConversionScreen> {
  final _valueController = TextEditingController(text: '1');

  String _fromUnit = 'acre';

  double? _sqFt;
  double? _sqYd;
  double? _acre;
  double? _sqMeter;
  double? _hectare;

  @override
  void dispose() { _valueController.dispose(); super.dispose(); }

  void _calculate() {
    final value = double.tryParse(_valueController.text) ?? 1;

    // Convert to square feet first
    double sqFt;
    switch (_fromUnit) {
      case 'sqft': sqFt = value; break;
      case 'sqyd': sqFt = value * 9; break;
      case 'acre': sqFt = value * 43560; break;
      case 'sqm': sqFt = value * 10.764; break;
      case 'hectare': sqFt = value * 107639; break;
      default: sqFt = value;
    }

    // Convert to all units
    setState(() {
      _sqFt = sqFt;
      _sqYd = sqFt / 9;
      _acre = sqFt / 43560;
      _sqMeter = sqFt / 10.764;
      _hectare = sqFt / 107639;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _valueController.text = '1'; setState(() { _fromUnit = 'acre'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Turf Conversion', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'CONVERT FROM', ['sqft', 'sqyd', 'acre', 'sqm', 'hectare'], _fromUnit, {'sqft': 'Sq Ft', 'sqyd': 'Sq Yd', 'acre': 'Acre', 'sqm': 'Sq M', 'hectare': 'Hectare'}, (v) { setState(() => _fromUnit = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Value', unit: '', controller: _valueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_sqFt != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CONVERSIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildResultRow(colors, 'Square feet', _formatNumber(_sqFt!)),
                _buildResultRow(colors, 'Square yards', _formatNumber(_sqYd!)),
                _buildResultRow(colors, 'Acres', _acre! < 0.01 ? _acre!.toStringAsExponential(2) : _acre!.toStringAsFixed(4)),
                _buildResultRow(colors, 'Square meters', _formatNumber(_sqMeter!)),
                _buildResultRow(colors, 'Hectares', _hectare! < 0.01 ? _hectare!.toStringAsExponential(2) : _hectare!.toStringAsFixed(4)),
              ]),
            ),
            const SizedBox(height: 20),
            _buildReferenceTable(colors),
          ]),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}K';
    return value.toStringAsFixed(2);
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ]),
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

  Widget _buildReferenceTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('QUICK REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1 acre', '43,560 sq ft'),
        _buildTableRow(colors, '1 acre', '4,840 sq yd'),
        _buildTableRow(colors, '1 hectare', '2.47 acres'),
        _buildTableRow(colors, '1 sq meter', '10.76 sq ft'),
        _buildTableRow(colors, '1 sq yard', '9 sq ft'),
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
