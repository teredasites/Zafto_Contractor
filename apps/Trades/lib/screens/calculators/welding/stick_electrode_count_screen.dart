import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stick Electrode Count Calculator - Number of electrodes needed
class StickElectrodeCountScreen extends ConsumerStatefulWidget {
  const StickElectrodeCountScreen({super.key});
  @override
  ConsumerState<StickElectrodeCountScreen> createState() => _StickElectrodeCountScreenState();
}

class _StickElectrodeCountScreenState extends ConsumerState<StickElectrodeCountScreen> {
  final _weldLengthController = TextEditingController();
  final _legSizeController = TextEditingController(text: '0.25');
  final _stubLengthController = TextEditingController(text: '2');
  String _electrodeSize = '1/8';

  int? _electrodesNeeded;
  double? _lbsRequired;
  double? _packagesNeeded;

  // Electrode weights in lbs per 14" rod
  static const Map<String, double> _rodWeights = {
    '3/32': 0.062,
    '1/8': 0.10,
    '5/32': 0.14,
    '3/16': 0.19,
    '7/32': 0.25,
    '1/4': 0.32,
  };

  // Deposition efficiency (usable portion)
  static const Map<String, double> _depositionEff = {
    '3/32': 0.60,
    '1/8': 0.62,
    '5/32': 0.63,
    '3/16': 0.64,
    '7/32': 0.65,
    '1/4': 0.65,
  };

  void _calculate() {
    final length = double.tryParse(_weldLengthController.text);
    final leg = double.tryParse(_legSizeController.text);
    final stubLength = double.tryParse(_stubLengthController.text) ?? 2;

    if (length == null || leg == null || leg <= 0) {
      setState(() { _electrodesNeeded = null; });
      return;
    }

    // Calculate weld metal volume (cubic inches per foot for fillet)
    final areaPerFoot = (leg * leg / 2) * 12; // triangular cross-section
    final totalVolume = areaPerFoot * length;

    // Steel density ~0.284 lbs/cu in
    final weldMetalWeight = totalVolume * 0.284;

    final rodWeight = _rodWeights[_electrodeSize] ?? 0.10;
    final efficiency = _depositionEff[_electrodeSize] ?? 0.62;

    // Adjust for stub loss (2" stub on 14" rod = 14.3% loss)
    final stubLossFactor = 1 - (stubLength / 14);
    final usablePerRod = rodWeight * efficiency * stubLossFactor;

    final electrodes = (weldMetalWeight / usablePerRod).ceil();
    final lbs = electrodes * rodWeight;
    final packages = lbs / 10; // Typical 10 lb package

    setState(() {
      _electrodesNeeded = electrodes;
      _lbsRequired = lbs;
      _packagesNeeded = packages;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _weldLengthController.clear();
    _legSizeController.text = '0.25';
    _stubLengthController.text = '2';
    setState(() { _electrodesNeeded = null; });
  }

  @override
  void dispose() {
    _weldLengthController.dispose();
    _legSizeController.dispose();
    _stubLengthController.dispose();
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
        title: Text('Electrode Count', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
            ZaftoInputField(label: 'Stub Length', unit: 'in', hint: 'Typical 2"', controller: _stubLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_electrodesNeeded != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSizeSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _rodWeights.keys.map((size) => ChoiceChip(
        label: Text(size),
        selected: _electrodeSize == size,
        onSelected: (_) => setState(() { _electrodeSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Stick Electrode Count', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Accounts for deposition efficiency and stub loss', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Electrodes Needed', '$_electrodesNeeded rods', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Total Weight', '${_lbsRequired!.toStringAsFixed(1)} lbs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, '10 lb Packages', '${_packagesNeeded!.toStringAsFixed(1)}'),
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
