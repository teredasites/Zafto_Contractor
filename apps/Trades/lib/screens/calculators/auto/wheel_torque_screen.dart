import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wheel Torque Calculator - Lug nut torque specifications
class WheelTorqueScreen extends ConsumerStatefulWidget {
  const WheelTorqueScreen({super.key});
  @override
  ConsumerState<WheelTorqueScreen> createState() => _WheelTorqueScreenState();
}

class _WheelTorqueScreenState extends ConsumerState<WheelTorqueScreen> {
  String _selectedVehicle = 'car_alloy';

  final Map<String, Map<String, dynamic>> _torqueSpecs = {
    'car_alloy': {
      'name': 'Car - Alloy Wheels',
      'torque': '80-100 ft-lbs',
      'nm': '108-135 Nm',
      'typical': 90,
    },
    'car_steel': {
      'name': 'Car - Steel Wheels',
      'torque': '75-95 ft-lbs',
      'nm': '100-130 Nm',
      'typical': 85,
    },
    'truck_half': {
      'name': 'Light Truck (1/2 ton)',
      'torque': '100-140 ft-lbs',
      'nm': '135-190 Nm',
      'typical': 120,
    },
    'truck_hd': {
      'name': 'Heavy Duty Truck',
      'torque': '120-165 ft-lbs',
      'nm': '165-225 Nm',
      'typical': 140,
    },
    'suv': {
      'name': 'SUV / Crossover',
      'torque': '85-120 ft-lbs',
      'nm': '115-165 Nm',
      'typical': 100,
    },
  };

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wheel Torque', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildVehicleSelector(colors),
            const SizedBox(height: 24),
            _buildTorqueCard(colors),
            const SizedBox(height: 24),
            _buildProcedureCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VEHICLE TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        ..._torqueSpecs.keys.map((key) => _buildVehicleOption(colors, key)),
      ]),
    );
  }

  Widget _buildVehicleOption(ZaftoColors colors, String key) {
    final isSelected = _selectedVehicle == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedVehicle = key; });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? colors.accentPrimary : Colors.transparent,
              border: Border.all(color: isSelected ? colors.accentPrimary : colors.textTertiary, width: 2),
            ),
            child: isSelected ? Icon(LucideIcons.check, size: 12, color: colors.bgBase) : null,
          ),
          const SizedBox(width: 12),
          Text(_torqueSpecs[key]!['name'], style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textPrimary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildTorqueCard(ZaftoColors colors) {
    final spec = _torqueSpecs[_selectedVehicle]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('TORQUE SPECIFICATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${spec['typical']} ft-lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Range: ${spec['torque']}', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text('(${spec['nm']})', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text('Always verify with vehicle-specific specification. Over-torquing can damage studs and rotors.', style: TextStyle(color: colors.warning, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildProcedureCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PROPER PROCEDURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('1. Hand-start all lug nuts', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('2. Snug in star pattern', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('3. Torque in star pattern (3 passes)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('4. Re-torque after 50-100 miles', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Text('Tips:', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text('• Clean threads before install', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Do NOT use anti-seize on lugs', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Use calibrated torque wrench', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
