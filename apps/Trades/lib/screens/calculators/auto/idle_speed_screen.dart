import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Idle Speed Adjustment Calculator
class IdleSpeedScreen extends ConsumerStatefulWidget {
  const IdleSpeedScreen({super.key});
  @override
  ConsumerState<IdleSpeedScreen> createState() => _IdleSpeedScreenState();
}

class _IdleSpeedScreenState extends ConsumerState<IdleSpeedScreen> {
  final _currentIdleController = TextEditingController();
  final _targetIdleController = TextEditingController(text: '750');
  final _warmIdleController = TextEditingController();
  final _coldIdleController = TextEditingController();
  final _acOnIdleController = TextEditingController();
  final _driveIdleController = TextEditingController();

  String _engineType = 'fuel_injected';
  bool _hasAC = true;
  bool _isAutomatic = true;

  String? _assessment;
  String? _assessmentColor;
  List<String> _issues = [];
  List<String> _adjustments = [];

  @override
  void dispose() {
    _currentIdleController.dispose();
    _targetIdleController.dispose();
    _warmIdleController.dispose();
    _coldIdleController.dispose();
    _acOnIdleController.dispose();
    _driveIdleController.dispose();
    super.dispose();
  }

  void _calculate() {
    final currentIdle = double.tryParse(_currentIdleController.text);
    final targetIdle = double.tryParse(_targetIdleController.text) ?? 750;
    final warmIdle = double.tryParse(_warmIdleController.text);
    final coldIdle = double.tryParse(_coldIdleController.text);
    final acOnIdle = double.tryParse(_acOnIdleController.text);
    final driveIdle = double.tryParse(_driveIdleController.text);

    if (currentIdle == null) {
      setState(() { _assessment = null; });
      return;
    }

    List<String> issues = [];
    List<String> adjustments = [];
    String assessment;
    String assessmentColor;

    // Determine acceptable range based on engine type
    final minIdle = _isAutomatic ? 600.0 : 700.0;
    final maxIdle = _isAutomatic ? 900.0 : 950.0;
    final targetMin = targetIdle - 50;
    final targetMax = targetIdle + 50;

    // Check current idle
    if (currentIdle >= targetMin && currentIdle <= targetMax) {
      assessment = 'Good';
      assessmentColor = 'green';
    } else if (currentIdle < minIdle) {
      assessment = 'Too Low';
      assessmentColor = 'red';
      issues.add('Idle speed below minimum (${minIdle.toInt()} RPM)');
      adjustments.add('Increase base idle speed');
      if (_engineType == 'carbureted') {
        adjustments.add('Adjust idle speed screw clockwise');
        adjustments.add('Check for vacuum leaks');
      } else {
        adjustments.add('Clean IAC valve');
        adjustments.add('Check throttle body for carbon');
        adjustments.add('Check for vacuum leaks');
      }
    } else if (currentIdle > maxIdle) {
      assessment = 'Too High';
      assessmentColor = 'orange';
      issues.add('Idle speed above maximum (${maxIdle.toInt()} RPM)');
      adjustments.add('Decrease base idle speed');
      if (_engineType == 'carbureted') {
        adjustments.add('Adjust idle speed screw counter-clockwise');
        adjustments.add('Check fast idle cam');
      } else {
        adjustments.add('Check for stuck IAC valve');
        adjustments.add('Check for throttle plate not closing');
        adjustments.add('Check TPS sensor');
      }
    } else if (currentIdle < targetMin) {
      assessment = 'Slightly Low';
      assessmentColor = 'yellow';
      issues.add('Below target idle (${targetIdle.toInt()} RPM)');
      adjustments.add('Minor adjustment needed - increase idle');
    } else {
      assessment = 'Slightly High';
      assessmentColor = 'yellow';
      issues.add('Above target idle (${targetIdle.toInt()} RPM)');
      adjustments.add('Minor adjustment needed - decrease idle');
    }

    // Check warm vs cold idle
    if (warmIdle != null && coldIdle != null) {
      final coldDiff = coldIdle - warmIdle;
      if (coldDiff < 100) {
        issues.add('Cold idle too close to warm idle');
        adjustments.add('Check fast idle/cold start system');
      } else if (coldDiff > 500) {
        issues.add('Excessive cold idle speed');
        adjustments.add('Adjust fast idle cam or ISC');
      }
    }

    // Check A/C idle
    if (_hasAC && acOnIdle != null && warmIdle != null) {
      final acDiff = acOnIdle - warmIdle;
      if (acDiff < 50) {
        issues.add('A/C idle compensation too low');
        adjustments.add('Adjust A/C idle-up circuit');
      } else if (acDiff > 200) {
        issues.add('A/C idle compensation too high');
        adjustments.add('Check A/C idle solenoid');
      }
    }

    // Check drive idle (automatic)
    if (_isAutomatic && driveIdle != null && warmIdle != null) {
      final driveDiff = warmIdle - driveIdle;
      if (driveDiff < 0) {
        issues.add('Drive idle higher than park idle');
        adjustments.add('Check neutral safety switch');
      } else if (driveDiff > 100) {
        issues.add('Excessive idle drop in drive');
        adjustments.add('Increase base idle or check IAC');
      }
    }

    setState(() {
      _assessment = assessment;
      _assessmentColor = assessmentColor;
      _issues = issues;
      _adjustments = adjustments;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentIdleController.clear();
    _targetIdleController.text = '750';
    _warmIdleController.clear();
    _coldIdleController.clear();
    _acOnIdleController.clear();
    _driveIdleController.clear();
    setState(() { _assessment = null; });
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
        title: Text('Idle Speed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ENGINE TYPE'),
              const SizedBox(height: 12),
              _buildEngineTypeSelector(colors),
              const SizedBox(height: 12),
              _buildOptionsRow(colors),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'IDLE READINGS'),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Current Idle', unit: 'rpm', hint: 'Your reading', controller: _currentIdleController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Target Idle', unit: 'rpm', hint: 'Spec idle speed', controller: _targetIdleController, onChanged: (_) => _calculate()),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'ADDITIONAL READINGS (Optional)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ZaftoInputField(label: 'Warm Idle', unit: 'rpm', hint: 'Normal temp', controller: _warmIdleController, onChanged: (_) => _calculate())),
                  const SizedBox(width: 12),
                  Expanded(child: ZaftoInputField(label: 'Cold Idle', unit: 'rpm', hint: 'Cold start', controller: _coldIdleController, onChanged: (_) => _calculate())),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: ZaftoInputField(label: 'A/C On', unit: 'rpm', hint: 'With A/C', controller: _acOnIdleController, onChanged: (_) => _calculate())),
                  const SizedBox(width: 12),
                  Expanded(child: ZaftoInputField(label: 'In Drive', unit: 'rpm', hint: 'Auto only', controller: _driveIdleController, onChanged: (_) => _calculate())),
                ],
              ),
              const SizedBox(height: 32),
              if (_assessment != null) _buildResultsCard(colors),
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
          Text('Target: 650-850 RPM (varies by vehicle)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Proper idle speed ensures smooth operation and emissions compliance', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildEngineTypeSelector(ZaftoColors colors) {
    return Row(
      children: [
        _buildTypeOption(colors, 'fuel_injected', 'Fuel Injected'),
        const SizedBox(width: 12),
        _buildTypeOption(colors, 'carbureted', 'Carbureted'),
      ],
    );
  }

  Widget _buildTypeOption(ZaftoColors colors, String value, String label) {
    final isSelected = _engineType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _engineType = value;
          });
          _calculate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
          ),
          child: Center(child: Text(label, style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13))),
        ),
      ),
    );
  }

  Widget _buildOptionsRow(ZaftoColors colors) {
    return Row(
      children: [
        Expanded(child: _buildToggle(colors, 'A/C Equipped', _hasAC, (v) { setState(() { _hasAC = v; }); _calculate(); })),
        const SizedBox(width: 12),
        Expanded(child: _buildToggle(colors, 'Automatic Trans', _isAutomatic, (v) { setState(() { _isAutomatic = v; }); _calculate(); })),
      ],
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: value ? colors.accentPrimary : colors.textTertiary, width: 2),
                color: value ? colors.accentPrimary : Colors.transparent,
              ),
              child: value ? Icon(LucideIcons.check, size: 12, color: colors.bgBase) : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(color: value ? colors.accentPrimary : colors.textSecondary, fontSize: 12))),
          ],
        ),
      ),
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assessment', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(_assessment!, style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (_issues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Issues Found:', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  ..._issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.alertTriangle, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Expanded(child: Text(issue, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          if (_adjustments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.wrench, size: 16, color: colors.accentPrimary),
                      const SizedBox(width: 8),
                      Text('Adjustments', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._adjustments.map((adj) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.chevronRight, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(adj, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TYPICAL SPECS', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildSpecRow(colors, 'Warm idle (P/N)', '650-850 RPM'),
                _buildSpecRow(colors, 'Cold idle', '1000-1500 RPM'),
                _buildSpecRow(colors, 'A/C on increase', '50-100 RPM'),
                _buildSpecRow(colors, 'Drive drop', '50-100 RPM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String value) {
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
}
