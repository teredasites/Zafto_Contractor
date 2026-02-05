import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Emissions Prep Calculator - Prepare vehicle for emissions testing
class EmissionsPrepScreen extends ConsumerStatefulWidget {
  const EmissionsPrepScreen({super.key});
  @override
  ConsumerState<EmissionsPrepScreen> createState() => _EmissionsPrepScreenState();
}

class _EmissionsPrepScreenState extends ConsumerState<EmissionsPrepScreen> {
  final Map<String, bool> _checklist = {
    'Check engine light off': false,
    'No pending DTCs': false,
    'All monitors complete': false,
    'Fuel cap tight/new': false,
    'Oil recently changed': false,
    'Coolant at proper temp': false,
    'Spark plugs good': false,
    'Air filter clean': false,
    'No vacuum leaks': false,
    'PCV valve working': false,
    'EGR system functional': false,
    'Cat converter intact': false,
  };

  int _readyMonitors = 0;
  int _totalMonitors = 8;

  void _updateMonitors(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 0 && parsed <= _totalMonitors) {
      setState(() { _readyMonitors = parsed; });
    }
  }

  int get _completedItems => _checklist.values.where((v) => v).length;
  double get _readiness => (_completedItems / _checklist.length) * 100;
  double get _monitorReadiness => (_readyMonitors / _totalMonitors) * 100;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Emissions Prep', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildReadinessCard(colors),
            const SizedBox(height: 24),
            _buildMonitorCard(colors),
            const SizedBox(height: 24),
            _buildChecklist(colors),
            const SizedBox(height: 24),
            _buildDriveCycle(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildReadinessCard(ZaftoColors colors) {
    Color statusColor;
    String status;
    if (_readiness >= 90 && _monitorReadiness >= 75) {
      statusColor = colors.accentSuccess;
      status = 'Ready for Testing';
    } else if (_readiness >= 70 || _monitorReadiness >= 50) {
      statusColor = colors.warning;
      status = 'Almost Ready';
    } else {
      statusColor = colors.error;
      status = 'Not Ready';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('EMISSIONS READINESS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Text('${_readiness.toStringAsFixed(0)}%', style: TextStyle(color: statusColor, fontSize: 48, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildMonitorCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OBD-II MONITORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ready Monitors', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text('$_readyMonitors / $_totalMonitors', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            ]),
          ),
          Container(
            width: 100,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0-8',
                hintStyle: TextStyle(color: colors.textTertiary),
              ),
              onChanged: _updateMonitors,
            ),
          ),
        ]),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _monitorReadiness / 100,
          backgroundColor: colors.bgBase,
          valueColor: AlwaysStoppedAnimation<Color>(_monitorReadiness >= 75 ? colors.accentSuccess : colors.warning),
        ),
        const SizedBox(height: 8),
        Text('Most states allow 1-2 incomplete monitors', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildChecklist(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('PRE-TEST CHECKLIST', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          Text('$_completedItems/${_checklist.length}', style: TextStyle(color: colors.accentPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        ..._checklist.entries.map((entry) => _buildCheckItem(colors, entry.key, entry.value)),
      ]),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, String label, bool checked) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _checklist[label] = !checked; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: checked ? colors.accentSuccess : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: checked ? colors.accentSuccess : colors.textTertiary, width: 2),
            ),
            child: checked ? Icon(LucideIcons.check, size: 16, color: colors.bgBase) : null,
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: checked ? colors.textPrimary : colors.textSecondary, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildDriveCycle(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DRIVE CYCLE TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('To complete monitors:', style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text('1. Cold start, idle 2 minutes', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('2. Drive 25 mph for 5 minutes', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('3. Accelerate to 55 mph, cruise 5 min', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('4. Decelerate without braking', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('5. Idle 30 seconds, shut off', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Text('May need 2-3 drive cycles to set all monitors.', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}
