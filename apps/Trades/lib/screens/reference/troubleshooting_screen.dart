/// Troubleshooting Guide - Design System v2.6
/// Common electrical problems and solutions
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

class TroubleshootingScreen extends ConsumerWidget {
  const TroubleshootingScreen({super.key});

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
        title: Text('Troubleshooting Guide', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafetyFirst(colors),
            const SizedBox(height: 16),
            _buildProblem('Dead Outlet', [
              'Check if switch-controlled (try switches)',
              'Test other outlets on same circuit',
              'Check GFCI outlets - press RESET (kitchen, bath, garage, outdoor)',
              'Check breaker panel - reset tripped breaker',
              'Test outlet with voltage tester',
              'If power at box but not outlet: bad outlet, replace',
              'If no power at box: trace circuit, check splices',
            ], colors),
            _buildProblem('Tripping Breaker', [
              'Unplug everything on circuit, reset breaker',
              'Plug in devices one at a time to find culprit',
              'Check for damaged cords, plugs, appliances',
              'Circuit overloaded: too many devices, redistribute',
              'Breaker trips instantly: short circuit somewhere',
              'AFCI trips: could be arc fault or nuisance trip',
              'If breaker won\'t reset: call electrician',
            ], colors),
            _buildProblem('Flickering Lights', [
              'One light: loose bulb, bad socket, failing bulb',
              'One circuit: loose connection at switch/outlet/box',
              'Whole house flickers: utility issue or main connection',
              'Flickers when appliance runs: normal for large motor start',
              'Consistent flicker: check neutral connections',
              'LED flicker: dimmer compatibility issue',
            ], colors),
            _buildProblem('Outlet Sparks', [
              'Small spark when plugging in: normal (inrush current)',
              'Large/loud sparks: worn outlet, replace immediately',
              'Burning smell: DANGER - turn off breaker, call electrician',
              'Warm outlet/cover plate: overloaded or loose connection',
              'Black marks on outlet: arcing damage, replace outlet and check wiring',
            ], colors),
            _buildProblem('GFCI Won\'t Reset', [
              'Press TEST first, then RESET',
              'Check other GFCIs - may be daisy-chained',
              'Unplug all devices on circuit, try reset',
              'Ground fault still present: moisture, damaged appliance',
              'No power to GFCI: check breaker, upstream wiring',
              'GFCI bad: they do fail, replace if >10 years old',
              'Wired wrong: LINE vs LOAD reversed',
            ], colors),
            _buildProblem('Buzzing/Humming', [
              'From outlet: loose connection, overloaded circuit',
              'From switch: dimmer with incompatible bulbs',
              'From panel: loose breaker, overloaded circuit, failing breaker',
              'From fluorescent: normal ballast hum, or failing ballast',
              'From transformer: normal 60Hz hum',
              'Loud buzz + heat: DANGER - turn off, call electrician',
            ], colors),
            _buildProblem('Half the House Dead', [
              'Check main breaker - may be half tripped',
              'Lost one leg of 240V service',
              'Utility issue: call power company',
              'Check meter - one leg may be out',
              'Loose main lug connection: call electrician',
            ], colors),
            _buildProblem('Light Switch Not Working', [
              'Bulb burned out (try new bulb)',
              '3-way switch: check both switches',
              'Test for power at switch box',
              'Bad switch: replace (cheap and easy)',
              'Loose wire on switch terminal',
              'Tripped breaker or GFCI upstream',
            ], colors),
            const SizedBox(height: 16),
            _buildTools(colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyFirst(ZaftoColors colors) {
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
              Text('SAFETY FIRST', style: TextStyle(color: colors.accentError, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Turn OFF power before working in boxes\n'
            '• Use non-contact voltage tester to verify dead\n'
            '• Test tester on known live circuit first\n'
            '• When in doubt, call a licensed electrician',
            style: TextStyle(color: colors.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProblem(String title, List<String> steps, ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Icon(LucideIcons.wrench, color: colors.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 18,
                  child: Text('${e.key + 1}.', style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
                ),
                Expanded(child: Text(e.value, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTools(ZaftoColors colors) {
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
          Text('Essential Troubleshooting Tools', style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _toolRow('Non-contact voltage tester', 'Detects live wires without contact', colors),
          _toolRow('Outlet tester', 'Shows open ground, reversed polarity, etc', colors),
          _toolRow('Multimeter', 'Measures voltage, continuity, resistance', colors),
          _toolRow('GFCI tester', 'Tests GFCI function and wiring', colors),
          _toolRow('Circuit tracer', 'Identifies which breaker controls circuit', colors),
          _toolRow('Tone generator', 'Traces wires through walls', colors),
        ],
      ),
    );
  }

  Widget _toolRow(String tool, String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.wrench, color: colors.accentPrimary, size: 14),
          const SizedBox(width: 6),
          SizedBox(width: 130, child: Text(tool, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(use, style: TextStyle(color: colors.textTertiary, fontSize: 10))),
        ],
      ),
    );
  }
}
