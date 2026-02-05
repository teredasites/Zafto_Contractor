import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wheel Lug Nut Torque Calculator
class WheelTorqueSpecScreen extends ConsumerStatefulWidget {
  const WheelTorqueSpecScreen({super.key});
  @override
  ConsumerState<WheelTorqueSpecScreen> createState() => _WheelTorqueSpecScreenState();
}

class _WheelTorqueSpecScreenState extends ConsumerState<WheelTorqueSpecScreen> {
  String _vehicleType = 'Passenger Car';
  String _lugSize = '12mm';
  String _wheelType = 'Steel';

  int? _torqueSpec;
  String? _recommendation;

  // Base torque specs by lug size (ft-lbs)
  static const Map<String, Map<String, int>> _torqueSpecs = {
    '10mm': {'Steel': 65, 'Alloy': 70},
    '12mm': {'Steel': 75, 'Alloy': 80},
    '14mm': {'Steel': 95, 'Alloy': 100},
    '7/16"': {'Steel': 70, 'Alloy': 75},
    '1/2"': {'Steel': 85, 'Alloy': 90},
    '9/16"': {'Steel': 110, 'Alloy': 115},
  };

  void _calculate() {
    final baseTorque = _torqueSpecs[_lugSize]?[_wheelType] ?? 80;

    // Adjust for vehicle type
    int adjustment = 0;
    if (_vehicleType == 'Truck/SUV') {
      adjustment = 15;
    } else if (_vehicleType == 'Heavy Duty') {
      adjustment = 30;
    }

    final torqueSpec = baseTorque + adjustment;

    String recommendation;
    if (_wheelType == 'Alloy') {
      recommendation = 'Alloy wheels: Re-torque after 50-100 miles';
    } else {
      recommendation = 'Use star pattern when tightening lugs';
    }

    setState(() {
      _torqueSpec = torqueSpec;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _vehicleType = 'Passenger Car';
    _lugSize = '12mm';
    _wheelType = 'Steel';
    setState(() { _torqueSpec = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wheel Torque Spec', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('VEHICLE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildVehicleSelector(colors),
            const SizedBox(height: 16),
            Text('LUG SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildLugSelector(colors),
            const SizedBox(height: 16),
            Text('WHEEL TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            _buildWheelSelector(colors),
            const SizedBox(height: 32),
            if (_torqueSpec != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['Passenger Car', 'Truck/SUV', 'Heavy Duty'].map((type) => ChoiceChip(
        label: Text(type, style: const TextStyle(fontSize: 11)),
        selected: _vehicleType == type,
        onSelected: (_) => setState(() { _vehicleType = type; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildLugSelector(ZaftoColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _torqueSpecs.keys.map((size) => ChoiceChip(
        label: Text(size, style: const TextStyle(fontSize: 11)),
        selected: _lugSize == size,
        onSelected: (_) => setState(() { _lugSize = size; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildWheelSelector(ZaftoColors colors) {
    return Row(children: [
      ChoiceChip(label: const Text('Steel'), selected: _wheelType == 'Steel', onSelected: (_) => setState(() { _wheelType = 'Steel'; _calculate(); })),
      const SizedBox(width: 8),
      ChoiceChip(label: const Text('Alloy'), selected: _wheelType == 'Alloy', onSelected: (_) => setState(() { _wheelType = 'Alloy'; _calculate(); })),
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Torque = Base + Vehicle Adjustment', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Always verify with manufacturer spec', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Torque Spec', '$_torqueSpec ft-lbs', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Nm', '${(_torqueSpec! * 1.356).toStringAsFixed(0)} Nm'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
