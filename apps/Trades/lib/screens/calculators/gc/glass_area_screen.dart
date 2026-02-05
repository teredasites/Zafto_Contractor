import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Glass Area Calculator - Window/door glass calculations
class GlassAreaScreen extends ConsumerStatefulWidget {
  const GlassAreaScreen({super.key});
  @override
  ConsumerState<GlassAreaScreen> createState() => _GlassAreaScreenState();
}

class _GlassAreaScreenState extends ConsumerState<GlassAreaScreen> {
  final _widthController = TextEditingController(text: '36');
  final _heightController = TextEditingController(text: '48');
  final _qtyController = TextEditingController(text: '8');

  String _glassType = 'double';

  double? _unitArea;
  double? _totalArea;
  double? _weightEstimate;

  @override
  void dispose() { _widthController.dispose(); _heightController.dispose(); _qtyController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text);
    final height = double.tryParse(_heightController.text);
    final qty = int.tryParse(_qtyController.text) ?? 1;

    if (width == null || height == null) {
      setState(() { _unitArea = null; _totalArea = null; _weightEstimate = null; });
      return;
    }

    // Convert to square feet
    final unitAreaSqIn = width * height;
    final unitAreaSqFt = unitAreaSqIn / 144;
    final totalArea = unitAreaSqFt * qty;

    // Weight estimate (lbs per sq ft)
    // Single pane: ~1.6 lbs/sqft, Double: ~3.3, Triple: ~5, Tempered: ~2
    double lbsPerSqFt;
    switch (_glassType) {
      case 'single': lbsPerSqFt = 1.6; break;
      case 'double': lbsPerSqFt = 3.3; break;
      case 'triple': lbsPerSqFt = 5.0; break;
      case 'tempered': lbsPerSqFt = 2.0; break;
      default: lbsPerSqFt = 3.3;
    }

    final weightEstimate = totalArea * lbsPerSqFt;

    setState(() { _unitArea = unitAreaSqFt; _totalArea = totalArea; _weightEstimate = weightEstimate; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '36'; _heightController.text = '48'; _qtyController.text = '8'; setState(() => _glassType = 'double'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Glass Area', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Quantity', unit: 'panes', controller: _qtyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_totalArea != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL GLASS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalArea!.toStringAsFixed(1)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per Unit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_unitArea!.toStringAsFixed(2)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. Weight', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_weightEstimate!.toStringAsFixed(0)} lbs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Tempered glass required within 24\" of doors, near tubs/showers, and at floor level.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildGlassTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['single', 'double', 'triple', 'tempered'];
    final labels = {'single': 'Single', 'double': 'Double', 'triple': 'Triple', 'tempered': 'Tempered'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('GLASS TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _glassType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _glassType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildGlassTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GLASS WEIGHTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Single Pane', '~1.6 lbs/sq ft'),
        _buildTableRow(colors, 'Double Pane (IGU)', '~3.3 lbs/sq ft'),
        _buildTableRow(colors, 'Triple Pane', '~5.0 lbs/sq ft'),
        _buildTableRow(colors, 'Tempered', '~2.0 lbs/sq ft'),
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
