import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Charging System Diagnostics - Test and analyze charging system
class ChargingSystemScreen extends ConsumerStatefulWidget {
  const ChargingSystemScreen({super.key});
  @override
  ConsumerState<ChargingSystemScreen> createState() => _ChargingSystemScreenState();
}

class _ChargingSystemScreenState extends ConsumerState<ChargingSystemScreen> {
  final _batteryVoltageController = TextEditingController();
  final _runningVoltageController = TextEditingController();
  final _loadVoltageController = TextEditingController();

  String? _batteryStatus;
  String? _alternatorStatus;
  String? _loadStatus;

  void _calculate() {
    final batteryV = double.tryParse(_batteryVoltageController.text);
    final runningV = double.tryParse(_runningVoltageController.text);
    final loadV = double.tryParse(_loadVoltageController.text);

    // Battery status
    if (batteryV != null) {
      if (batteryV >= 12.6) {
        _batteryStatus = 'Fully charged';
      } else if (batteryV >= 12.4) {
        _batteryStatus = '75% charged';
      } else if (batteryV >= 12.2) {
        _batteryStatus = '50% charged';
      } else if (batteryV >= 12.0) {
        _batteryStatus = '25% charged';
      } else {
        _batteryStatus = 'Discharged - charge or replace';
      }
    } else {
      _batteryStatus = null;
    }

    // Alternator status
    if (runningV != null) {
      if (runningV >= 13.5 && runningV <= 14.8) {
        _alternatorStatus = 'Normal charging';
      } else if (runningV > 14.8) {
        _alternatorStatus = 'Overcharging - check regulator';
      } else if (runningV >= 13.0) {
        _alternatorStatus = 'Low output - check belt/connections';
      } else {
        _alternatorStatus = 'Not charging - alternator fault';
      }
    } else {
      _alternatorStatus = null;
    }

    // Load test status
    if (loadV != null) {
      if (loadV >= 13.0) {
        _loadStatus = 'Good - handles load well';
      } else if (loadV >= 12.5) {
        _loadStatus = 'Marginal - may struggle with high loads';
      } else {
        _loadStatus = 'Weak - alternator may be undersized or failing';
      }
    } else {
      _loadStatus = null;
    }

    setState(() {});
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _batteryVoltageController.clear();
    _runningVoltageController.clear();
    _loadVoltageController.clear();
    setState(() { _batteryStatus = null; _alternatorStatus = null; _loadStatus = null; });
  }

  @override
  void dispose() {
    _batteryVoltageController.dispose();
    _runningVoltageController.dispose();
    _loadVoltageController.dispose();
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
        title: Text('Charging System', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildTestInput(colors, 'Battery (Engine Off)', 'V', 'Key off, surface charge settled', _batteryVoltageController, _batteryStatus),
            const SizedBox(height: 16),
            _buildTestInput(colors, 'Running (No Load)', 'V', 'Engine at 2000 RPM', _runningVoltageController, _alternatorStatus),
            const SizedBox(height: 16),
            _buildTestInput(colors, 'Running (With Load)', 'V', 'A/C, lights, blower on', _loadVoltageController, _loadStatus),
            const SizedBox(height: 32),
            _buildReferenceCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildTestInput(ZaftoColors colors, String label, String unit, String hint, TextEditingController controller, String? status) {
    Color? statusColor;
    if (status != null) {
      if (status.contains('Normal') || status.contains('Fully') || status.contains('Good')) {
        statusColor = colors.accentSuccess;
      } else if (status.contains('fault') || status.contains('Discharged') || status.contains('Weak') || status.contains('Overcharging')) {
        statusColor = colors.error;
      } else {
        statusColor = colors.warning;
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ZaftoInputField(label: label, unit: unit, hint: hint, controller: controller, onChanged: (_) => _calculate()),
      if (status != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor!.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(status.contains('Normal') || status.contains('Fully') || status.contains('Good') ? LucideIcons.checkCircle : LucideIcons.alertCircle, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Expanded(child: Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500))),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Battery: 12.6V | Running: 13.5-14.8V', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Test at battery terminals with clean connections', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildReferenceCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BATTERY STATE OF CHARGE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildRefRow(colors, '12.6V+', '100%'),
        _buildRefRow(colors, '12.4V', '75%'),
        _buildRefRow(colors, '12.2V', '50%'),
        _buildRefRow(colors, '12.0V', '25%'),
        _buildRefRow(colors, '11.8V', '0% - Damaged if left'),
      ]),
    );
  }

  Widget _buildRefRow(ZaftoColors colors, String voltage, String charge) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(voltage, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(charge, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
