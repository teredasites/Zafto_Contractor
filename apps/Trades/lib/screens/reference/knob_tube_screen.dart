/// Knob & Tube Wiring Reference - Design System v2.6
/// Historical wiring system identification and safety
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class KnobTubeScreen extends ConsumerWidget {
  const KnobTubeScreen({super.key});

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
        title: Text('Knob & Tube Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarning(colors),
            const SizedBox(height: 16),
            _buildWhatIsIt(colors),
            const SizedBox(height: 16),
            _buildIdentification(colors),
            const SizedBox(height: 16),
            _buildDangers(colors),
            const SizedBox(height: 16),
            _buildCanYouUse(colors),
            const SizedBox(height: 16),
            _buildRecommendations(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentError, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text('OUTDATED WIRING SYSTEM', style: TextStyle(color: colors.accentError, fontSize: 16, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Knob & tube wiring was installed 1880s-1940s. While not inherently dangerous when properly maintained, it lacks grounding, has degraded insulation, and is often overloaded. Many insurance companies refuse coverage.',
            style: TextStyle(color: colors.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatIsIt(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is Knob & Tube?', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('     JOIST                    JOIST', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('  ════════                 ════════', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('      │                       │', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('   ┌──┴──┐                 ┌──┴──┐', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('   │KNOB │ ─── HOT ─────  │KNOB │', style: TextStyle(color: colors.accentError, fontFamily: 'monospace', fontSize: 10)),
                Text('   └─────┘   (separate)   └─────┘', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('', style: TextStyle(fontFamily: 'monospace', fontSize: 6)),
                Text('   ┌─────┐                ┌─────┐', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('   │KNOB │ ─ NEUTRAL ───  │KNOB │', style: TextStyle(color: colors.textPrimary, fontFamily: 'monospace', fontSize: 10)),
                Text('   └──┬──┘   (separate)   └──┬──┘', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('      │                       │', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
                Text('  ════════                 ════════', style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('• Porcelain KNOBS support wires along joists', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Porcelain TUBES protect wires through framing', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Hot and neutral run SEPARATELY (air cooling)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Rubber or cloth insulation on conductors', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• NO GROUND WIRE', style: TextStyle(color: colors.accentWarning, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildIdentification(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to Identify K&T', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _idRow('Attic/basement', 'Look for porcelain knobs on joists', colors),
          _idRow('Wire insulation', 'Black rubber or cloth-wrapped', colors),
          _idRow('Wire runs', 'Hot and neutral separated by 4-6"', colors),
          _idRow('Junction points', 'Soldered and taped (no wire nuts)', colors),
          _idRow('Outlets', '2-prong only, no ground', colors),
          _idRow('Fuse box', 'Old screw-in fuses, 60A service typical', colors),
        ],
      ),
    );
  }

  Widget _idRow(String where, String what, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(where, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(what, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildDangers(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 18),
              const SizedBox(width: 8),
              Text('Hazards & Problems', style: TextStyle(color: colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _dangerRow('Insulation breakdown', 'Rubber/cloth cracks after 80+ years', colors),
          _dangerRow('No ground', 'Shock hazard, can\'t use 3-prong', colors),
          _dangerRow('Overloaded circuits', 'Original 15A not enough for modern loads', colors),
          _dangerRow('Insulation burial', 'K&T MUST have air space - blown-in insulation is fire hazard', colors),
          _dangerRow('Amateur splices', 'Previous owners\' bad repairs', colors),
          _dangerRow('Insurance issues', 'Many companies won\'t insure or charge premium', colors),
        ],
      ),
    );
  }

  Widget _dangerRow(String danger, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertCircle, color: colors.accentWarning, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: '$danger: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                TextSpan(text: detail, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanYouUse(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Can You Still Use It?', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text('NEC does NOT require removal of existing K&T. However:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 12)),
          const SizedBox(height: 8),
          Text('• Cannot extend or add to K&T circuits', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Cannot bury in insulation without inspection', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• Must be in good condition (no damaged insulation)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text('• New circuits must be modern NM/conduit', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 16, color: colors.accentPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: GFCI protection can be added to ungrounded K&T outlets. Install GFCI at first outlet and label downstream outlets "No Equipment Ground".',
                    style: TextStyle(color: colors.accentPrimary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 18),
              const SizedBox(width: 8),
              Text('Recommendations', style: TextStyle(color: colors.accentSuccess, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• Get professional inspection before buying K&T home\n'
            '• Budget for full rewire (\$8,000-\$20,000+ typical)\n'
            '• Partial rewire: prioritize kitchen, bath, heavy loads\n'
            '• Add GFCI/AFCI protection where possible\n'
            '• Never cover K&T with blown-in insulation\n'
            '• Document everything for insurance purposes\n'
            '• Consider rewire during renovation (walls open)',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
