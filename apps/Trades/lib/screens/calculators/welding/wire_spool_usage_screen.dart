import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wire Spool Usage Calculator - Estimate wire consumption
class WireSpoolUsageScreen extends ConsumerStatefulWidget {
  const WireSpoolUsageScreen({super.key});
  @override
  ConsumerState<WireSpoolUsageScreen> createState() => _WireSpoolUsageScreenState();
}

class _WireSpoolUsageScreenState extends ConsumerState<WireSpoolUsageScreen> {
  final _weldLengthController = TextEditingController();
  final _legSizeController = TextEditingController(text: '0.25');
  final _spoolSizeController = TextEditingController(text: '33');
  String _wireSize = '0.035';

  double? _lbsNeeded;
  double? _spoolsNeeded;
  double? _feetOfWire;

  // Wire weight per foot (lbs/ft)
  static const Map<String, double> _wireWeightPerFt = {
    '0.023': 0.00040,
    '0.030': 0.00068,
    '0.035': 0.00093,
    '0.045': 0.00153,
    '0.052': 0.00205,
    '1/16': 0.00295,
  };

  void _calculate() {
    final length = double.tryParse(_weldLengthController.text);
    final leg = double.tryParse(_legSizeController.text);
    final spoolSize = double.tryParse(_spoolSizeController.text) ?? 33;

    if (length == null || leg == null || leg <= 0) {
      setState(() { _lbsNeeded = null; });
      return;
    }

    // Fillet weld metal volume
    final areaPerFoot = (leg * leg / 2) * 12;
    final totalVolume = areaPerFoot * length;
    final weldMetalWeight = totalVolume * 0.284; // Steel density

    // MIG typically 95-98% deposition efficiency
    final lbsNeeded = weldMetalWeight / 0.95;

    final weightPerFt = _wireWeightPerFt[_wireSize] ?? 0.00093;
    final feetOfWire = lbsNeeded / weightPerFt;
    final spoolsNeeded = lbsNeeded / spoolSize;

    setState(() {
      _lbsNeeded = lbsNeeded;
      _spoolsNeeded = spoolsNeeded;
      _feetOfWire = feetOfWire;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldLengthController.clear();
    _legSizeController.text = '0.25';
    _spoolSizeController.text = '33';
    setState(() { _lbsNeeded = null; });
  }

  @override
  void dispose() {
    _weldLengthController.dispose();
    _legSizeController.dispose();
    _spoolSizeController.dispose();
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
        title: Text('Wire Spool Usage', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSizeSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Weld Length', unit: 'ft', hint: 'Total linear feet', controller: _weldLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Fillet Leg Size', unit: 'in', hint: 'e.g. 0.25', controller: _legSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Spool Size', unit: 'lbs', hint: '33 lb typical', controller: _spoolSizeController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lbsNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _wireWeightPerFt.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _wireSize == size,
        onSelected: (_) => setState(() { _wireSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('MIG/FCAW Wire Consumption', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Based on 95% deposition efficiency', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Wire Needed', '${_lbsNeeded!.toStringAsFixed(1)} lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Wire Length', '${_feetOfWire!.toStringAsFixed(0)} ft'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Spools Needed', _spoolsNeeded!.toStringAsFixed(2)),
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
