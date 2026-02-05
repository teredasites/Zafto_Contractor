import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Scavenging Effect Calculator - Exhaust scavenging timing
class ScavengingEffectScreen extends ConsumerStatefulWidget {
  const ScavengingEffectScreen({super.key});
  @override
  ConsumerState<ScavengingEffectScreen> createState() => _ScavengingEffectScreenState();
}

class _ScavengingEffectScreenState extends ConsumerState<ScavengingEffectScreen> {
  final _primaryLengthController = TextEditingController();
  final _exhaustTempController = TextEditingController(text: '1400');
  final _targetRpmController = TextEditingController(text: '6000');

  double? _pulseVelocity;
  double? _returnTime;
  double? _optimalRpm;
  double? _scavengingWindow;
  String? _assessment;

  void _calculate() {
    final primaryL = double.tryParse(_primaryLengthController.text);
    final exhaustTemp = double.tryParse(_exhaustTempController.text);
    final targetRpm = double.tryParse(_targetRpmController.text);

    if (primaryL == null || exhaustTemp == null || targetRpm == null) {
      setState(() { _pulseVelocity = null; });
      return;
    }

    // Speed of sound varies with temperature
    // v = 49.03 * sqrt(T + 460) ft/sec for Fahrenheit
    final tempRankine = exhaustTemp + 460;
    final soundSpeed = 49.03 * _sqrt(tempRankine);

    // Pulse velocity in ft/sec (approximately speed of sound in exhaust gas)
    final pulseVel = soundSpeed;

    // Time for pulse to travel down primary and return (round trip)
    // Primary length in inches, convert to feet
    final primaryFt = primaryL / 12;
    final returnTimeMs = (2 * primaryFt / pulseVel) * 1000;

    // Optimal RPM for scavenging effect
    // The negative pressure wave should arrive during valve overlap
    // Assuming 270 degree exhaust duration: optimal = 60000 / (return time in ms * 3)
    final optRpm = 60000 / (returnTimeMs * 3);

    // Scavenging window in degrees at target RPM
    final degreesPerMs = (targetRpm * 360) / 60000;
    final windowDegrees = returnTimeMs * degreesPerMs * 0.5; // Effective window

    // Assessment based on target RPM vs optimal
    final rpmDiff = (targetRpm - optRpm).abs();
    final rpmPercent = (rpmDiff / optRpm) * 100;

    String assess;
    if (rpmPercent < 10) {
      assess = 'Excellent - headers tuned for target RPM';
    } else if (rpmPercent < 20) {
      assess = 'Good - within effective scavenging range';
    } else if (rpmPercent < 35) {
      assess = 'Marginal - consider different primary length';
    } else {
      assess = 'Poor - headers mismatched for target RPM';
    }

    setState(() {
      _pulseVelocity = pulseVel;
      _returnTime = returnTimeMs;
      _optimalRpm = optRpm;
      _scavengingWindow = windowDegrees;
      _assessment = assess;
    });
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _primaryLengthController.clear();
    _exhaustTempController.text = '1400';
    _targetRpmController.text = '6000';
    setState(() { _pulseVelocity = null; });
  }

  @override
  void dispose() {
    _primaryLengthController.dispose();
    _exhaustTempController.dispose();
    _targetRpmController.dispose();
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
        title: Text('Scavenging Effect', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Primary Tube Length', unit: 'in', hint: 'Header primary length', controller: _primaryLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Exhaust Gas Temp', unit: 'F', hint: '1200-1600F typical', controller: _exhaustTempController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Peak RPM', unit: 'RPM', hint: 'Desired power peak', controller: _targetRpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pulseVelocity != null) _buildResultsCard(colors),
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
        Text('v = 49.03 x sqrt(T + 460)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 4),
        Text('t = 2L / v', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Pulse timing for exhaust scavenging effect', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final targetRpm = double.tryParse(_targetRpmController.text) ?? 6000;
    final isOptimal = (_optimalRpm! - targetRpm).abs() / _optimalRpm! < 0.15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Optimal Scavenging RPM', '${_optimalRpm!.toStringAsFixed(0)}', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Pulse Velocity', '${_pulseVelocity!.toStringAsFixed(0)} ft/s'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Round-Trip Time', '${_returnTime!.toStringAsFixed(2)} ms'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Scavenging Window', '${_scavengingWindow!.toStringAsFixed(1)} deg'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOptimal ? colors.accentSuccess.withValues(alpha: 0.1) : colors.accentWarning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(_assessment!, style: TextStyle(color: isOptimal ? colors.accentSuccess : colors.accentWarning, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(height: 12),
        _buildExplanationCard(colors),
      ]),
    );
  }

  Widget _buildExplanationCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How Scavenging Works:', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          '1. Exhaust valve opens, pressure wave travels down primary\n'
          '2. Wave reflects at collector as negative pressure\n'
          '3. Negative wave returns to help evacuate cylinder\n'
          '4. Timing must align with valve overlap period',
          style: TextStyle(color: colors.textTertiary, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Text('Primary Length Guidelines:', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        _buildLengthRow(colors, 'High RPM (7000+)', '28-32"'),
        _buildLengthRow(colors, 'Mid RPM (5500-7000)', '32-38"'),
        _buildLengthRow(colors, 'Low RPM (< 5500)', '38-42"'),
      ]),
    );
  }

  Widget _buildLengthRow(ZaftoColors colors, String range, String length) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(range, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(length, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontFamily: 'monospace')),
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
