import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Line Pressure Calculator - Transmission line pressure calculator
class LinePressureScreen extends ConsumerStatefulWidget {
  const LinePressureScreen({super.key});
  @override
  ConsumerState<LinePressureScreen> createState() => _LinePressureScreenState();
}

class _LinePressureScreenState extends ConsumerState<LinePressureScreen> {
  final _engineTorqueController = TextEditingController();
  final _firstGearController = TextEditingController(text: '2.74');
  final _clutchAreaController = TextEditingController();
  final _clutchCountController = TextEditingController(text: '5');
  final _frictionCoefController = TextEditingController(text: '0.12');
  final _safetyFactorController = TextEditingController(text: '1.3');

  double? _requiredPressure;
  double? _clutchCapacity;
  String? _pressureRange;
  String? _recommendation;

  void _calculate() {
    final torque = double.tryParse(_engineTorqueController.text);
    final firstGear = double.tryParse(_firstGearController.text);
    final clutchArea = double.tryParse(_clutchAreaController.text);
    final clutchCount = double.tryParse(_clutchCountController.text);
    final frictionCoef = double.tryParse(_frictionCoefController.text);
    final safetyFactor = double.tryParse(_safetyFactorController.text);

    if (torque == null || firstGear == null) {
      setState(() { _requiredPressure = null; });
      return;
    }

    // Input torque to transmission = engine torque × converter multiplication (assume 2.0-2.5)
    final converterMultiplier = 2.2;
    final inputTorque = torque * converterMultiplier;

    // Torque through first gear
    final gearTorque = inputTorque * firstGear;

    double requiredPressure;
    double? capacity;
    String range;
    String recommendation;

    if (clutchArea != null && clutchCount != null && frictionCoef != null && safetyFactor != null) {
      // Clutch capacity calculation
      // Capacity = Apply Pressure × Clutch Area × Friction Coef × Number of Friction Surfaces × Mean Radius
      // Simplified: Pressure = Torque × Safety / (Area × μ × n × r)
      // Using typical mean radius of 3 inches
      final meanRadius = 3.0;
      final frictionSurfaces = clutchCount * 2; // Both sides of each plate

      requiredPressure = (gearTorque * (safetyFactor) * 12) /
                         (clutchArea * frictionCoef * frictionSurfaces * meanRadius);

      // Calculate clutch capacity at estimated pressure
      capacity = (requiredPressure * clutchArea * frictionCoef * frictionSurfaces * meanRadius) / 12;
    } else {
      // Estimate based on torque alone
      // Rule of thumb: ~0.5-0.8 PSI per lb-ft of input torque for typical clutch pack
      requiredPressure = gearTorque * 0.6;
    }

    // Classify pressure range
    if (requiredPressure < 100) {
      range = 'Low pressure - verify calculations';
      recommendation = 'Pressure seems low. Check clutch pack specifications.';
    } else if (requiredPressure < 150) {
      range = 'Stock range (100-150 PSI)';
      recommendation = 'Within factory specifications for most transmissions';
    } else if (requiredPressure < 200) {
      range = 'Moderate increase (150-200 PSI)';
      recommendation = 'May need upgraded pump or pressure regulator spring';
    } else if (requiredPressure < 250) {
      range = 'Performance range (200-250 PSI)';
      recommendation = 'Requires upgraded pump and/or valve body modifications';
    } else {
      range = 'Race pressure (250+ PSI)';
      recommendation = 'Full valve body upgrade recommended. Watch for harsh shifts.';
    }

    setState(() {
      _requiredPressure = requiredPressure;
      _clutchCapacity = capacity;
      _pressureRange = range;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _engineTorqueController.clear();
    _firstGearController.text = '2.74';
    _clutchAreaController.clear();
    _clutchCountController.text = '5';
    _frictionCoefController.text = '0.12';
    _safetyFactorController.text = '1.3';
    setState(() { _requiredPressure = null; });
  }

  @override
  void dispose() {
    _engineTorqueController.dispose();
    _firstGearController.dispose();
    _clutchAreaController.dispose();
    _clutchCountController.dispose();
    _frictionCoefController.dispose();
    _safetyFactorController.dispose();
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
        title: Text('Line Pressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Torque', unit: 'lb-ft', hint: 'Peak torque', controller: _engineTorqueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'First Gear Ratio', unit: ':1', hint: 'e.g. 2.74', controller: _firstGearController, onChanged: (_) => _calculate()),
            const SizedBox(height: 20),
            Text('Clutch Pack Specs (Optional)', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Clutch Piston Area', unit: 'sq in', hint: 'e.g. 12', controller: _clutchAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Friction Disc Count', unit: 'discs', hint: 'e.g. 5', controller: _clutchCountController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Friction Coefficient', unit: 'μ', hint: '0.10-0.14', controller: _frictionCoefController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Safety Factor', unit: 'x', hint: '1.2-1.5', controller: _safetyFactorController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_requiredPressure != null) _buildResultsCard(colors),
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
        Text('P = Torque × Safety / (A × μ × n × r)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Higher torque demands higher line pressure', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Required Pressure', '${_requiredPressure!.toStringAsFixed(0)} PSI', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pressure Range', _pressureRange!),
        if (_clutchCapacity != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Clutch Capacity', '${_clutchCapacity!.toStringAsFixed(0)} lb-ft'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Note: Actual pressure varies by gear and throttle position', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))),
      const SizedBox(width: 12),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
