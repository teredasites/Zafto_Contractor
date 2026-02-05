/// Aluminum Wiring Reference - Design System v2.6
/// Safety guide for aluminum branch circuit wiring
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class AluminumWiringScreen extends ConsumerWidget {
  const AluminumWiringScreen({super.key});

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
        title: Text('Aluminum Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OverviewSection(colors: colors),
          const SizedBox(height: 16),
          _ProblemsSection(colors: colors),
          const SizedBox(height: 16),
          _IdentificationSection(colors: colors),
          const SizedBox(height: 16),
          _RemediationSection(colors: colors),
          const SizedBox(height: 16),
          _DeviceRatingsSection(colors: colors),
          const SizedBox(height: 16),
          _LargeWireSection(colors: colors),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final ZaftoColors colors;
  const _OverviewSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 24),
              const SizedBox(width: 10),
              Expanded(child: Text('Aluminum Branch Circuit Wiring', style: TextStyle(color: colors.accentWarning, fontSize: 16, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Single-strand aluminum wiring was used in branch circuits (15A/20A) from 1965-1973 due to copper shortage. '
            'This specific application has known fire hazards. NOT the same issue as large aluminum feeders.',
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ProblemsSection extends StatelessWidget {
  final ZaftoColors colors;
  const _ProblemsSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Why It's Dangerous", style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _ProblemRow(colors: colors, problem: 'Oxidation', detail: 'Aluminum oxide is resistive, creates heat'),
          _ProblemRow(colors: colors, problem: 'Expansion', detail: 'Expands/contracts more than copper, loosens connections'),
          _ProblemRow(colors: colors, problem: 'Creep', detail: 'Cold flows under pressure, loosens screw terminals'),
          _ProblemRow(colors: colors, problem: 'Galvanic corrosion', detail: 'Dissimilar metals (Al + Cu) corrode at junction'),
          _ProblemRow(colors: colors, problem: 'Softness', detail: 'Easily nicked or damaged during installation'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentError.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'CPSC reports: Homes with aluminum wiring are 55× more likely to have fire-hazard conditions at outlets.',
              style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProblemRow extends StatelessWidget {
  final ZaftoColors colors;
  final String problem;
  final String detail;
  const _ProblemRow({required this.colors, required this.problem, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(problem, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}

class _IdentificationSection extends StatelessWidget {
  final ZaftoColors colors;
  const _IdentificationSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to Identify', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _IdRow(colors: colors, where: 'Cable jacket', what: 'Marked "AL" or "ALUMINUM"'),
          _IdRow(colors: colors, where: 'Wire color', what: "Silver/gray vs copper's orange"),
          _IdRow(colors: colors, where: 'Panel', what: 'Look at branch circuit wires'),
          _IdRow(colors: colors, where: 'Home age', what: '1965-1973 most common'),
          _IdRow(colors: colors, where: 'Warning signs', what: 'Warm cover plates, flickering lights, burning smell'),
          const SizedBox(height: 12),
          Text('Check at panel with power OFF. If unsure, hire electrician.', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _IdRow extends StatelessWidget {
  final ZaftoColors colors;
  final String where;
  final String what;
  const _IdRow({required this.colors, required this.where, required this.what});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 95, child: Text(where, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(what, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}

class _RemediationSection extends StatelessWidget {
  final ZaftoColors colors;
  const _RemediationSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.borderDefault)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repair Options', style: TextStyle(color: colors.accentPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          _RepairRow(colors: colors, method: 'Complete rewire', detail: 'BEST - Replace all aluminum branch circuits', rating: 'best'),
          _RepairRow(colors: colors, method: 'COPALUM crimp', detail: 'GOOD - Special crimp connector (licensed only)', rating: 'good'),
          _RepairRow(colors: colors, method: 'AlumiConn', detail: 'ACCEPTABLE - Set-screw lug connector', rating: 'acceptable'),
          _RepairRow(colors: colors, method: 'CO/ALR devices', detail: 'MINIMUM - Use rated devices at all points', rating: 'minimum'),
          _RepairRow(colors: colors, method: 'Purple wire nuts', detail: 'NOT RECOMMENDED - Temporary at best', rating: 'not'),
          const SizedBox(height: 12),
          Text('COPALUM and complete rewire are only CPSC-recommended permanent repairs.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RepairRow extends StatelessWidget {
  final ZaftoColors colors;
  final String method;
  final String detail;
  final String rating;
  const _RepairRow({required this.colors, required this.method, required this.detail, required this.rating});

  Color get _dotColor {
    switch (rating) {
      case 'best':
      case 'good':
        return colors.accentSuccess;
      case 'acceptable':
        return colors.accentPrimary;
      case 'minimum':
        return colors.accentWarning;
      default:
        return colors.accentError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10, height: 10,
            margin: const EdgeInsets.only(top: 3, right: 10),
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: '$method: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                TextSpan(text: detail, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceRatingsSection extends StatelessWidget {
  final ZaftoColors colors;
  const _DeviceRatingsSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentInfo.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Device Ratings Explained', style: TextStyle(color: colors.accentInfo, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _RatingRow(colors: colors, rating: 'CO/ALR', meaning: 'Copper/Aluminum Revised - For 15A/20A receptacles & switches'),
          _RatingRow(colors: colors, rating: 'CU-AL', meaning: 'Only for 20A+ switches, NOT receptacles'),
          _RatingRow(colors: colors, rating: 'AL-CU', meaning: 'For circuit breakers, larger equipment'),
          const SizedBox(height: 12),
          Text(
            'Standard devices marked "CU only" or "Use Copper Wire Only" cannot be used with aluminum. CO/ALR devices have larger terminal screws and are designed for aluminum\'s properties.',
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final ZaftoColors colors;
  final String rating;
  final String meaning;
  const _RatingRow({required this.colors, required this.rating, required this.meaning});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 65, child: Text(rating, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(meaning, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}

class _LargeWireSection extends StatelessWidget {
  final ZaftoColors colors;
  const _LargeWireSection({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Large Aluminum Wire is OK', style: TextStyle(color: colors.accentSuccess, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(
            'Aluminum is commonly used (and acceptable) for:\n\n'
            '• Service entrance conductors (SE cable)\n'
            '• Large feeders (sub-panels, 60A+)\n'
            '• 240V appliance circuits (#8 and larger)\n'
            '• Utility service drops\n\n'
            'These larger connections use AL-rated lugs and are properly torqued. '
            'The fire hazard is specific to small branch circuit (15A/20A) wiring with standard devices.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
