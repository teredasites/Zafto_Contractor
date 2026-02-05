import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// ABS Troubleshooting Guide - Common codes and diagnostics
class AbsTroubleshootScreen extends ConsumerStatefulWidget {
  const AbsTroubleshootScreen({super.key});
  @override
  ConsumerState<AbsTroubleshootScreen> createState() => _AbsTroubleshootScreenState();
}

class _AbsTroubleshootScreenState extends ConsumerState<AbsTroubleshootScreen> {
  String? _selectedCode;

  final Map<String, Map<String, String>> _absCodesInfo = {
    'C0035': {'name': 'LF Wheel Speed Sensor', 'cause': 'Damaged sensor, wiring, or tone ring', 'fix': 'Check sensor gap, inspect wiring, clean tone ring'},
    'C0040': {'name': 'RF Wheel Speed Sensor', 'cause': 'Damaged sensor, wiring, or tone ring', 'fix': 'Check sensor gap, inspect wiring, clean tone ring'},
    'C0045': {'name': 'LR Wheel Speed Sensor', 'cause': 'Damaged sensor, wiring, or tone ring', 'fix': 'Check sensor gap, inspect wiring, clean tone ring'},
    'C0050': {'name': 'RR Wheel Speed Sensor', 'cause': 'Damaged sensor, wiring, or tone ring', 'fix': 'Check sensor gap, inspect wiring, clean tone ring'},
    'C0060': {'name': 'ABS Motor Circuit', 'cause': 'Pump motor failure, relay, or wiring', 'fix': 'Test pump motor, check relay and fuse'},
    'C0065': {'name': 'Brake Switch Circuit', 'cause': 'Faulty brake switch or wiring', 'fix': 'Adjust or replace brake light switch'},
    'C0070': {'name': 'ABS Control Module', 'cause': 'Internal module failure', 'fix': 'Module replacement may be required'},
    'C0080': {'name': 'System Voltage', 'cause': 'Low battery or charging issue', 'fix': 'Test battery and alternator output'},
    'C0110': {'name': 'Pump Motor Running Too Long', 'cause': 'Fluid leak or air in system', 'fix': 'Check for leaks, bleed ABS system'},
    'C0121': {'name': 'Valve Relay Circuit', 'cause': 'Relay failure or wiring', 'fix': 'Test relay, check connections'},
  };

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() { _selectedCode = null; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('ABS Troubleshoot', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('COMMON ABS CODES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ..._absCodesInfo.entries.map((e) => _buildCodeCard(colors, e.key, e.value)),
            const SizedBox(height: 24),
            _buildDiagnosticsCard(colors),
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
        Text('ABS Code Reference & Diagnostics', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Tap code for detailed troubleshooting info', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildCodeCard(ZaftoColors colors, String code, Map<String, String> info) {
    final isSelected = _selectedCode == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedCode = isSelected ? null : code),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary.withValues(alpha: 0.1) : colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(code, style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
            Icon(isSelected ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 20, color: colors.textSecondary),
          ]),
          Text(info['name']!, style: TextStyle(color: colors.textPrimary, fontSize: 14)),
          if (isSelected) ...[
            const SizedBox(height: 12),
            _buildInfoRow(colors, 'Cause', info['cause']!),
            const SizedBox(height: 8),
            _buildInfoRow(colors, 'Fix', info['fix']!),
          ],
        ]),
      ),
    );
  }

  Widget _buildInfoRow(ZaftoColors colors, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 50, child: Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
    ]);
  }

  Widget _buildDiagnosticsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BASIC DIAGNOSTICS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('1. Check brake fluid level\n2. Inspect wheel speed sensors for damage/debris\n3. Verify tone rings are intact\n4. Test battery voltage (12.4V+ at rest)\n5. Scan for codes with OBD2 scanner\n6. Check fuses and relays\n7. Inspect wiring for damage or corrosion', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6)),
      ]),
    );
  }
}
