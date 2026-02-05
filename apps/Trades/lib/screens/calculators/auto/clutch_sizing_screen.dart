import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Clutch Sizing Calculator - Clutch holding capacity calculation
class ClutchSizingScreen extends ConsumerStatefulWidget {
  const ClutchSizingScreen({super.key});
  @override
  ConsumerState<ClutchSizingScreen> createState() => _ClutchSizingScreenState();
}

class _ClutchSizingScreenState extends ConsumerState<ClutchSizingScreen> {
  final _torqueController = TextEditingController();
  final _safetyFactorController = TextEditingController(text: '1.25');
  final _frictionCoefController = TextEditingController(text: '0.35');
  final _clampForceController = TextEditingController();
  final _discDiameterController = TextEditingController();

  double? _requiredCapacity;
  double? _actualCapacity;
  double? _safetyMargin;
  String? _recommendation;

  void _calculate() {
    final torque = double.tryParse(_torqueController.text);
    final safetyFactor = double.tryParse(_safetyFactorController.text);
    final frictionCoef = double.tryParse(_frictionCoefController.text);
    final clampForce = double.tryParse(_clampForceController.text);
    final discDiameter = double.tryParse(_discDiameterController.text);

    if (torque == null || safetyFactor == null) {
      setState(() { _requiredCapacity = null; });
      return;
    }

    // Required clutch capacity = Engine Torque × Safety Factor
    final required = torque * safetyFactor;

    double? actual;
    double? margin;
    String recommendation;

    // If clutch specs provided, calculate actual capacity
    // Clutch Capacity = Clamp Force × Friction Coefficient × Mean Disc Radius × Number of Friction Surfaces
    // Simplified: Capacity = Clamp Force × μ × (Disc Diameter / 2) × 2 surfaces / 12 (for lb-ft)
    if (clampForce != null && frictionCoef != null && discDiameter != null && discDiameter > 0) {
      final meanRadius = discDiameter / 2 * 0.75; // Approximate mean friction radius
      actual = clampForce * frictionCoef * meanRadius * 2 / 12; // 2 friction surfaces, convert to lb-ft
      margin = ((actual - required) / required) * 100;
    }

    if (required < 300) {
      recommendation = 'Stock clutch suitable for daily driving';
    } else if (required < 500) {
      recommendation = 'Performance clutch recommended (Stage 1-2)';
    } else if (required < 700) {
      recommendation = 'Heavy-duty clutch required (Stage 3+)';
    } else {
      recommendation = 'Multi-disc or twin-disc clutch recommended';
    }

    setState(() {
      _requiredCapacity = required;
      _actualCapacity = actual;
      _safetyMargin = margin;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _torqueController.clear();
    _safetyFactorController.text = '1.25';
    _frictionCoefController.text = '0.35';
    _clampForceController.clear();
    _discDiameterController.clear();
    setState(() { _requiredCapacity = null; });
  }

  @override
  void dispose() {
    _torqueController.dispose();
    _safetyFactorController.dispose();
    _frictionCoefController.dispose();
    _clampForceController.dispose();
    _discDiameterController.dispose();
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
        title: Text('Clutch Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine Torque', unit: 'lb-ft', hint: 'Peak torque output', controller: _torqueController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Safety Factor', unit: 'x', hint: '1.25 typical', controller: _safetyFactorController, onChanged: (_) => _calculate()),
            const SizedBox(height: 20),
            Text('Clutch Specs (Optional)', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pressure Plate Clamp Force', unit: 'lbs', hint: 'e.g. 2400', controller: _clampForceController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Disc Diameter', unit: 'in', hint: 'e.g. 10.5', controller: _discDiameterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Friction Coefficient', unit: 'μ', hint: '0.30-0.40', controller: _frictionCoefController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_requiredCapacity != null) _buildResultsCard(colors),
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
        Text('Required = Torque × Safety Factor', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Safety: 1.25 street, 1.5+ racing', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Required Capacity', '${_requiredCapacity!.toStringAsFixed(0)} lb-ft', isPrimary: true),
        if (_actualCapacity != null) ...[
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Clutch Capacity', '${_actualCapacity!.toStringAsFixed(0)} lb-ft'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Safety Margin', '${_safetyMargin!.toStringAsFixed(1)}%'),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
