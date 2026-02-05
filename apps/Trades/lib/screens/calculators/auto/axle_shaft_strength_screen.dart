import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Axle Shaft Torque Capacity Calculator
class AxleShaftStrengthScreen extends ConsumerStatefulWidget {
  const AxleShaftStrengthScreen({super.key});
  @override
  ConsumerState<AxleShaftStrengthScreen> createState() => _AxleShaftStrengthScreenState();
}

class _AxleShaftStrengthScreenState extends ConsumerState<AxleShaftStrengthScreen> {
  final _diameterController = TextEditingController();
  final _engineTorqueController = TextEditingController();
  final _gearRatioController = TextEditingController();
  final _finalDriveController = TextEditingController();
  String _material = 'chrome_moly';

  double? _shaftCapacity;
  double? _wheelTorque;
  double? _safetyFactor;
  String? _status;

  void _calculate() {
    final diameter = double.tryParse(_diameterController.text);
    final engineTorque = double.tryParse(_engineTorqueController.text);
    final gearRatio = double.tryParse(_gearRatioController.text);
    final finalDrive = double.tryParse(_finalDriveController.text);

    if (diameter == null) {
      setState(() { _shaftCapacity = null; });
      return;
    }

    // Material shear strength (psi) - typical values
    double shearStrength;
    switch (_material) {
      case '1040_steel':
        shearStrength = 32000; // 1040 steel
        break;
      case '4340_steel':
        shearStrength = 63000; // 4340 alloy steel
        break;
      case 'chrome_moly':
        shearStrength = 75000; // Chrome-moly
        break;
      case '300m':
        shearStrength = 95000; // 300M high-strength
        break;
      default:
        shearStrength = 75000;
    }

    // Torsional capacity: T = (pi * d^3 * shear_strength) / 16
    // Diameter in inches, result in lb-ft
    final radiusCubed = math.pow(diameter / 2, 3);
    final capacity = (math.pi * math.pow(diameter, 3) * shearStrength) / 16 / 12; // Convert lb-in to lb-ft

    double? wheelTorqueCalc;
    double? safety;
    String statusMsg;

    if (engineTorque != null && gearRatio != null && finalDrive != null) {
      // Calculate wheel torque (per axle = total / 2 for open diff)
      wheelTorqueCalc = (engineTorque * gearRatio * finalDrive) / 2;
      safety = capacity / wheelTorqueCalc;

      if (safety >= 2.5) {
        statusMsg = 'Excellent - Good for high-performance use';
      } else if (safety >= 1.8) {
        statusMsg = 'Good - Adequate for street/strip';
      } else if (safety >= 1.3) {
        statusMsg = 'Marginal - May break under hard launches';
      } else {
        statusMsg = 'Insufficient - Upgrade recommended';
      }
    } else {
      statusMsg = 'Enter powertrain data for safety factor';
    }

    setState(() {
      _shaftCapacity = capacity;
      _wheelTorque = wheelTorqueCalc;
      _safetyFactor = safety;
      _status = statusMsg;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _diameterController.clear();
    _engineTorqueController.clear();
    _gearRatioController.clear();
    _finalDriveController.clear();
    setState(() { _shaftCapacity = null; _material = 'chrome_moly'; });
  }

  @override
  void dispose() {
    _diameterController.dispose();
    _engineTorqueController.dispose();
    _gearRatioController.dispose();
    _finalDriveController.dispose();
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
        title: Text('Axle Shaft Strength', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildMaterialSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Shaft Diameter', unit: 'in', hint: 'Minimum cross-section', controller: _diameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 24),
            Text('POWERTRAIN DATA (optional)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine Torque', unit: 'lb-ft', hint: 'Peak torque', controller: _engineTorqueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Trans Gear Ratio', unit: ':1', hint: 'First gear', controller: _gearRatioController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Final Drive Ratio', unit: ':1', hint: 'Ring & pinion', controller: _finalDriveController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_shaftCapacity != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SHAFT MATERIAL', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _buildOption(colors, '1040', '1040_steel'),
        _buildOption(colors, '4340', '4340_steel'),
        _buildOption(colors, 'Cr-Mo', 'chrome_moly'),
        _buildOption(colors, '300M', '300m'),
      ]),
    ]);
  }

  Widget _buildOption(ZaftoColors colors, String label, String value) {
    final selected = _material == value;
    return GestureDetector(
      onTap: () { setState(() => _material = value); _calculate(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? colors.accentPrimary : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('T = (pi x d^3 x Ss) / 16', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Torsional capacity based on diameter and material', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isGood = _safetyFactor != null && _safetyFactor! >= 1.8;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Shaft Capacity', '${_shaftCapacity!.toStringAsFixed(0)} lb-ft', isPrimary: true),
        if (_wheelTorque != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Wheel Torque (ea)', '${_wheelTorque!.toStringAsFixed(0)} lb-ft'),
        ],
        if (_safetyFactor != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Safety Factor', '${_safetyFactor!.toStringAsFixed(2)}x'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _safetyFactor == null ? colors.bgBase : (isGood ? colors.accentSuccess.withValues(alpha: 0.1) : colors.warning.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            if (_safetyFactor != null) ...[
              Icon(isGood ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isGood ? colors.accentSuccess : colors.warning, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(_status!, style: TextStyle(color: _safetyFactor == null ? colors.textSecondary : (isGood ? colors.accentSuccess : colors.warning), fontSize: 13, fontWeight: FontWeight.w500))),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Recommended safety factor: 1.8x street, 2.5x drag racing. Does not account for shock loads or traction devices.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
