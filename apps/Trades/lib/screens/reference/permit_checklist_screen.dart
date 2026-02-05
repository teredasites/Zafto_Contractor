/// Permit & Inspection Guide - Design System v2.6
/// Permit process and inspection checklists
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class PermitChecklistScreen extends ConsumerWidget {
  const PermitChecklistScreen({super.key});

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
        title: Text('Permit & Inspection Guide', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWhenNeeded(colors),
            const SizedBox(height: 16),
            _buildTypicalProcess(colors),
            const SizedBox(height: 16),
            _buildRoughInChecklist(colors),
            const SizedBox(height: 16),
            _buildFinalChecklist(colors),
            const SizedBox(height: 16),
            _buildCommonFails(colors),
            const SizedBox(height: 16),
            _buildTips(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWhenNeeded(ZaftoColors colors) {
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
          Text('When is a Permit Required?', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text('USUALLY REQUIRES PERMIT:', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _listItem('New circuits', true, colors),
          _listItem('Panel upgrades/replacement', true, colors),
          _listItem('Sub-panel installation', true, colors),
          _listItem('New service installation', true, colors),
          _listItem('Adding outlets in new locations', true, colors),
          _listItem('240V appliance circuits (EV, range, dryer)', true, colors),
          _listItem('Hot tub/pool wiring', true, colors),
          _listItem('Rewiring projects', true, colors),
          _listItem('Generator/transfer switch', true, colors),
          const SizedBox(height: 12),
          Text('USUALLY NO PERMIT:', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _listItem('Like-for-like device replacement', false, colors),
          _listItem('Replacing light fixtures', false, colors),
          _listItem('Replacing switches/outlets', false, colors),
          _listItem('Replacing breakers (same size)', false, colors),
          const SizedBox(height: 10),
          Text('Rules vary by jurisdiction - check with local building department', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _listItem(String text, bool permit, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(permit ? LucideIcons.checkCircle : LucideIcons.minusCircle, color: permit ? colors.accentSuccess : colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTypicalProcess(ZaftoColors colors) {
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
          Text('Typical Permit Process', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _stepItem('1', 'Apply for permit (online or in person)', colors),
          _stepItem('2', 'Submit plans if required', colors),
          _stepItem('3', 'Pay permit fee', colors),
          _stepItem('4', 'Receive permit - post on job site', colors),
          _stepItem('5', 'Do rough-in work', colors),
          _stepItem('6', 'Call for ROUGH-IN inspection (before covering)', colors),
          _stepItem('7', 'Pass rough-in, close walls', colors),
          _stepItem('8', 'Complete finish work', colors),
          _stepItem('9', 'Call for FINAL inspection', colors),
          _stepItem('10', 'Receive approval/sign-off', colors),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(child: Text(num, style: TextStyle(color: colors.bgBase, fontWeight: FontWeight.w600, fontSize: 11))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildRoughInChecklist(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.clipboardList, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Rough-In Inspection Checklist', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _checkItem('All boxes installed and secured', colors),
          _checkItem('Cables stapled within 12" of box, every 4.5ft', colors),
          _checkItem('Proper cable protection (nail plates where needed)', colors),
          _checkItem('Box fill calculations OK', colors),
          _checkItem('Correct wire sizes for circuit', colors),
          _checkItem('Panel location accessible, clearances met', colors),
          _checkItem('Grounding electrode system in place', colors),
          _checkItem('Smoke detector locations correct', colors),
          _checkItem('AFCI circuits identified', colors),
          _checkItem('GFCI locations identified', colors),
          _checkItem('Permit posted and visible', colors),
        ],
      ),
    );
  }

  Widget _buildFinalChecklist(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.clipboardCheck, color: colors.accentSuccess, size: 18),
              const SizedBox(width: 8),
              Text('Final Inspection Checklist', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _checkItem('All devices installed (outlets, switches)', colors),
          _checkItem('Cover plates on all boxes', colors),
          _checkItem('GFCIs installed and functional', colors),
          _checkItem('AFCIs installed and functional', colors),
          _checkItem('Panel cover on, directory complete', colors),
          _checkItem('All circuits labeled', colors),
          _checkItem('Smoke/CO detectors working', colors),
          _checkItem('Ground and neutral properly terminated', colors),
          _checkItem('Correct polarity on all outlets', colors),
          _checkItem('Working clearances maintained', colors),
          _checkItem('Outdoor boxes weatherproof', colors),
        ],
      ),
    );
  }

  Widget _checkItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(LucideIcons.square, color: colors.textTertiary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildCommonFails(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 18),
              const SizedBox(width: 8),
              Text('Common Inspection Failures', style: TextStyle(color: colors.accentError, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          _failItem('Missing AFCI/GFCI protection', colors),
          _failItem('Panel directory incomplete', colors),
          _failItem('Cables not properly secured', colors),
          _failItem('Missing nail plates', colors),
          _failItem('Box fill exceeded', colors),
          _failItem('Working clearance violations', colors),
          _failItem('Wrong circuit breaker size', colors),
          _failItem('Missing bonding jumper', colors),
          _failItem('Smoke detectors not interconnected', colors),
          _failItem('Open knockouts in panel', colors),
        ],
      ),
    );
  }

  Widget _failItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(LucideIcons.x, color: colors.accentError, size: 14),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text('Pro Tips', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• Call for inspection early in the day\n'
            '• Be present during inspection if possible\n'
            '• Have permit and plans accessible\n'
            '• Keep area clean and well-lit\n'
            '• Don\'t cover work before rough-in passes\n'
            '• Fix corrections promptly, call for re-inspect\n'
            '• Build relationship with local inspectors\n'
            '• When in doubt, ask inspector BEFORE doing work',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
