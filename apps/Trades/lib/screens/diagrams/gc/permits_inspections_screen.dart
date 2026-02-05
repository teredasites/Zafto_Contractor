import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class PermitsInspectionsScreen extends ConsumerWidget {
  const PermitsInspectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'Permits & Inspections',
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
            _buildPermitTypes(colors),
            const SizedBox(height: 24),
            _buildInspectionSequence(colors),
            const SizedBox(height: 24),
            _buildInspectionChecklist(colors),
            const SizedBox(height: 24),
            _buildCommonFailures(colors),
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
              Icon(LucideIcons.clipboardCheck, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Permits & Inspections Overview',
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
            'Building permits ensure construction meets code requirements. The Authority Having Jurisdiction (AHJ) - typically the local building department - reviews plans and conducts inspections at critical stages.',
            style: TextStyle(color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Work without permits can result in fines, required demolition, insurance issues, and problems selling the property.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermitTypes(ZaftoColors colors) {
    final permits = [
      {'type': 'Building Permit', 'covers': 'Structure, framing, roofing, siding', 'icon': LucideIcons.home},
      {'type': 'Electrical Permit', 'covers': 'Wiring, panels, fixtures', 'icon': LucideIcons.zap},
      {'type': 'Plumbing Permit', 'covers': 'Water, drain, gas piping', 'icon': LucideIcons.droplet},
      {'type': 'Mechanical Permit', 'covers': 'HVAC, ductwork, equipment', 'icon': LucideIcons.wind},
      {'type': 'Demolition Permit', 'covers': 'Removal of structures', 'icon': LucideIcons.hammer},
      {'type': 'Grading Permit', 'covers': 'Earthwork, drainage', 'icon': LucideIcons.mountain},
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
              Icon(LucideIcons.fileText, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Permit Types',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
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
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
            children: permits.map((p) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgInset,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(p['icon'] as IconData, color: colors.accentInfo, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p['type'] as String, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 10)),
                        Text(p['covers'] as String, style: TextStyle(color: colors.textTertiary, fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionSequence(ZaftoColors colors) {
    final inspections = [
      {'name': 'Footing', 'when': 'Before concrete pour', 'checks': 'Depth, width, rebar, soil'},
      {'name': 'Foundation', 'when': 'Before backfill', 'checks': 'Walls, waterproofing, drainage'},
      {'name': 'Slab/Under-slab', 'when': 'Before slab pour', 'checks': 'Gravel, vapor barrier, plumbing'},
      {'name': 'Framing', 'when': 'After framing complete', 'checks': 'Structure, nailing, headers, straps'},
      {'name': 'Rough Electric', 'when': 'Before insulation', 'checks': 'Boxes, wire, grounding'},
      {'name': 'Rough Plumbing', 'when': 'Before insulation', 'checks': 'DWV, supply, pressure test'},
      {'name': 'Rough Mechanical', 'when': 'Before insulation', 'checks': 'Ductwork, equipment, venting'},
      {'name': 'Insulation', 'when': 'Before drywall', 'checks': 'R-values, coverage, vapor barrier'},
      {'name': 'Final', 'when': 'Before occupancy', 'checks': 'All systems complete, operational'},
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
            'Typical Inspection Sequence',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...inspections.asMap().entries.map((entry) {
            final index = entry.key;
            final insp = entry.value;
            final isLast = index == inspections.length - 1;
            return _buildInspectionRow(colors, insp, isLast, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildInspectionRow(ZaftoColors colors, Map<String, String> insp, bool isLast, int number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.accentSuccess,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$number', style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: colors.accentSuccess.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgBase,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(insp['name']!, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(insp['when']!, style: TextStyle(color: colors.accentInfo, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Checks: ${insp['checks']}', style: TextStyle(color: colors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectionChecklist(ZaftoColors colors) {
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
              Icon(LucideIcons.checkSquare, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pre-Inspection Checklist',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCheckItem(colors, 'Permit posted and visible on site'),
          _buildCheckItem(colors, 'Approved plans on site and accessible'),
          _buildCheckItem(colors, 'Work matches approved plans'),
          _buildCheckItem(colors, 'Work area accessible to inspector'),
          _buildCheckItem(colors, 'Previous inspection corrections made'),
          _buildCheckItem(colors, 'All required work complete for this stage'),
          _buildCheckItem(colors, 'Address visible from street'),
          _buildCheckItem(colors, 'Inspection scheduled 24 hours in advance'),
        ],
      ),
    );
  }

  Widget _buildCheckItem(ZaftoColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: colors.accentSuccess),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(LucideIcons.check, color: colors.accentSuccess, size: 12),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCommonFailures(ZaftoColors colors) {
    final failures = [
      {'issue': 'Missing fire blocking', 'fix': 'Add blocking at floor/ceiling penetrations'},
      {'issue': 'Improper nailing', 'fix': 'Follow nailing schedule, avoid shiners'},
      {'issue': 'Missing straps/ties', 'fix': 'Install hurricane straps, hold-downs'},
      {'issue': 'Wrong wire size', 'fix': 'Match wire gauge to breaker rating'},
      {'issue': 'Missing GFCI/AFCI', 'fix': 'Install required protection per code'},
      {'issue': 'Failed pressure test', 'fix': 'Find and repair leaks, retest'},
      {'issue': 'Insulation gaps', 'fix': 'Fill voids, ensure complete coverage'},
      {'issue': 'Missing CO/smoke detectors', 'fix': 'Install per code locations'},
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
              Icon(LucideIcons.xCircle, color: colors.accentError, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common Inspection Failures',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...failures.map((f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.x, color: colors.accentError, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(f['issue']!, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
                Icon(LucideIcons.arrowRight, color: colors.textTertiary, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(f['fix']!, style: TextStyle(color: colors.accentSuccess, fontSize: 11))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
