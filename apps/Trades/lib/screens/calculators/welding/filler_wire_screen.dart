import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Filler Wire Calculator - Wire weight for MIG/TIG
class FillerWireScreen extends ConsumerStatefulWidget {
  const FillerWireScreen({super.key});
  @override
  ConsumerState<FillerWireScreen> createState() => _FillerWireScreenState();
}

class _FillerWireScreenState extends ConsumerState<FillerWireScreen> {
  final _weldLengthController = TextEditingController();
  final _legSizeController = TextEditingController(text: '0.25');
  String _wireDiameter = '0.035';

  double? _lbsRequired;
  double? _feetOfWire;

  // Lbs per foot of wire by diameter
  static const Map<String, double> _wireWeights = {
    '0.023': 0.00018,
    '0.030': 0.00030,
    '0.035': 0.00042,
    '0.045': 0.00068,
  };

  void _calculate() {
    final length = double.tryParse(_weldLengthController.text);
    final leg = double.tryParse(_legSizeController.text);

    if (length == null || leg == null || leg <= 0) {
      setState(() { _lbsRequired = null; });
      return;
    }

    // Cross-sectional area of fillet weld (triangle)
    final weldArea = 0.5 * leg * leg;
    // Volume per foot of weld (sq in × 12 in = cubic inches)
    final volumePerFoot = weldArea * 12;
    // Steel density ~0.284 lbs/cu in
    final lbsPerFoot = volumePerFoot * 0.284;
    final totalLbs = length * lbsPerFoot * 1.10; // 10% waste

    final wireWeight = _wireWeights[_wireDiameter] ?? 0.00042;
    final feetWire = totalLbs / wireWeight;

    setState(() {
      _lbsRequired = totalLbs;
      _feetOfWire = feetWire;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldLengthController.clear();
    _legSizeController.text = '0.25';
    setState(() { _lbsRequired = null; });
  }

  @override
  void dispose() {
    _weldLengthController.dispose();
    _legSizeController.dispose();
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
        title: Text('Filler Wire', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildWireSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Length', unit: 'ft', hint: 'Total linear feet', controller: _weldLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fillet Leg Size', unit: 'in', hint: 'e.g. 0.25', controller: _legSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lbsRequired != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildWireSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      children: _wireWeights.keys.map((size) => ChoiceChip(
        label: Text('$size"'),
        selected: _wireDiameter == size,
        onSelected: (_) => setState(() { _wireDiameter = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('MIG/TIG Wire Estimator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Based on weld cross-section and steel density', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Wire Weight', '${_lbsRequired!.toStringAsFixed(2)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Wire Length', '${_feetOfWire!.toStringAsFixed(0)} ft'),
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
