import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Stall Speed Calculator - Torque converter stall speed selection
class StallSpeedScreen extends ConsumerStatefulWidget {
  const StallSpeedScreen({super.key});
  @override
  ConsumerState<StallSpeedScreen> createState() => _StallSpeedScreenState();
}

class _StallSpeedScreenState extends ConsumerState<StallSpeedScreen> {
  final _peakTorqueRpmController = TextEditingController();
  final _camDurationController = TextEditingController();
  final _vehicleWeightController = TextEditingController();
  final _engineHpController = TextEditingController();

  double? _recommendedStall;
  double? _stallRange;
  String? _converterType;
  String? _recommendation;

  void _calculate() {
    final peakTorqueRpm = double.tryParse(_peakTorqueRpmController.text);
    final camDuration = double.tryParse(_camDurationController.text);
    final weight = double.tryParse(_vehicleWeightController.text);
    final hp = double.tryParse(_engineHpController.text);

    if (peakTorqueRpm == null) {
      setState(() { _recommendedStall = null; });
      return;
    }

    // Base stall speed calculation
    // General rule: Stall speed should be slightly below peak torque RPM
    // This allows the engine to build into the torque curve at launch
    double baseStall = peakTorqueRpm * 0.85;

    // Adjust for cam duration (bigger cams need higher stall)
    if (camDuration != null) {
      if (camDuration > 240) {
        baseStall += (camDuration - 240) * 10;
      }
    }

    // Adjust for power-to-weight ratio
    if (weight != null && hp != null && weight > 0) {
      final powerToWeight = hp / (weight / 1000);
      if (powerToWeight > 200) {
        baseStall += 200; // High power needs higher stall
      }
    }

    String type;
    String recommendation;
    double range;

    if (baseStall < 1800) {
      type = 'Stock/tight converter';
      range = 200;
      recommendation = 'Good for daily driving, mild modifications';
    } else if (baseStall < 2400) {
      type = 'Mild performance converter';
      range = 300;
      recommendation = 'Street/strip use, bolt-on modifications';
    } else if (baseStall < 3200) {
      type = 'High stall converter';
      range = 400;
      recommendation = 'Aggressive street, strip use, cammed engines';
    } else if (baseStall < 4000) {
      type = 'Race converter';
      range = 500;
      recommendation = 'Drag racing, big cams, power adders';
    } else {
      type = 'Extreme stall converter';
      range = 600;
      baseStall = 4500; // Cap reasonable max
      recommendation = 'Pro drag racing, transbrake launch';
    }

    setState(() {
      _recommendedStall = baseStall;
      _stallRange = range;
      _converterType = type;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _peakTorqueRpmController.clear();
    _camDurationController.clear();
    _vehicleWeightController.clear();
    _engineHpController.clear();
    setState(() { _recommendedStall = null; });
  }

  @override
  void dispose() {
    _peakTorqueRpmController.dispose();
    _camDurationController.dispose();
    _vehicleWeightController.dispose();
    _engineHpController.dispose();
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
        title: Text('Stall Speed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Peak Torque RPM', unit: 'RPM', hint: 'Where torque peaks', controller: _peakTorqueRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Cam Duration @ 0.050"', unit: 'deg', hint: 'Optional - e.g. 220', controller: _camDurationController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Vehicle Weight', unit: 'lbs', hint: 'Optional - curb weight', controller: _vehicleWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Engine Horsepower', unit: 'HP', hint: 'Optional - at wheels', controller: _engineHpController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_recommendedStall != null) _buildResultsCard(colors),
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
        Text('Stall ≈ Peak Torque RPM × 0.85', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Launch into the torque curve, not above it', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final lowStall = _recommendedStall! - _stallRange! / 2;
    final highStall = _recommendedStall! + _stallRange! / 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Recommended Stall', '${_recommendedStall!.toStringAsFixed(0)} RPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Stall Range', '${lowStall.toStringAsFixed(0)}-${highStall.toStringAsFixed(0)} RPM'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Converter Type', _converterType!),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Flash stall is typically 200-400 RPM lower than foot-brake stall', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Flexible(child: Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600), textAlign: TextAlign.right)),
    ]);
  }
}
