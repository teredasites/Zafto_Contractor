import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Venting Types Diagram - Design System v2.6
class VentingTypesScreen extends ConsumerWidget {
  const VentingTypesScreen({super.key});

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
        title: Text('Venting Types', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWhyVent(colors),
            const SizedBox(height: 16),
            _buildIndividualVent(colors),
            const SizedBox(height: 16),
            _buildCommonVent(colors),
            const SizedBox(height: 16),
            _buildWetVent(colors),
            const SizedBox(height: 16),
            _buildCircuitVent(colors),
            const SizedBox(height: 16),
            _buildAAV(colors),
            const SizedBox(height: 16),
            _buildVentTermination(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyVent(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('Why Venting is Required', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          _bulletItem('Prevents trap siphonage', 'Air behind water prevents vacuum', colors),
          _bulletItem('Prevents back pressure', 'Allows air escape when water flows', colors),
          _bulletItem('Removes sewer gases', 'Vents gases safely above roof', colors),
          _bulletItem('Ensures proper drainage', 'Air allows water to flow freely', colors),
        ],
      ),
    );
  }

  Widget _bulletItem(String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualVent(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentSuccess, borderRadius: BorderRadius.circular(4)),
              child: Text('1', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 10),
            Text('INDIVIDUAL VENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Each fixture has its own dedicated vent', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('          TO ROOF', colors.accentSuccess),
                _diagramLine('             │', colors.accentSuccess),
                _diagramLine('             │ VENT', colors.accentSuccess),
                _diagramLine('  [FIXTURE]──┤', colors.accentInfo),
                _diagramLine('     │       │', colors.textTertiary),
                _diagramLine('   TRAP      │', colors.accentWarning),
                _diagramLine('     │       │', colors.textTertiary),
                _diagramLine('     └───────┴──── TO DRAIN', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoItem('Best protection - dedicated airflow for each fixture', colors),
          _infoItem('Vent must connect within 2× pipe diameter of trap', colors),
        ],
      ),
    );
  }

  Widget _buildCommonVent(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentInfo, borderRadius: BorderRadius.circular(4)),
              child: Text('2', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 10),
            Text('COMMON VENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Two fixtures share one vent (back-to-back)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('              TO ROOF', colors.accentSuccess),
                _diagramLine('                 │', colors.accentSuccess),
                _diagramLine('   [LAV]────┬────┼────┬────[LAV]', colors.accentInfo),
                _diagramLine('     │      │    │    │      │', colors.textTertiary),
                _diagramLine('   TRAP     │ COMMON │    TRAP', colors.accentWarning),
                _diagramLine('     │      │  VENT  │      │', colors.textTertiary),
                _diagramLine('     └──────┴────┬───┴──────┘', colors.textTertiary),
                _diagramLine('                 │', colors.textTertiary),
                _diagramLine('            TO DRAIN', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoItem('Fixtures must be same floor level', colors),
          _infoItem('Must connect at same level (double wye or sanitary cross)', colors),
        ],
      ),
    );
  }

  Widget _buildWetVent(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentWarning, borderRadius: BorderRadius.circular(4)),
              child: Text('3', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 10),
            Text('WET VENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Drain pipe also serves as vent for downstream fixture', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('         TO ROOF', colors.accentSuccess),
                _diagramLine('            │', colors.accentSuccess),
                _diagramLine('  [LAV]─────┤ (dry vent above)', colors.accentInfo),
                _diagramLine('    │       │', colors.textTertiary),
                _diagramLine('  TRAP      │ WET VENT PORTION', colors.accentWarning),
                _diagramLine('    │       │ (serves as vent', colors.accentWarning),
                _diagramLine('    └───────┤  for toilet below)', colors.textTertiary),
                _diagramLine('            │', colors.textTertiary),
                _diagramLine('  [WC]──────┤', colors.accentInfo),
                _diagramLine('            │', colors.textTertiary),
                _diagramLine('       TO DRAIN', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoItem('Wet vent must be 2" min (1 or 2 fixtures)', colors),
          _infoItem('Wet vent section has size requirements per fixture count', colors),
          _infoItem('Common in bathroom groups', colors),
        ],
      ),
    );
  }

  Widget _buildCircuitVent(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: colors.accentError, borderRadius: BorderRadius.circular(4)),
              child: Text('4', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const SizedBox(width: 10),
            Text('CIRCUIT / LOOP VENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('One vent serves multiple fixtures on horizontal branch', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('                    TO ROOF', colors.accentSuccess),
                _diagramLine('                       │', colors.accentSuccess),
                _diagramLine('[F1]──[F2]──[F3]──[F4]──┤', colors.accentInfo),
                _diagramLine(' │     │     │     │   │', colors.textTertiary),
                _diagramLine(' └─────┴─────┴─────┴───┴──── TO STACK', colors.accentError),
                _diagramLine('                  ▲', colors.textTertiary),
                _diagramLine('        Circuit vent connects', colors.textTertiary),
                _diagramLine('       between last 2 fixtures', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _infoItem('Max 8 fixtures on circuit vent', colors),
          _infoItem('Vent connects between last 2 fixtures', colors),
          _infoItem('Common in commercial bathroom rows', colors),
        ],
      ),
    );
  }

  Widget _buildAAV(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.disc, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('AIR ADMITTANCE VALVE (AAV)', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Mechanical device allowing air in but not out', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('         ┌─────┐', colors.accentWarning),
                _diagramLine('         │ AAV │ (opens when negative', colors.accentWarning),
                _diagramLine('         └──┬──┘  pressure occurs)', colors.accentWarning),
                _diagramLine('            │', colors.textTertiary),
                _diagramLine('  [FIXTURE]─┤  Min 4" above trap', colors.accentInfo),
                _diagramLine('     │      │', colors.textTertiary),
                _diagramLine('   TRAP     │', colors.accentWarning),
                _diagramLine('     │      │', colors.textTertiary),
                _diagramLine('     └──────┴──── TO DRAIN', colors.accentError),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('AAV Requirements:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _infoItem('Must be accessible (not buried in wall)', colors),
          _infoItem('Min 4" above flood rim or trap weir', colors),
          _infoItem('Within max developed length of trap arm', colors),
          _infoItem('Not allowed by all codes - check local AHJ', colors),
          _infoItem('At least one full vent to atmosphere required per building', colors),
        ],
      ),
    );
  }

  Widget _buildVentTermination(ZaftoColors colors) {
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
            Icon(LucideIcons.home, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('VENT TERMINATION', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Min 6" above roof surface\n'
            '• Min 10 ft from any air intake\n'
            '• Min 3 ft from any openable window\n'
            '• Min 10 ft horizontal + 2 ft above window if within 10 ft\n'
            '• In snow areas: extend above expected snow level\n'
            '• Cannot terminate under eave/overhang\n'
            '• Cannot reduce in size toward roof',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Text('IPC 903.1, UPC 906', style: TextStyle(color: colors.accentInfo, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
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
}
