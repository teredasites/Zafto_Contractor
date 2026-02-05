import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Under-Cabinet Lighting Wiring Diagram - Design System v2.6
class UnderCabinetScreen extends ConsumerWidget {
  const UnderCabinetScreen({super.key});

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
        title: Text('Under-Cabinet Lighting', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypes(colors),
            const SizedBox(height: 16),
            _buildHardwiredWiring(colors),
            const SizedBox(height: 16),
            _buildPlugInWiring(colors),
            const SizedBox(height: 16),
            _buildLowVoltage(colors),
            const SizedBox(height: 16),
            _buildInstallTips(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.lightbulb, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('UNDER-CABINET LIGHT TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _typeRow('LED Strip/Tape', '12V or 24V DC', 'Flexible, cuttable, needs driver', colors),
          _typeRow('LED Light Bar', '120V or 12V', 'Rigid, linkable, easy install', colors),
          _typeRow('Puck Lights', '120V or 12V', 'Spot lighting, can be recessed', colors),
          _typeRow('Fluorescent', '120V', 'Older style, T5/T8 tubes', colors),
          _typeRow('Xenon/Halogen', '12V or 120V', 'Warm light, runs hot', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.leaf, color: colors.accentSuccess, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('LED is now standard - efficient, cool running, long life', style: TextStyle(color: colors.accentSuccess, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _typeRow(String type, String voltage, String notes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 95, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
        SizedBox(width: 75, child: Text(voltage, style: TextStyle(color: colors.accentPrimary, fontSize: 10))),
        Expanded(child: Text(notes, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
      ]),
    );
  }

  Widget _buildHardwiredWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HARDWIRED 120V INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('SWITCH ──► J-BOX (in wall) ──► LIGHT BAR 1', colors.accentPrimary),
                _diagramLine('                │                   │', colors.textTertiary),
                _diagramLine('                │              LIGHT BAR 2', colors.accentPrimary),
                _diagramLine('                │                   │', colors.textTertiary),
                _diagramLine('             (behind             LIGHT BAR 3', colors.textTertiary),
                _diagramLine('              cabinet)', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Run 14/2 NM from switch to J-box behind cabinet', colors),
          _infoItem('J-box must remain accessible', colors),
          _infoItem('Use direct-wire LED bars with knockout connections', colors),
          _infoItem('Link bars with included connectors', colors),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _infoItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildPlugInWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLUG-IN INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('OUTLET ──► LIGHT BAR (with cord/plug)', colors.accentPrimary),
                _diagramLine('  (above        │', colors.textTertiary),
                _diagramLine('   counter)  ───┴─── Link to more bars', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('Easiest install - no electrical work', colors),
          _infoItem('Use outlet behind cabinet or above counter', colors),
          _infoItem('Hide cord in channel or behind trim', colors),
          _infoItem('Can add inline switch on cord', colors),
        ],
      ),
    );
  }

  Widget _buildLowVoltage(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.zap, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('LOW VOLTAGE LED STRIP (12V/24V)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('120V ──► LED DRIVER ──► LED STRIP', colors.accentPrimary),
                _diagramLine('         (transformer)    (12V or 24V DC)', colors.textTertiary),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('         Can be in        Cut at marks,', colors.textTertiary),
                _diagramLine('         cabinet or       solder or use', colors.textTertiary),
                _diagramLine('         remote loc       connectors', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.calculator, color: colors.accentPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Driver sizing: Total watts / 0.8 = driver watts needed', style: TextStyle(color: colors.accentPrimary, fontSize: 12))),
            ]),
          ),
          const SizedBox(height: 10),
          _infoItem('Keep driver accessible and ventilated', colors),
          _infoItem('Use correct voltage strip for driver', colors),
          _infoItem('24V better for long runs (less voltage drop)', colors),
          _infoItem('Dimmable drivers for dimming capability', colors),
        ],
      ),
    );
  }

  Widget _buildInstallTips(ZaftoColors colors) {
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
            Icon(LucideIcons.lightbulb, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('INSTALLATION TIPS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Mount toward FRONT of cabinet (not back)\n'
            '• Use lens/diffuser to reduce hot spots\n'
            '• 3000K-3500K for warm kitchen light\n'
            '• 4000K-5000K for task/work areas\n'
            '• CRI 90+ for accurate food colors\n'
            '• Add trim/valance to hide light source\n'
            '• Wire before backsplash install if possible\n'
            '• Consider smart switch for dimming/control',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
