import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Water Heater Installation Diagram - Design System v2.6
class WaterHeaterInstallScreen extends ConsumerWidget {
  const WaterHeaterInstallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Water Heater Installation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTankDiagram(colors),
            const SizedBox(height: 16),
            _buildConnections(colors),
            const SizedBox(height: 16),
            _buildTprValve(colors),
            const SizedBox(height: 16),
            _buildExpansionTank(colors),
            const SizedBox(height: 16),
            _buildGasRequirements(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTankDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TANK WATER HEATER DIAGRAM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('           FLUE/VENT', colors.textTertiary),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('         ┌────┴────┐', colors.accentWarning),
                _diagramLine('   COLD ─┤         ├─ HOT OUT', colors.accentInfo),
                _diagramLine('   IN    │  ════   │', colors.accentError),
                _diagramLine('  (dip   │  ════   │ ← T&P VALVE', colors.accentError),
                _diagramLine('   tube) │  ════   ├──┐', colors.textTertiary),
                _diagramLine('         │  ════   │  │ T&P DISCHARGE', colors.textTertiary),
                _diagramLine('         │         │  │ (to floor drain', colors.textTertiary),
                _diagramLine('         │ BURNER  │  │  or outside)', colors.textTertiary),
                _diagramLine('         └────┬────┘  ▼', colors.accentWarning),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('         GAS LINE', colors.accentWarning),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('         [VALVE] ← SEDIMENT TRAP', colors.accentPrimary),
                _diagramLine('              │      (drip leg)', colors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnections(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PIPING CONNECTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _connectionRow('Cold water inlet', 'Right side (marked)', 'Has dip tube going to bottom', colors),
          _connectionRow('Hot water outlet', 'Left side (marked)', 'Draws from top of tank', colors),
          _connectionRow('Gas connection', 'Bottom front', '3/4" typically, with shut-off', colors),
          _connectionRow('Flue connection', 'Top center', 'Draft hood for natural draft', colors),
          _connectionRow('T&P valve port', 'Upper side', '3/4" threaded opening', colors),
          _connectionRow('Drain valve', 'Bottom', 'For maintenance draining', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Use dielectric unions when connecting copper to steel tank to prevent galvanic corrosion', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _connectionRow(String name, String location, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
              const Spacer(),
              Text(location, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
            ],
          ),
          Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTprValve(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('T&P (TEMPERATURE & PRESSURE) RELIEF', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('CRITICAL SAFETY DEVICE - Prevents tank explosion', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          _tprRow('Temperature rating', '210°F (99°C)', colors),
          _tprRow('Pressure rating', '150 PSI', colors),
          _tprRow('Discharge pipe size', 'Same as valve outlet (3/4")', colors),
          const SizedBox(height: 12),
          Text('Discharge Pipe Requirements:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _bulletItem('Cannot be smaller than valve outlet', colors),
          _bulletItem('Cannot have valves or restrictions', colors),
          _bulletItem('Must terminate 6" above floor/drain', colors),
          _bulletItem('Cannot be threaded at discharge end', colors),
          _bulletItem('Visible air gap at termination', colors),
          _bulletItem('Slope downward to termination', colors),
        ],
      ),
    );
  }

  Widget _tprRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Text(value, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _bulletItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentError, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildExpansionTank(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.disc, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('EXPANSION TANK', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Required when system has check valve, PRV, or backflow preventer (closed system)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('          ┌──────────┐', colors.accentWarning),
                _diagramLine('          │EXPANSION │', colors.accentWarning),
                _diagramLine('          │  TANK    │', colors.accentWarning),
                _diagramLine('          └────┬─────┘', colors.accentWarning),
                _diagramLine('               │', colors.textTertiary),
                _diagramLine('  COLD IN ─────┼───────────┐', colors.accentInfo),
                _diagramLine('               │           │', colors.textTertiary),
                _diagramLine('          ┌────┴────┐      │', colors.accentWarning),
                _diagramLine('          │  WATER  │      │', colors.accentWarning),
                _diagramLine('          │  HEATER │ HOT ─┘', colors.accentError),
                _diagramLine('          └─────────┘', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Installation:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _expRow('Location', 'Cold water line, close to heater', colors),
          _expRow('Pre-charge', 'Match to system pressure (40-60 PSI)', colors),
          _expRow('Size', 'Based on tank size and temp rise', colors),
          _expRow('Orientation', 'Upright preferred (connection up or down)', colors),
        ],
      ),
    );
  }

  Widget _expRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildGasRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.flame, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('GAS WATER HEATER REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _gasRow('Gas line size', 'Per sizing table (usually 1/2" or 3/4")', colors),
          _gasRow('Shut-off valve', 'Within 6 ft of appliance', colors),
          _gasRow('Sediment trap', '3" min drip leg at valve', colors),
          _gasRow('Connector', 'CSST or approved flex', colors),
          _gasRow('Combustion air', 'Per fuel gas code requirements', colors),
          _gasRow('Vent connector', 'Type B vent, single wall to B', colors),
          _gasRow('Clearance to combustibles', 'Per manufacturer (usually 1")', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Direct vent and power vent units have specific venting requirements - follow manufacturer', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _gasRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCodeRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('CODE REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• IPC/UPC Chapter 5 - Water Heaters\n'
            '• T&P valve required on all storage heaters\n'
            '• Seismic strapping in zones 3+ (2 straps)\n'
            '• Drain pan in locations where leaks cause damage\n'
            '• 18" min from floor in garage (FVIR units exempt)\n'
            '• Expansion tank when closed system\n'
            '• Listed/approved for installation location\n'
            '• Accessible for service and replacement',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
