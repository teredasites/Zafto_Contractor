import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Ignition Timing Calculator
class TimingAdvanceScreen extends ConsumerStatefulWidget {
  const TimingAdvanceScreen({super.key});
  @override
  ConsumerState<TimingAdvanceScreen> createState() => _TimingAdvanceScreenState();
}

class _TimingAdvanceScreenState extends ConsumerState<TimingAdvanceScreen> {
  final _baseTimingController = TextEditingController(text: '10');
  final _mechanicalAdvanceController = TextEditingController(text: '20');
  final _vacuumAdvanceController = TextEditingController(text: '10');
  final _rpmController = TextEditingController(text: '3000');
  final _fullAdvanceRpmController = TextEditingController(text: '3000');
  final _compressionController = TextEditingController(text: '9.0');
  final _octaneController = TextEditingController(text: '91');

  double? _totalTiming;
  double? _currentTiming;
  double? _recommendedTotal;
  String? _assessment;
  String? _assessmentColor;

  @override
  void dispose() {
    _baseTimingController.dispose();
    _mechanicalAdvanceController.dispose();
    _vacuumAdvanceController.dispose();
    _rpmController.dispose();
    _fullAdvanceRpmController.dispose();
    _compressionController.dispose();
    _octaneController.dispose();
    super.dispose();
  }

  void _calculate() {
    final baseTiming = double.tryParse(_baseTimingController.text);
    final mechanicalAdvance = double.tryParse(_mechanicalAdvanceController.text);
    final vacuumAdvance = double.tryParse(_vacuumAdvanceController.text) ?? 0;
    final rpm = double.tryParse(_rpmController.text);
    final fullAdvanceRpm = double.tryParse(_fullAdvanceRpmController.text);
    final compression = double.tryParse(_compressionController.text) ?? 9.0;
    final octane = double.tryParse(_octaneController.text) ?? 91;

    if (baseTiming == null || mechanicalAdvance == null || rpm == null || fullAdvanceRpm == null) {
      setState(() { _totalTiming = null; });
      return;
    }

    // Total timing at full advance (no vacuum)
    final totalTiming = baseTiming + mechanicalAdvance;

    // Current timing based on RPM (linear advance curve approximation)
    final advanceRatio = (rpm / fullAdvanceRpm).clamp(0.0, 1.0);
    final currentMechanical = mechanicalAdvance * advanceRatio;
    final currentTiming = baseTiming + currentMechanical + vacuumAdvance;

    // Recommended total timing based on compression and octane
    // Higher compression needs more timing, lower octane needs less
    // Base formula: ~36 degrees for 9:1 on 91 octane
    double recommendedTotal = 36.0;

    // Adjust for compression ratio (roughly 2 degrees per 1:1 change)
    recommendedTotal += (compression - 9.0) * 2;

    // Adjust for octane (roughly 1 degree per 2 octane points)
    recommendedTotal += (octane - 91) / 2;

    // Clamp to reasonable range
    recommendedTotal = recommendedTotal.clamp(28.0, 42.0);

    String assessment;
    String assessmentColor;

    final difference = totalTiming - recommendedTotal;

    if (difference.abs() <= 2) {
      assessment = 'Optimal';
      assessmentColor = 'green';
    } else if (difference > 2 && difference <= 5) {
      assessment = 'Slightly Advanced';
      assessmentColor = 'yellow';
    } else if (difference > 5) {
      assessment = 'Over-Advanced';
      assessmentColor = 'red';
    } else if (difference < -2 && difference >= -5) {
      assessment = 'Slightly Retarded';
      assessmentColor = 'yellow';
    } else {
      assessment = 'Under-Advanced';
      assessmentColor = 'orange';
    }

    setState(() {
      _totalTiming = totalTiming;
      _currentTiming = currentTiming;
      _recommendedTotal = recommendedTotal;
      _assessment = assessment;
      _assessmentColor = assessmentColor;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _baseTimingController.text = '10';
    _mechanicalAdvanceController.text = '20';
    _vacuumAdvanceController.text = '10';
    _rpmController.text = '3000';
    _fullAdvanceRpmController.text = '3000';
    _compressionController.text = '9.0';
    _octaneController.text = '91';
    setState(() { _totalTiming = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Timing Advance', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormulaCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'TIMING COMPONENTS'),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Base Timing', unit: 'deg BTDC', hint: 'Initial timing', controller: _baseTimingController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Mechanical Advance', unit: 'deg', hint: 'Centrifugal advance', controller: _mechanicalAdvanceController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Vacuum Advance', unit: 'deg', hint: 'Vacuum canister', controller: _vacuumAdvanceController, onChanged: (_) => _calculate()),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'ENGINE CONDITIONS'),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Current RPM', unit: 'rpm', hint: 'Engine speed', controller: _rpmController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Full Advance RPM', unit: 'rpm', hint: 'All-in point', controller: _fullAdvanceRpmController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Compression Ratio', unit: ':1', hint: 'Static CR', controller: _compressionController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Fuel Octane', unit: 'RON', hint: 'Pump octane', controller: _octaneController, onChanged: (_) => _calculate()),
              const SizedBox(height: 32),
              if (_totalTiming != null) _buildResultsCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        children: [
          Text('Total = Base + Mechanical + Vacuum', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Ignition timing controls when spark fires before TDC', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    switch (_assessmentColor) {
      case 'green':
        statusColor = Colors.green;
        break;
      case 'yellow':
        statusColor = Colors.amber;
        break;
      case 'orange':
        statusColor = Colors.orange;
        break;
      case 'red':
        statusColor = Colors.red;
        break;
      default:
        statusColor = colors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(
        children: [
          _buildResultRow(colors, 'Total Timing', '${_totalTiming!.toStringAsFixed(1)} deg', isPrimary: true),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Current Timing', '${_currentTiming!.toStringAsFixed(1)} deg'),
          const SizedBox(height: 12),
          _buildResultRow(colors, 'Recommended', '${_recommendedTotal!.toStringAsFixed(1)} deg'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assessment', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(_assessment!, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimingDiagram(colors),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, size: 16, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Text('Detonation Warning', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Over-advanced timing causes knock/ping. Listen for detonation under load and retard if needed.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TYPICAL VALUES', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildReferenceRow(colors, 'Base timing', '6-12 deg'),
                _buildReferenceRow(colors, 'Mechanical', '18-24 deg'),
                _buildReferenceRow(colors, 'Vacuum', '8-15 deg'),
                _buildReferenceRow(colors, 'Total', '32-38 deg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingDiagram(ZaftoColors colors) {
    final baseTiming = double.tryParse(_baseTimingController.text) ?? 0;
    final mechanicalAdvance = double.tryParse(_mechanicalAdvanceController.text) ?? 0;
    final vacuumAdvance = double.tryParse(_vacuumAdvanceController.text) ?? 0;
    final total = baseTiming + mechanicalAdvance + vacuumAdvance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIMING BREAKDOWN', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildTimingBar(colors, 'Base', baseTiming, total, Colors.blue),
          const SizedBox(height: 8),
          _buildTimingBar(colors, 'Mechanical', mechanicalAdvance, total, Colors.orange),
          const SizedBox(height: 8),
          _buildTimingBar(colors, 'Vacuum', vacuumAdvance, total, Colors.green),
        ],
      ),
    );
  }

  Widget _buildTimingBar(ZaftoColors colors, String label, double value, double total, Color barColor) {
    final percentage = total > 0 ? (value / total) : 0.0;
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(color: barColor, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 40, child: Text('${value.toStringAsFixed(0)}°', style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildReferenceRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 20 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}
