import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// DWV System Overview Diagram - Design System v2.6
class DWVSystemScreen extends ConsumerWidget {
  const DWVSystemScreen({super.key});

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
        title: Text('DWV System Overview', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildSystemDiagram(colors),
            const SizedBox(height: 16),
            _buildComponents(colors),
            const SizedBox(height: 16),
            _buildPipeSizing(colors),
            const SizedBox(height: 16),
            _buildSlopes(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(ZaftoColors colors) {
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
            Icon(LucideIcons.pipette, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('What is DWV?', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          _bulletItem('D = Drain', 'Carries wastewater from fixtures by gravity', colors),
          _bulletItem('W = Waste', 'Removes liquid waste (no solids)', colors),
          _bulletItem('V = Vent', 'Allows air in, prevents siphoning traps', colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('All three systems work together - drain removes waste, vent allows drainage and prevents trap siphoning', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5), decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TYPICAL DWV SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('                    VENT THROUGH ROOF', colors.accentSuccess),
                _diagramLine('                         │', colors.accentSuccess),
                _diagramLine('    ┌─────────────────────┼─────────────────────┐', colors.textTertiary),
                _diagramLine('    │                     │                     │', colors.textTertiary),
                _diagramLine('  [LAV]───┬───────────────┼───────────────┬───[TUB]', colors.accentInfo),
                _diagramLine('    │     │               │               │     │', colors.textTertiary),
                _diagramLine('   P-TRAP │           MAIN VENT          │  P-TRAP', colors.accentWarning),
                _diagramLine('    │     │               │               │     │', colors.textTertiary),
                _diagramLine('    └─────┴───────────────┼───────────────┴─────┘', colors.textTertiary),
                _diagramLine('                          │', colors.textTertiary),
                _diagramLine('                     SOIL STACK', colors.accentError),
                _diagramLine('                          │', colors.textTertiary),
                _diagramLine('  [WC]────────────────────┤', colors.accentInfo),
                _diagramLine('  (toilet)                │', colors.textTertiary),
                _diagramLine('                     BUILDING DRAIN', colors.accentError),
                _diagramLine('                          │', colors.textTertiary),
                _diagramLine('                  ═══════════════════', colors.textSecondary),
                _diagramLine('                    BUILDING SEWER', colors.textSecondary),
                _diagramLine('                     (to municipal)', colors.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }

  Widget _buildComponents(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KEY COMPONENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _componentRow('Soil Stack', 'Vertical drain receiving toilet waste', colors.accentError, colors),
          _componentRow('Waste Stack', 'Vertical drain (no toilet waste)', colors.accentWarning, colors),
          _componentRow('Vent Stack', 'Vertical vent connected to drain stack', colors.accentSuccess, colors),
          _componentRow('Building Drain', 'Horizontal collector under floor', colors.accentError, colors),
          _componentRow('Building Sewer', 'Outside building to public sewer', colors.textSecondary, colors),
          _componentRow('Branch Drain', 'Connects fixtures to main drain', colors.accentInfo, colors),
          _componentRow('Trap', 'Water seal preventing sewer gas', colors.accentWarning, colors),
          _componentRow('Cleanout', 'Access point for clearing clogs', colors.accentPrimary, colors),
        ],
      ),
    );
  }

  Widget _componentRow(String name, String desc, Color dotColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MINIMUM PIPE SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _sizeRow('Lavatory drain', '1-1/4"', colors),
          _sizeRow('Kitchen sink drain', '1-1/2"', colors),
          _sizeRow('Shower drain', '2"', colors),
          _sizeRow('Bathtub drain', '1-1/2"', colors),
          _sizeRow('Toilet drain', '3"', colors),
          _sizeRow('Building drain', '3" (typically 4")', colors),
          _sizeRow('Main vent', '3" (full size)', colors),
          _sizeRow('Individual vent', '1-1/4" min', colors),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Drains cannot reduce in size downstream', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sizeRow(String fixture, String size, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(fixture, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Text(size, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSlopes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.trendingDown, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('DRAIN SLOPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _slopeRow('Pipe 3" and larger', '1/8" per foot', '1%', colors),
          _slopeRow('Pipe under 3"', '1/4" per foot', '2%', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Calculation:', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 4),
                Text('1/4" per foot = 2" drop in 8 feet\n1/8" per foot = 1" drop in 8 feet', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slopeRow(String pipe, String slope, String percent, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(pipe, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
          Expanded(flex: 2, child: Text(slope, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          SizedBox(width: 40, child: Text(percent, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
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
            Text('CODE REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• IPC Chapter 7 - Sanitary Drainage\n'
            '• IPC Chapter 9 - Vents\n'
            '• IPC Table 702.1 - Fixture Unit Values\n'
            '• IPC Table 704.1 - Drain Pipe Sizing\n'
            '• UPC Chapter 7 - Sanitary Drainage\n'
            '• UPC Table 702.1 - DFU Values\n'
            '• UPC Section 704 - Slope Requirements',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
