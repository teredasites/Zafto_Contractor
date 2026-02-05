import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shift Point Calculator - Optimal shift point for maximum acceleration
class ShiftPointScreen extends ConsumerStatefulWidget {
  const ShiftPointScreen({super.key});
  @override
  ConsumerState<ShiftPointScreen> createState() => _ShiftPointScreenState();
}

class _ShiftPointScreenState extends ConsumerState<ShiftPointScreen> {
  final _peakHpRpmController = TextEditingController();
  final _redlineController = TextEditingController();
  final _currentGearController = TextEditingController();
  final _nextGearController = TextEditingController();

  double? _optimalShiftRpm;
  double? _dropRpm;
  double? _gearRatioChange;
  String? _recommendation;

  void _calculate() {
    final peakHpRpm = double.tryParse(_peakHpRpmController.text);
    final redline = double.tryParse(_redlineController.text);
    final currentGear = double.tryParse(_currentGearController.text);
    final nextGear = double.tryParse(_nextGearController.text);

    if (peakHpRpm == null || redline == null || currentGear == null || nextGear == null) {
      setState(() { _optimalShiftRpm = null; });
      return;
    }

    if (currentGear <= 0 || nextGear <= 0) {
      setState(() { _optimalShiftRpm = null; });
      return;
    }

    // Gear ratio change
    final gearChange = nextGear / currentGear;

    // RPM drop after shift = Current RPM × (Next Gear Ratio / Current Gear Ratio)
    // Optimal shift keeps you in the powerband after the shift
    // Shift when: RPM × gear_ratio_change >= peak_hp_rpm

    // Optimal shift point calculation
    // We want to land at or above peak HP RPM after shift
    // Shift RPM × (nextGear/currentGear) = target landing RPM
    // For max acceleration, land just above peak torque/HP

    final optimalShift = peakHpRpm / gearChange;

    // Clamp to redline
    final actualShift = optimalShift > redline ? redline : optimalShift;
    final dropToRpm = actualShift * gearChange;

    String recommendation;
    if (actualShift < peakHpRpm) {
      recommendation = 'Shift early - powerband is narrow or gear spread is tight';
    } else if (actualShift > redline - 200) {
      recommendation = 'Shift at redline - large gear spread requires high RPM shifts';
    } else {
      recommendation = 'Shift at ${actualShift.toStringAsFixed(0)} RPM for optimal acceleration';
    }

    setState(() {
      _optimalShiftRpm = actualShift;
      _dropRpm = dropToRpm;
      _gearRatioChange = (1 - gearChange) * 100;
      _recommendation = recommendation;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _peakHpRpmController.clear();
    _redlineController.clear();
    _currentGearController.clear();
    _nextGearController.clear();
    setState(() { _optimalShiftRpm = null; });
  }

  @override
  void dispose() {
    _peakHpRpmController.dispose();
    _redlineController.dispose();
    _currentGearController.dispose();
    _nextGearController.dispose();
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
        title: Text('Shift Point', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Peak Horsepower RPM', unit: 'RPM', hint: 'Where HP peaks', controller: _peakHpRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Redline', unit: 'RPM', hint: 'Rev limiter', controller: _redlineController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Current Gear Ratio', unit: ':1', hint: 'e.g. 2.66 (2nd)', controller: _currentGearController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Next Gear Ratio', unit: ':1', hint: 'e.g. 1.78 (3rd)', controller: _nextGearController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_optimalShiftRpm != null) _buildResultsCard(colors),
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
        Text('Shift = Peak HP RPM / Gear Ratio Change', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Shift to land in the powerband for max acceleration', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Optimal Shift Point', '${_optimalShiftRpm!.toStringAsFixed(0)} RPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'RPM After Shift', '${_dropRpm!.toStringAsFixed(0)} RPM'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'RPM Drop', '${_gearRatioChange!.toStringAsFixed(1)}%'),
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
