import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Smoke Detector Wiring Diagram - Design System v2.6
class SmokeDetectorScreen extends ConsumerWidget {
  const SmokeDetectorScreen({super.key});

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
        title: Text('Smoke Detector Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInterconnectDiagram(colors),
            const SizedBox(height: 16),
            _buildWireColors(colors),
            const SizedBox(height: 16),
            _buildPlacementRules(colors),
            const SizedBox(height: 16),
            _buildTypesOfDetectors(colors),
            const SizedBox(height: 16),
            _buildWiringSteps(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildInterconnectDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.bellRing, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('INTERCONNECTED SMOKE DETECTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('When one alarms, ALL alarm together', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('PANEL (15A Dedicated or AFCI)         14/3 Cable', colors.textTertiary),
                _diagramLine('   │                                  Throughout', colors.textTertiary),
                _diagramLine('   │      ┌──────┐    ┌──────┐    ┌──────┐', colors.textTertiary),
                _diagramLine('   │      │SMOKE │    │SMOKE │    │SMOKE │', colors.accentPrimary),
                _diagramLine('   │      │  #1  │    │  #2  │    │  #3  │', colors.accentPrimary),
                _diagramLine('   │      └──┬───┘    └──┬───┘    └──┬───┘', colors.textTertiary),
                _diagramLine('   │         │           │           │', colors.textTertiary),
                _diagramLine('HOT├─────────┼───────────┼───────────┤ Black', colors.accentError),
                _diagramLine('   │         │           │           │', colors.textTertiary),
                _diagramLine('NEU├─────────┼───────────┼───────────┤ White', colors.textSecondary),
                _diagramLine('   │         │           │           │', colors.textTertiary),
                _diagramLine('INT├─────────┼───────────┼───────────┤ Red (Interconnect)', colors.accentError),
                _diagramLine('   │         │           │           │', colors.textTertiary),
                _diagramLine('GND└─────────┴───────────┴───────────┘ Bare/Green', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentError, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Red wire = interconnect signal (triggers all units when one detects smoke)', style: TextStyle(color: colors.accentError, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }

  Widget _buildWireColors(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WIRE COLOR CODE (14/3 NM-B)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _wireRow('Black', 'Hot (120V power)', Colors.grey[800]!, colors),
          _wireRow('White', 'Neutral', Colors.white, colors),
          _wireRow('Red', 'Interconnect signal', Colors.red, colors),
          _wireRow('Bare/Green', 'Equipment ground', Colors.green, colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Max interconnected units varies by manufacturer (typically 12-24). Check specs.', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _wireRow(String color, String purpose, Color dotColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: dotColor == Colors.white ? Border.all(color: colors.borderSubtle) : null)),
        const SizedBox(width: 10),
        SizedBox(width: 80, child: Text(color, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
        Expanded(child: Text(purpose, style: TextStyle(color: colors.textTertiary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildPlacementRules(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.mapPin, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('PLACEMENT REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _placementItem('Bedrooms', 'Inside each bedroom', colors),
          _placementItem('Outside Bedrooms', 'Within 21 ft of bedroom door', colors),
          _placementItem('Each Level', 'Minimum one per floor', colors),
          _placementItem('Basement', 'Required, near stairway', colors),
          _placementItem('Ceiling Mount', '4" min from wall', colors),
          _placementItem('Wall Mount', '4-12" from ceiling', colors),
          _placementItem('Peaked Ceiling', 'Within 3 ft of peak', colors),
          _placementItem('Away From', 'Kitchen (10ft), bathroom (3ft)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('CO detectors required in homes with fuel-burning appliances or attached garages', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _placementItem(String location, String rule, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(location, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
          Expanded(child: Text(rule, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTypesOfDetectors(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TYPES OF DETECTORS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _typeCard('Ionization', 'Fast-flaming fires', 'Kitchen distance: 20ft', colors),
          _typeCard('Photoelectric', 'Smoldering fires', 'Kitchen distance: 10ft', colors),
          _typeCard('Dual Sensor', 'Both types combined', 'Best protection', colors),
          _typeCard('Smoke/CO Combo', 'Smoke + Carbon Monoxide', 'Reduces device count', colors),
          _typeCard('Heat Detector', 'Temperature rise', 'Kitchens, garages, attics', colors),
        ],
      ),
    );
  }

  Widget _typeCard(String type, String detects, String note, ZaftoColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Expanded(flex: 2, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12))),
        Expanded(flex: 2, child: Text(detects, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        Expanded(flex: 2, child: Text(note, style: TextStyle(color: colors.accentPrimary, fontSize: 10))),
      ]),
    );
  }

  Widget _buildWiringSteps(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INSTALLATION STEPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _stepItem('1', 'Install 4" octagon boxes at each location', colors),
          _stepItem('2', 'Run 14/3 NM-B between all detector locations', colors),
          _stepItem('3', 'First detector: 14/2 home run to panel', colors),
          _stepItem('4', 'Connect all blacks together (power)', colors),
          _stepItem('5', 'Connect all whites together (neutral)', colors),
          _stepItem('6', 'Connect all reds together (interconnect)', colors),
          _stepItem('7', 'Connect all grounds to box and detector', colors),
          _stepItem('8', 'Mount detector bases, snap on heads', colors),
          _stepItem('9', 'Test each detector - all should alarm', colors),
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
            decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(num, style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13))),
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
            Text('CODE REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• NEC 210.12 - AFCI protection may be required\n'
            '• NEC 760 - Fire alarm systems (commercial)\n'
            '• IRC R314 - Smoke alarm requirements\n'
            '• IRC R315 - CO alarm requirements\n'
            '• NFPA 72 - Fire alarm code\n'
            '• Hardwired with battery backup required\n'
            '• All alarms must be interconnected',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
