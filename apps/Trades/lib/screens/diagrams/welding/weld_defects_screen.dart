import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class WeldDefectsScreen extends ConsumerWidget {
  const WeldDefectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Weld Defects',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommonDefects(colors),
            const SizedBox(height: 24),
            _buildCausesAndFixes(colors),
            const SizedBox(height: 24),
            _buildVisualInspection(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonDefects(ZaftoColors colors) {
    final defects = [
      {
        'name': 'Porosity',
        'diagram': '○ ○ ○',
        'desc': 'Gas pockets in weld',
      },
      {
        'name': 'Undercut',
        'diagram': '▔╲▓▓▓╱▔',
        'desc': 'Groove at weld toe',
      },
      {
        'name': 'Lack of Fusion',
        'diagram': '▓│ │▓',
        'desc': 'No fusion to base',
      },
      {
        'name': 'Crack',
        'diagram': '▓▓╱╲▓▓',
        'desc': 'Fracture in weld',
      },
      {
        'name': 'Overlap',
        'diagram': '▓▓▓▔▔',
        'desc': 'Metal over unfused base',
      },
      {
        'name': 'Spatter',
        'diagram': '· ▓▓▓ ·',
        'desc': 'Metal drops around weld',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 24),
              const SizedBox(width: 12),
              Text(
                'Common Weld Defects',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: defects.map((d) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['name']!, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.bold, fontSize: 12)),
                  const Spacer(),
                  Center(
                    child: Text(
                      d['diagram']!,
                      style: TextStyle(color: colors.textTertiary, fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                  const Spacer(),
                  Text(d['desc']!, style: TextStyle(color: colors.textSecondary, fontSize: 10)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCausesAndFixes(ZaftoColors colors) {
    final issues = [
      {
        'defect': 'Porosity',
        'causes': 'Contamination, wet electrode, wind, wrong gas',
        'fixes': 'Clean metal, dry electrodes, shield from wind',
      },
      {
        'defect': 'Undercut',
        'causes': 'Too much heat, wrong angle, too fast',
        'fixes': 'Reduce amperage, correct angle, slow down',
      },
      {
        'defect': 'Lack of Fusion',
        'causes': 'Cold weld, wrong angle, oxide layer',
        'fixes': 'Increase heat, direct arc at joint, clean metal',
      },
      {
        'defect': 'Cracking',
        'causes': 'Fast cooling, high carbon, stress',
        'fixes': 'Preheat, post-heat, reduce restraint',
      },
      {
        'defect': 'Overlap',
        'causes': 'Too slow travel, wrong angle',
        'fixes': 'Increase speed, adjust angle',
      },
      {
        'defect': 'Spatter',
        'causes': 'Voltage too high, arc too long, contamination',
        'fixes': 'Reduce voltage, shorten arc, clean metal',
      },
      {
        'defect': 'Burn Through',
        'causes': 'Too much heat, slow travel, thin material',
        'fixes': 'Reduce amperage, increase speed, use backing',
      },
      {
        'defect': 'Slag Inclusion',
        'causes': 'Poor slag removal, wrong angle, cold weld',
        'fixes': 'Clean between passes, correct angle, more heat',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wrench, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Causes & Corrections',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...issues.map((i) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i['defect']!, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.helpCircle, color: colors.textTertiary, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(i['causes']!, style: TextStyle(color: colors.textSecondary, fontSize: 10))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 12),
                    const SizedBox(width: 4),
                    Expanded(child: Text(i['fixes']!, style: TextStyle(color: colors.accentSuccess, fontSize: 10))),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildVisualInspection(ZaftoColors colors) {
    final checks = [
      {'item': 'Weld size', 'criteria': 'Meets drawing specs'},
      {'item': 'Weld length', 'criteria': 'Complete, no short welds'},
      {'item': 'Undercut', 'criteria': 'Max 1/32" (per code)'},
      {'item': 'Overlap', 'criteria': 'None acceptable'},
      {'item': 'Cracks', 'criteria': 'None acceptable'},
      {'item': 'Porosity', 'criteria': 'Per code limits'},
      {'item': 'Spatter', 'criteria': 'Minimal, remove before finish'},
      {'item': 'Arc strikes', 'criteria': 'None outside weld zone'},
      {'item': 'Crater', 'criteria': 'Filled, no crater cracks'},
      {'item': 'Profile', 'criteria': 'Smooth, proper contour'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.search, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Visual Inspection Checklist',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...checks.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(LucideIcons.checkSquare, color: colors.accentInfo, size: 16),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: Text(c['item']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(c['criteria']!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
