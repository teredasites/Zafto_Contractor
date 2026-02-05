import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';
import 'dart:math' as math;

/// Launch RPM Calculator - Optimal launch RPM for drag racing
class LaunchRpmScreen extends ConsumerStatefulWidget {
  const LaunchRpmScreen({super.key});
  @override
  ConsumerState<LaunchRpmScreen> createState() => _LaunchRpmScreenState();
}

class _LaunchRpmScreenState extends ConsumerState<LaunchRpmScreen> {
  final _peakTorqueRpmController = TextEditingController();
  final _peakHpRpmController = TextEditingController();
  final _stallSpeedController = TextEditingController();
  final _tireHeightController = TextEditingController(text: '26');

  double? _optimalLaunchRpm;
  double? _powerBandStart;
  double? _powerBandEnd;
  String? _launchAdvice;

  void _calculate() {
    final peakTorqueRpm = double.tryParse(_peakTorqueRpmController.text);
    final peakHpRpm = double.tryParse(_peakHpRpmController.text);
    final stallSpeed = double.tryParse(_stallSpeedController.text);
    final tireHeight = double.tryParse(_tireHeightController.text);

    if (peakTorqueRpm == null || peakHpRpm == null) {
      setState(() { _optimalLaunchRpm = null; });
      return;
    }

    // Power band typically starts around peak torque
    final powerBandStart = peakTorqueRpm;
    final powerBandEnd = peakHpRpm;

    // Optimal launch RPM considerations:
    // - Should be above converter stall (if auto)
    // - Should be near or just above peak torque
    // - Higher for manual trans (clutch slip)
    double optimalRpm;
    String advice;

    if (stallSpeed != null && stallSpeed > 0) {
      // Automatic transmission
      // Launch at or slightly above stall speed for best hook
      optimalRpm = stallSpeed + 200;
      if (optimalRpm < peakTorqueRpm * 0.8) {
        optimalRpm = peakTorqueRpm * 0.85;
      }
      advice = 'Auto trans: Launch at ${optimalRpm.toStringAsFixed(0)} RPM (stall + 200). '
               'Brake-torque to build boost/converter pressure.';
    } else {
      // Manual transmission
      // Launch higher for clutch slip, near peak torque
      optimalRpm = peakTorqueRpm * 0.9;
      advice = 'Manual trans: Slip clutch from ${optimalRpm.toStringAsFixed(0)} RPM. '
               'Modulate clutch to control wheelspin.';
    }

    // Adjust for tire size (larger tires need more RPM)
    if (tireHeight != null && tireHeight > 28) {
      optimalRpm *= 1 + ((tireHeight - 28) * 0.02);
      advice += ' Large tires may require higher launch RPM.';
    }

    setState(() {
      _optimalLaunchRpm = optimalRpm;
      _powerBandStart = powerBandStart;
      _powerBandEnd = powerBandEnd;
      _launchAdvice = advice;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _peakTorqueRpmController.clear();
    _peakHpRpmController.clear();
    _stallSpeedController.clear();
    _tireHeightController.text = '26';
    setState(() { _optimalLaunchRpm = null; });
  }

  @override
  void dispose() {
    _peakTorqueRpmController.dispose();
    _peakHpRpmController.dispose();
    _stallSpeedController.dispose();
    _tireHeightController.dispose();
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
        title: Text('Launch RPM', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Peak Torque RPM', unit: 'RPM', hint: 'From dyno sheet', controller: _peakTorqueRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Peak HP RPM', unit: 'RPM', hint: 'From dyno sheet', controller: _peakHpRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Converter Stall', unit: 'RPM', hint: 'Leave blank for manual', controller: _stallSpeedController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tire Height', unit: 'in', hint: 'Diameter', controller: _tireHeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_optimalLaunchRpm != null) _buildResultsCard(colors),
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
        Text('Launch RPM = f(Torque Peak, Stall)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Optimize launch for maximum traction', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Optimal Launch RPM', '${_optimalLaunchRpm!.toStringAsFixed(0)}', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Power Band Start', '${_powerBandStart!.toStringAsFixed(0)} RPM'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Power Band End', '${_powerBandEnd!.toStringAsFixed(0)} RPM'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_launchAdvice!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
