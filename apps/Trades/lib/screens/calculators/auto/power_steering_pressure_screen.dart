import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Power Steering Pressure Calculator - PS pump pressure requirements
class PowerSteeringPressureScreen extends ConsumerStatefulWidget {
  const PowerSteeringPressureScreen({super.key});
  @override
  ConsumerState<PowerSteeringPressureScreen> createState() => _PowerSteeringPressureScreenState();
}

class _PowerSteeringPressureScreenState extends ConsumerState<PowerSteeringPressureScreen> {
  final _vehicleWeightController = TextEditingController();
  final _tireWidthController = TextEditingController(text: '225');
  final _cylinderBoreController = TextEditingController(text: '1.5');

  double? _requiredPressure;
  double? _steeringForce;
  double? _flowRate;
  String? _systemStatus;

  void _calculate() {
    final weight = double.tryParse(_vehicleWeightController.text);
    final tireWidth = double.tryParse(_tireWidthController.text);
    final bore = double.tryParse(_cylinderBoreController.text);

    if (weight == null || tireWidth == null || bore == null ||
        weight <= 0 || bore <= 0) {
      setState(() { _requiredPressure = null; });
      return;
    }

    // Approximate steering force based on front axle weight and tire contact
    // Front axle typically 55-60% of vehicle weight
    final frontAxleWeight = weight * 0.57;

    // Steering force approximation (empirical formula)
    // Higher tire width = more friction = more force needed
    final frictionCoeff = 0.7 + (tireWidth - 185) * 0.001;
    final steeringForce = frontAxleWeight * frictionCoeff * 0.15;

    // Cylinder area
    final cylinderArea = 3.14159 * (bore / 2) * (bore / 2);

    // Required pressure = Force / Area
    final pressure = steeringForce / cylinderArea;

    // Typical flow rate needed (2.5-4 GPM for most vehicles)
    final flowRate = 2.5 + (weight / 5000);

    String status;
    if (pressure < 800) {
      status = 'Low - Check for leaks';
    } else if (pressure <= 1500) {
      status = 'Normal Operating Range';
    } else if (pressure <= 2000) {
      status = 'High - Heavy-duty application';
    } else {
      status = 'Very High - Verify specs';
    }

    setState(() {
      _requiredPressure = pressure;
      _steeringForce = steeringForce;
      _flowRate = flowRate.clamp(2.0, 5.0);
      _systemStatus = status;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _vehicleWeightController.clear();
    _tireWidthController.text = '225';
    _cylinderBoreController.text = '1.5';
    setState(() { _requiredPressure = null; });
  }

  @override
  void dispose() {
    _vehicleWeightController.dispose();
    _tireWidthController.dispose();
    _cylinderBoreController.dispose();
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
        title: Text('Power Steering Pressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'Curb weight', controller: _vehicleWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tire Width', unit: 'mm', hint: 'Section width (e.g., 225)', controller: _tireWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'PS Cylinder Bore', unit: 'in', hint: 'Steering cylinder diameter', controller: _cylinderBoreController, onChanged: (_) => _calculate()),
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
        Text('Pressure = Force / Cylinder Area', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Normal: 800-1500 PSI, Flow: 2.5-4 GPM', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
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
        _buildResultRow(colors, 'Steering Force', '${_steeringForce!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Flow Rate Needed', '${_flowRate!.toStringAsFixed(1)} GPM'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'System Status', _systemStatus!),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.end)),
    ]);
  }
}
