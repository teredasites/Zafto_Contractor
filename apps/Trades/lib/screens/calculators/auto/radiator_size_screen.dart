import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Radiator Size Calculator - BTU dissipation based on HP
class RadiatorSizeScreen extends ConsumerStatefulWidget {
  const RadiatorSizeScreen({super.key});
  @override
  ConsumerState<RadiatorSizeScreen> createState() => _RadiatorSizeScreenState();
}

class _RadiatorSizeScreenState extends ConsumerState<RadiatorSizeScreen> {
  final _hpController = TextEditingController();
  final _efficiencyController = TextEditingController(text: '30');
  final _ambientTempController = TextEditingController(text: '100');

  double? _btuRequired;
  double? _minRadiatorSize;
  double? _recommendedSize;
  String? _radiatorType;

  void _calculate() {
    final hp = double.tryParse(_hpController.text);
    final efficiency = double.tryParse(_efficiencyController.text);
    final ambient = double.tryParse(_ambientTempController.text);

    if (hp == null || efficiency == null || ambient == null) {
      setState(() { _btuRequired = null; });
      return;
    }

    // Heat rejection = HP * 2545 BTU/hr * (1 - thermal efficiency)
    // Typical engine efficiency is 25-35%
    final wasteHeatPercent = (100 - efficiency) / 100;
    final totalBtu = hp * 2545 * wasteHeatPercent;

    // About 1/3 of waste heat goes to cooling system
    final coolingBtu = totalBtu * 0.33;

    // Radiator sizing: ~150-200 BTU/hr per sq inch at highway speeds
    // Use 150 for conservative estimate
    final minSize = coolingBtu / 150;
    final recSize = coolingBtu / 120; // Add 25% safety margin

    // Determine radiator type
    String type;
    if (hp <= 200) {
      type = 'Single-row aluminum or 2-row copper/brass';
    } else if (hp <= 400) {
      type = 'Dual-row aluminum or 3-row copper/brass';
    } else if (hp <= 600) {
      type = 'Triple-row aluminum with dual fans';
    } else {
      type = 'Quad-row aluminum or custom dual-pass';
    }

    setState(() {
      _btuRequired = coolingBtu;
      _minRadiatorSize = minSize;
      _recommendedSize = recSize;
      _radiatorType = type;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _hpController.clear();
    _efficiencyController.text = '30';
    _ambientTempController.text = '100';
    setState(() { _btuRequired = null; });
  }

  @override
  void dispose() {
    _hpController.dispose();
    _efficiencyController.dispose();
    _ambientTempController.dispose();
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
        title: Text('Radiator Size', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Horsepower', unit: 'HP', hint: 'Peak horsepower', controller: _hpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Thermal Efficiency', unit: '%', hint: '25-35% typical', controller: _efficiencyController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Max Ambient Temp', unit: 'F', hint: 'Hottest conditions', controller: _ambientTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_btuRequired != null) _buildResultsCard(colors),
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
        Text('BTU = HP x 2545 x Waste Heat x 0.33', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Cooling system handles ~33% of engine waste heat', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Heat to Dissipate', '${(_btuRequired! / 1000).toStringAsFixed(1)}k BTU/hr', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Min Radiator Area', '${_minRadiatorSize!.toStringAsFixed(0)} sq in'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Recommended Area', '${_recommendedSize!.toStringAsFixed(0)} sq in'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(LucideIcons.info, color: colors.accentPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_radiatorType!, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
          ]),
        ),
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
