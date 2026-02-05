import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// PEX Manifold System Diagram - Design System v2.6
class PexManifoldScreen extends ConsumerWidget {
  const PexManifoldScreen({super.key});

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
        title: Text('PEX Manifold Systems', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildManifoldDiagram(colors),
            const SizedBox(height: 16),
            _buildTrunkBranch(colors),
            const SizedBox(height: 16),
            _buildComparison(colors),
            const SizedBox(height: 16),
            _buildConnectionTypes(colors),
            const SizedBox(height: 16),
            _buildInstallationTips(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildManifoldDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.gitBranch, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('HOME RUN (MANIFOLD) SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('Each fixture gets dedicated line from central manifold', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('WATER ─────┬───────────────────┬───── HOT', colors.accentInfo),
                _diagramLine('HEATER     │                   │      MANIFOLD', colors.accentError),
                _diagramLine('           │                   │', colors.textTertiary),
                _diagramLine('        ┌──┴──┐             ┌──┴──┐', colors.accentInfo),
                _diagramLine('        │COLD │             │ HOT │', colors.accentInfo),
                _diagramLine('        │MANIF│             │MANIF│', colors.accentError),
                _diagramLine('        └┬┬┬┬┬┘             └┬┬┬┬┬┘', colors.textTertiary),
                _diagramLine('         │││││               │││││', colors.textTertiary),
                _diagramLine('         │││││  Individual   │││││', colors.textTertiary),
                _diagramLine('         │││││  home runs    │││││', colors.textTertiary),
                _diagramLine('         ▼▼▼▼▼  to fixtures  ▼▼▼▼▼', colors.textTertiary),
                _diagramLine('        [Fixtures have dedicated H&C lines]', colors.accentPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _featureRow('Individual shut-offs', 'Each fixture can be isolated at manifold', colors),
          _featureRow('Continuous runs', 'No joints in walls - fewer leak points', colors),
          _featureRow('Fast hot water', 'Smaller lines = less water to flush', colors),
        ],
      ),
    );
  }

  Widget _featureRow(String title, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrunkBranch(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRUNK & BRANCH SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Traditional system - main line with branches to fixtures', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('MAIN ═══════════════════════════════════►', colors.accentInfo),
                _diagramLine('            │       │       │       │', colors.textTertiary),
                _diagramLine('           3/4"    TEE     TEE     TEE', colors.textTertiary),
                _diagramLine('            │       │       │       │', colors.textTertiary),
                _diagramLine('           1/2"   1/2"    1/2"    1/2"', colors.accentPrimary),
                _diagramLine('            │       │       │       │', colors.textTertiary),
                _diagramLine('          [LAV]  [TUB]  [TOILET] [SHOWER]', colors.accentPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _featureRow('Less material', 'Shorter total pipe runs', colors),
          _featureRow('More fittings', 'Tees at each branch point', colors),
          _featureRow('No central control', 'Must trace pipes to shut off', colors),
        ],
      ),
    );
  }

  Widget _buildComparison(ZaftoColors colors) {
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
          Text('SYSTEM COMPARISON', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _compareRow('Feature', 'Home Run', 'Trunk & Branch', colors, header: true),
          _compareRow('Material cost', 'Higher', 'Lower', colors),
          _compareRow('Fitting count', 'Fewer', 'More', colors),
          _compareRow('Leak potential', 'Lower', 'Higher', colors),
          _compareRow('Hot water wait', 'Less', 'More', colors),
          _compareRow('Pressure balance', 'Better', 'Variable', colors),
          _compareRow('Serviceability', 'Excellent', 'Good', colors),
          _compareRow('Best for', 'New construction', 'Retrofits', colors),
        ],
      ),
    );
  }

  Widget _compareRow(String feature, String manifold, String trunk, ZaftoColors colors, {bool header = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(feature, style: TextStyle(color: header ? colors.accentPrimary : colors.textPrimary, fontWeight: header ? FontWeight.w700 : FontWeight.w600, fontSize: 11))),
          Expanded(flex: 2, child: Text(manifold, style: TextStyle(color: header ? colors.accentPrimary : colors.textSecondary, fontWeight: header ? FontWeight.w700 : FontWeight.normal, fontSize: 11))),
          Expanded(flex: 2, child: Text(trunk, style: TextStyle(color: header ? colors.accentPrimary : colors.textSecondary, fontWeight: header ? FontWeight.w700 : FontWeight.normal, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildConnectionTypes(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PEX CONNECTION METHODS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _connectionRow('Crimp', 'Copper crimp ring + tool', 'Most common, reliable', colors),
          _connectionRow('Clamp', 'Stainless steel cinch clamp', 'Easy to remove, all temps', colors),
          _connectionRow('Expansion', 'Cold expansion + ring', 'PEX-A only, reliable', colors),
          _connectionRow('Push-fit', 'SharkBite type', 'Easy but expensive', colors),
          _connectionRow('Press', 'Copper press fitting', 'Fast, expensive tool', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Never mix PEX types with wrong fittings - PEX-A expansion fittings only for PEX-A', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _connectionRow(String type, String method, String notes, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(type, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                Text(notes, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.lightbulb, color: colors.accentSuccess, size: 18),
            const SizedBox(width: 8),
            Text('INSTALLATION TIPS', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• Support PEX every 32" horizontal, 4 ft vertical\n'
            '• Keep PEX away from heat sources\n'
            '• Protect from UV light (not for outdoor use)\n'
            '• Use proper bend supports at turns\n'
            '• Min bend radius = 6× pipe diameter\n'
            '• Label hot/cold at manifold\n'
            '• Use brass manifolds (not plastic)\n'
            '• Leave 12" slack at connections\n'
            '• Protect in concrete with sleeve\n'
            '• Use nail plates through studs',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
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
            Text('CODE & STANDARDS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• PEX tubing: ASTM F876, F877\n'
            '• Fittings: ASTM F1807, F2159, F2080\n'
            '• IPC Section 605.4 - PEX installation\n'
            '• Support intervals per Table 605.4\n'
            '• Thermal expansion compensation required\n'
            '• Manifolds: ASSE 1061 standard\n'
            '• Check local code for PEX approval',
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
