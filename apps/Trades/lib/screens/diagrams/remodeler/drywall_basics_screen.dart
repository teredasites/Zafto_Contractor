import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class DrywallBasicsScreen extends ConsumerWidget {
  const DrywallBasicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Drywall Basics',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDrywallTypes(colors),
            const SizedBox(height: 24),
            _buildInstallationPattern(colors),
            const SizedBox(height: 24),
            _buildFasteningSchedule(colors),
            const SizedBox(height: 24),
            _buildFinishLevels(colors),
            const SizedBox(height: 24),
            _buildTapingProcess(colors),
            const SizedBox(height: 24),
            _buildCommonMistakes(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDrywallTypes(ZaftoColors colors) {
    final types = [
      {'type': 'Regular (White)', 'thickness': '1/2", 5/8"', 'use': 'Standard walls/ceilings', 'color': Colors.white},
      {'type': 'Moisture Resistant (Green)', 'thickness': '1/2", 5/8"', 'use': 'Bathrooms, kitchens', 'color': Colors.green},
      {'type': 'Fire Resistant (Type X)', 'thickness': '5/8"', 'use': 'Garage walls, fire walls', 'color': Colors.pink},
      {'type': 'Mold Resistant (Purple)', 'thickness': '1/2", 5/8"', 'use': 'High humidity areas', 'color': Colors.purple},
      {'type': 'Soundproof', 'thickness': '5/8"', 'use': 'Between units, media rooms', 'color': Colors.blue},
      {'type': 'Cement Board', 'thickness': '1/4", 1/2"', 'use': 'Tile backing, wet areas', 'color': Colors.grey},
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
              Icon(LucideIcons.layers, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Drywall Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...types.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: t['color'] as Color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['type'] as String,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        t['use'] as String,
                        style: TextStyle(color: colors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Text(
                  t['thickness'] as String,
                  style: TextStyle(color: colors.accentInfo, fontSize: 11),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInstallationPattern(ZaftoColors colors) {
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
              Icon(LucideIcons.layoutGrid, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Installation Patterns',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgInset,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('CEILING', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(
                        '''┌────┬────┬────┐
│    │    │    │
├────┼────┼────┤
│    │    │    │
└────┴────┴────┘
Perpendicular to
joists preferred''',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgInset,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('WALLS', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.bold, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(
                        '''┌──────────────┐
│              │
├──────────────┤
│              │
└──────────────┘
Horizontal for
8'+ ceilings''',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Installation Order:', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 8),
                Text(
                  '1. Ceilings first\n2. Upper wall sheets\n3. Lower wall sheets (1/2" off floor)\n4. Stagger joints, avoid aligning with door/window corners',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFasteningSchedule(ZaftoColors colors) {
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
              Icon(LucideIcons.hammer, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fastening Schedule',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''SCREW SPACING

CEILING:           WALLS:
  ↓   ↓   ↓          ↓   ↓   ↓
←12"→←12"→        ←16"→←16"→
  │   │   │          │   │   │
  ↓   ↓   ↓          ↓   ↓   ↓
←12"→←12"→        ←16"→←16"→

Field: 12" ceiling, 16" walls
Edges: 8" on center
End joints: Back-block or floating

SCREW DEPTH
  ┌─────────────┐
  │  DRYWALL    │
  │═════════════│ ← Paper intact
  │   ◯←dimpled │   (slightly below)
  │   │         │
  │  STUD       │''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildFasteningNote(colors, 'Screw length', '1-1/4" for 1/2", 1-5/8" for 5/8"'),
          _buildFasteningNote(colors, 'Edge distance', '3/8" min from edges'),
          _buildFasteningNote(colors, 'Dimple depth', 'Just below surface, paper intact'),
          _buildFasteningNote(colors, 'Adhesive option', 'Reduces screws to 16" field'),
        ],
      ),
    );
  }

  Widget _buildFasteningNote(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(LucideIcons.chevronRight, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishLevels(ZaftoColors colors) {
    final levels = [
      {'level': '0', 'name': 'None', 'use': 'Temporary, hidden areas', 'work': 'Tape joints only'},
      {'level': '1', 'name': 'Fire tape', 'use': 'Above ceilings, plenums', 'work': 'Embed tape, no finish'},
      {'level': '2', 'name': 'Substrate', 'use': 'Tile backing, garages', 'work': 'One coat over tape'},
      {'level': '3', 'name': 'Texture', 'use': 'Heavy/medium texture', 'work': 'Two coats, tool marks OK'},
      {'level': '4', 'name': 'Light texture', 'use': 'Light texture, flat paint', 'work': 'Three coats, smooth'},
      {'level': '5', 'name': 'Premium', 'use': 'Gloss paint, critical light', 'work': 'Skim coat entire surface'},
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
              Icon(LucideIcons.paintbrush, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Finish Levels (GA-214)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...levels.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: l['level'] == '4' || l['level'] == '5'
                    ? colors.accentSuccess.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      l['level'] as String,
                      style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l['name'] as String,
                        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        l['use'] as String,
                        style: TextStyle(color: colors.textTertiary, fontSize: 10),
                      ),
                      Text(
                        l['work'] as String,
                        style: TextStyle(color: colors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTapingProcess(ZaftoColors colors) {
    final steps = [
      {'step': '1', 'name': 'Tape coat', 'tool': '5" knife', 'dry': '24 hrs', 'desc': 'Embed tape in mud'},
      {'step': '2', 'name': 'Block coat', 'tool': '8" knife', 'dry': '24 hrs', 'desc': 'Fill over tape'},
      {'step': '3', 'name': 'Skim coat', 'tool': '10-12" knife', 'dry': '24 hrs', 'desc': 'Feather edges'},
      {'step': '4', 'name': 'Sand', 'tool': '150-220 grit', 'dry': 'N/A', 'desc': 'Smooth, check with light'},
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
              Icon(LucideIcons.listOrdered, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Taping Process',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.accentInfo,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      s['step'] as String,
                      style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s['name'] as String,
                            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            s['tool'] as String,
                            style: TextStyle(color: colors.accentWarning, fontSize: 10),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s['desc'] as String,
                            style: TextStyle(color: colors.textSecondary, fontSize: 10),
                          ),
                          Text(
                            'Dry: ${s['dry']}',
                            style: TextStyle(color: colors.textTertiary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCommonMistakes(ZaftoColors colors) {
    final mistakes = [
      {'mistake': 'Screws too deep', 'fix': 'Paper should be intact, just dimpled'},
      {'mistake': 'Butt joints aligned', 'fix': 'Stagger joints, never align vertically'},
      {'mistake': 'Insufficient drying', 'fix': 'Wait 24 hrs between coats'},
      {'mistake': 'Too much mud', 'fix': 'Multiple thin coats, not thick'},
      {'mistake': 'Poor feathering', 'fix': 'Blend 6-8" beyond joint'},
      {'mistake': 'Skipping primer', 'fix': 'Always prime before painting'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertCircle, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Mistakes',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...mistakes.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(LucideIcons.x, color: colors.accentError, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(m['mistake']!, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
                Icon(LucideIcons.arrowRight, color: colors.textTertiary, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(m['fix']!, style: TextStyle(color: colors.accentSuccess, fontSize: 11))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
