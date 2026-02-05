import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Compression Test Analysis Calculator
class CompressionTestScreen extends ConsumerStatefulWidget {
  const CompressionTestScreen({super.key});
  @override
  ConsumerState<CompressionTestScreen> createState() => _CompressionTestScreenState();
}

class _CompressionTestScreenState extends ConsumerState<CompressionTestScreen> {
  final _cyl1Controller = TextEditingController();
  final _cyl2Controller = TextEditingController();
  final _cyl3Controller = TextEditingController();
  final _cyl4Controller = TextEditingController();
  final _cyl5Controller = TextEditingController();
  final _cyl6Controller = TextEditingController();
  final _cyl7Controller = TextEditingController();
  final _cyl8Controller = TextEditingController();
  final _specController = TextEditingController(text: '150');

  int _cylinderCount = 4;
  double? _average;
  double? _lowest;
  double? _highest;
  double? _variation;
  String? _condition;
  String? _conditionColor;
  List<String> _issues = [];

  @override
  void dispose() {
    _cyl1Controller.dispose();
    _cyl2Controller.dispose();
    _cyl3Controller.dispose();
    _cyl4Controller.dispose();
    _cyl5Controller.dispose();
    _cyl6Controller.dispose();
    _cyl7Controller.dispose();
    _cyl8Controller.dispose();
    _specController.dispose();
    super.dispose();
  }

  List<TextEditingController> get _activeControllers {
    switch (_cylinderCount) {
      case 4:
        return [_cyl1Controller, _cyl2Controller, _cyl3Controller, _cyl4Controller];
      case 6:
        return [_cyl1Controller, _cyl2Controller, _cyl3Controller, _cyl4Controller, _cyl5Controller, _cyl6Controller];
      case 8:
        return [_cyl1Controller, _cyl2Controller, _cyl3Controller, _cyl4Controller, _cyl5Controller, _cyl6Controller, _cyl7Controller, _cyl8Controller];
      default:
        return [_cyl1Controller, _cyl2Controller, _cyl3Controller, _cyl4Controller];
    }
  }

  void _calculate() {
    final spec = double.tryParse(_specController.text) ?? 150;
    final readings = <double>[];

    for (final controller in _activeControllers) {
      final value = double.tryParse(controller.text);
      if (value != null && value > 0) {
        readings.add(value);
      }
    }

    if (readings.isEmpty) {
      setState(() { _average = null; });
      return;
    }

    final average = readings.reduce((a, b) => a + b) / readings.length;
    final lowest = readings.reduce((a, b) => a < b ? a : b);
    final highest = readings.reduce((a, b) => a > b ? a : b);
    final variation = ((highest - lowest) / highest) * 100;

    String condition;
    String conditionColor;
    List<String> issues = [];

    // 10% rule: All cylinders should be within 10% of each other
    final tenPercentOfHighest = highest * 0.10;
    final withinSpec = (highest - lowest) <= tenPercentOfHighest;

    // Check if readings are within manufacturer spec (typically 150-200 psi)
    final belowSpec = average < (spec * 0.75);
    final lowCylinders = readings.where((r) => r < (highest - tenPercentOfHighest)).toList();

    if (withinSpec && !belowSpec) {
      condition = 'Good';
      conditionColor = 'green';
    } else if (variation <= 15 && !belowSpec) {
      condition = 'Fair';
      conditionColor = 'yellow';
      issues.add('Slight variation between cylinders');
    } else if (belowSpec && withinSpec) {
      condition = 'Low';
      conditionColor = 'orange';
      issues.add('All cylinders below spec - general wear');
    } else {
      condition = 'Problem';
      conditionColor = 'red';
      if (lowCylinders.isNotEmpty) {
        issues.add('${lowCylinders.length} cylinder(s) significantly lower');
      }
      if (belowSpec) {
        issues.add('Overall compression below spec');
      }
    }

    // Add specific diagnostics
    if (lowest < 100) {
      issues.add('Very low reading suggests major issue');
    }
    if (variation > 20) {
      issues.add('Large variation - possible blown gasket');
    }

    setState(() {
      _average = average;
      _lowest = lowest;
      _highest = highest;
      _variation = variation;
      _condition = condition;
      _conditionColor = conditionColor;
      _issues = issues;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    for (final controller in _activeControllers) {
      controller.clear();
    }
    _specController.text = '150';
    setState(() { _average = null; });
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
        title: Text('Compression Test', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSectionHeader(colors, 'ENGINE CONFIGURATION'),
              const SizedBox(height: 12),
              _buildCylinderSelector(colors),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Spec Minimum', unit: 'psi', hint: 'Manufacturer spec', controller: _specController, onChanged: (_) => _calculate()),
              const SizedBox(height: 20),
              _buildSectionHeader(colors, 'CYLINDER READINGS'),
              const SizedBox(height: 12),
              _buildCylinderInputs(colors),
              const SizedBox(height: 32),
              if (_average != null) _buildResultsCard(colors),
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
          Text('10% Rule: All cylinders within 10% of highest', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 8),
          Text('Compression test reveals piston ring, valve, and gasket health', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildCylinderSelector(ZaftoColors colors) {
    return Row(
      children: [
        _buildCylinderOption(colors, 4),
        const SizedBox(width: 12),
        _buildCylinderOption(colors, 6),
        const SizedBox(width: 12),
        _buildCylinderOption(colors, 8),
      ],
    );
  }

  Widget _buildCylinderOption(ZaftoColors colors, int count) {
    final isSelected = _cylinderCount == count;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _cylinderCount = count;
            _average = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary.withValues(alpha: 0.2) : colors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
          ),
          child: Center(child: Text('$count Cyl', style: TextStyle(color: isSelected ? colors.accentPrimary : colors.textSecondary, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }

  Widget _buildCylinderInputs(ZaftoColors colors) {
    final controllers = _activeControllers;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: ZaftoInputField(label: 'Cyl 1', unit: 'psi', hint: '', controller: controllers[0], onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: ZaftoInputField(label: 'Cyl 2', unit: 'psi', hint: '', controller: controllers[1], onChanged: (_) => _calculate())),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ZaftoInputField(label: 'Cyl 3', unit: 'psi', hint: '', controller: controllers[2], onChanged: (_) => _calculate())),
            const SizedBox(width: 12),
            Expanded(child: ZaftoInputField(label: 'Cyl 4', unit: 'psi', hint: '', controller: controllers[3], onChanged: (_) => _calculate())),
          ],
        ),
        if (_cylinderCount >= 6) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ZaftoInputField(label: 'Cyl 5', unit: 'psi', hint: '', controller: controllers[4], onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Cyl 6', unit: 'psi', hint: '', controller: controllers[5], onChanged: (_) => _calculate())),
            ],
          ),
        ],
        if (_cylinderCount == 8) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ZaftoInputField(label: 'Cyl 7', unit: 'psi', hint: '', controller: controllers[6], onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Cyl 8', unit: 'psi', hint: '', controller: controllers[7], onChanged: (_) => _calculate())),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    Color statusColor;
    switch (_conditionColor) {
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
              Text('Condition', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(_condition!, style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow(colors, 'Average', '${_average!.toStringAsFixed(0)} psi'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Highest', '${_highest!.toStringAsFixed(0)} psi'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Lowest', '${_lowest!.toStringAsFixed(0)} psi'),
          const SizedBox(height: 8),
          _buildResultRow(colors, 'Variation', '${_variation!.toStringAsFixed(1)}%', isPrimary: true),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.info, size: 16, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Text('Wet Test', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Add oil to low cylinder and retest. Higher reading = ring issue. Same reading = valve issue.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 18 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }
}
