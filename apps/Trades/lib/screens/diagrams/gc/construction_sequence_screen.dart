import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class ConstructionSequenceScreen extends ConsumerWidget {
  const ConstructionSequenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Construction Sequence',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(colors),
            const SizedBox(height: 24),
            _buildPhaseTimeline(colors),
            const SizedBox(height: 24),
            _buildPreConstruction(colors),
            const SizedBox(height: 24),
            _buildFoundationPhase(colors),
            const SizedBox(height: 24),
            _buildFramingPhase(colors),
            const SizedBox(height: 24),
            _buildMEPRough(colors),
            const SizedBox(height: 24),
            _buildFinishPhase(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(ZaftoColors colors) {
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
              Icon(LucideIcons.listOrdered, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Construction Sequence Overview',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Residential construction follows a specific sequence to ensure each phase is complete before dependent work begins. Understanding this sequence helps coordinate subcontractors and inspections.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTimeline(ZaftoColors colors) {
    final phases = [
      {'name': 'Pre-Construction', 'duration': '2-4 weeks', 'color': colors.accentInfo},
      {'name': 'Site Work', 'duration': '1-2 weeks', 'color': colors.accentWarning},
      {'name': 'Foundation', 'duration': '2-3 weeks', 'color': colors.accentError},
      {'name': 'Framing', 'duration': '2-4 weeks', 'color': colors.accentPrimary},
      {'name': 'MEP Rough', 'duration': '2-3 weeks', 'color': colors.accentSuccess},
      {'name': 'Insulation/Drywall', 'duration': '2-3 weeks', 'color': colors.accentInfo},
      {'name': 'Finishes', 'duration': '4-6 weeks', 'color': colors.accentWarning},
      {'name': 'Final/Punch', 'duration': '1-2 weeks', 'color': colors.accentSuccess},
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
          Text(
            'Typical Residential Timeline',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...phases.asMap().entries.map((entry) {
            final index = entry.key;
            final phase = entry.value;
            final isLast = index == phases.length - 1;
            return _buildTimelineItem(colors, phase, isLast, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ZaftoColors colors, Map<String, dynamic> phase, bool isLast, int number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: phase['color'] as Color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$number', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: (phase['color'] as Color).withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(phase['name'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (phase['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(phase['duration'] as String, style: TextStyle(color: phase['color'] as Color, fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreConstruction(ZaftoColors colors) {
    final items = [
      'Permits and approvals obtained',
      'Site survey and staking complete',
      'Utility locate (call 811)',
      'Temporary power/water arranged',
      'Materials ordered and scheduled',
      'Subcontractor contracts signed',
      'Insurance certificates on file',
      'Job site safety plan in place',
    ];

    return _buildPhaseSection(colors, 'Pre-Construction Phase', items, LucideIcons.fileText, colors.accentInfo);
  }

  Widget _buildFoundationPhase(ZaftoColors colors) {
    final items = [
      'Excavation and grading',
      'Footings dug and inspected',
      'Foundation walls poured',
      'Waterproofing applied',
      'Drain tile and gravel installed',
      'Foundation backfill',
      'Slab prep (gravel, vapor barrier)',
      'Under-slab MEP rough-in',
      'Slab pour and cure',
    ];

    return _buildPhaseSection(colors, 'Foundation Phase', items, LucideIcons.layers, colors.accentError);
  }

  Widget _buildFramingPhase(ZaftoColors colors) {
    final items = [
      'Sill plates and anchor bolts',
      'Floor joists/subfloor',
      'Wall framing and sheathing',
      'Roof trusses/rafters',
      'Roof sheathing and felt',
      'Windows and exterior doors',
      'Roofing installation',
      'House wrap/WRB',
      'Exterior trim rough',
    ];

    return _buildPhaseSection(colors, 'Framing Phase', items, LucideIcons.home, colors.accentPrimary);
  }

  Widget _buildMEPRough(ZaftoColors colors) {
    final items = [
      'Plumbing top-out (DWV, supply)',
      'HVAC ductwork',
      'Electrical rough (boxes, wire)',
      'Low voltage (data, security)',
      'Gas piping (if applicable)',
      'Rough inspections (all trades)',
      'Insulation installation',
      'Vapor barrier (if required)',
      'Insulation inspection',
      'Drywall hang and finish',
    ];

    return _buildPhaseSection(colors, 'MEP Rough-In & Drywall', items, LucideIcons.wrench, colors.accentSuccess);
  }

  Widget _buildFinishPhase(ZaftoColors colors) {
    final items = [
      'Interior paint/primer',
      'Cabinets and countertops',
      'Interior doors and trim',
      'Flooring installation',
      'Plumbing fixtures',
      'Electrical devices/fixtures',
      'HVAC equipment startup',
      'Appliance installation',
      'Final paint touch-up',
      'Exterior siding complete',
      'Landscaping and grading',
      'Final inspections',
      'Certificate of Occupancy',
      'Punch list and close-out',
    ];

    return _buildPhaseSection(colors, 'Finish Phase', items, LucideIcons.paintbrush, colors.accentWarning);
  }

  Widget _buildPhaseSection(ZaftoColors colors, String title, List<String> items, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.check, color: accent, size: 12),
                  const SizedBox(width: 4),
                  Text(item, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
