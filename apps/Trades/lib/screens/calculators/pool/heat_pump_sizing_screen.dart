import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Pool Heat Pump Sizing Calculator
class HeatPumpSizingScreen extends ConsumerStatefulWidget {
  const HeatPumpSizingScreen({super.key});
  @override
  ConsumerState<HeatPumpSizingScreen> createState() => _HeatPumpSizingScreenState();
}

class _HeatPumpSizingScreenState extends ConsumerState<HeatPumpSizingScreen> {
  final _surfaceAreaController = TextEditingController();
  final _tempRiseController = TextEditingController(text: '15');
  bool _hasCover = true;

  double? _btuRequired;
  String? _recommendation;
  double? _hoursToHeat;

  void _calculate() {
    final surfaceArea = double.tryParse(_surfaceAreaController.text);
    final tempRise = double.tryParse(_tempRiseController.text);

    if (surfaceArea == null || tempRise == null || surfaceArea <= 0 || tempRise <= 0) {
      setState(() { _btuRequired = null; });
      return;
    }

    // Heat pump sizing based on surface area and temp rise
    // Rule of thumb: 10 BTU per sq ft per degree F rise without cover
    // With cover: reduce by 50%
    double btuPerSqFt = _hasCover ? 5 : 10;
    final btu = surfaceArea * tempRise * btuPerSqFt;

    // Standard heat pump sizes
    String recommendation;
    double selectedBtu;
    if (btu <= 50000) {
      recommendation = '50,000 BTU heat pump';
      selectedBtu = 50000;
    } else if (btu <= 80000) {
      recommendation = '80,000 BTU heat pump';
      selectedBtu = 80000;
    } else if (btu <= 100000) {
      recommendation = '100,000 BTU heat pump';
      selectedBtu = 100000;
    } else if (btu <= 120000) {
      recommendation = '120,000 BTU heat pump';
      selectedBtu = 120000;
    } else if (btu <= 140000) {
      recommendation = '140,000 BTU heat pump';
      selectedBtu = 140000;
    } else {
      recommendation = 'Multiple units or commercial grade';
      selectedBtu = 140000;
    }

    // Estimate hours to heat (very rough)
    // Assume 1 hour per degree for average residential pool with proper sizing
    final hours = tempRise * (btu / selectedBtu);

    setState(() {
      _btuRequired = btu;
      _recommendation = recommendation;
      _hoursToHeat = hours;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _surfaceAreaController.clear();
    _tempRiseController.text = '15';
    setState(() { _btuRequired = null; });
  }

  @override
  void dispose() {
    _surfaceAreaController.dispose();
    _tempRiseController.dispose();
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
        title: Text('Heat Pump Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Surface Area', unit: 'sq ft', hint: 'L × W for rectangular', controller: _surfaceAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Temp Rise Needed', unit: 'F', hint: 'Desired increase', controller: _tempRiseController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            _buildCoverToggle(colors),
            const SizedBox(height: 32),
            if (_btuRequired != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildCoverToggle(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('With Cover'), selected: _hasCover, onSelected: (_) => setState(() { _hasCover = true; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('No Cover'), selected: !_hasCover, onSelected: (_) => setState(() { _hasCover = false; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('BTU = Area × Temp Rise × Factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 14)),
        const SizedBox(height: 8),
        Text('Heat pumps are 5-6x more efficient than gas', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'BTU Required', '${(_btuRequired! / 1000).toStringAsFixed(0)}K BTU', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Est. Heat Time', '${_hoursToHeat!.toStringAsFixed(0)} hrs'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        Text('Heat pumps work best when air temp > 50F', style: TextStyle(color: colors.textTertiary, fontSize: 12)),
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
