import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Dimmer Switch Wiring Diagram - Design System v2.6
class DimmerSwitchScreen extends ConsumerWidget {
  const DimmerSwitchScreen({super.key});

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
        title: Text(
          'Dimmer Switch Wiring',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDimmerTypes(colors),
            const SizedBox(height: 16),
            _buildSinglePoleDimmer(colors),
            const SizedBox(height: 16),
            _buildThreeWayDimmer(colors),
            const SizedBox(height: 16),
            _buildLoadCompatibility(colors),
            const SizedBox(height: 16),
            _buildNeutralRequirement(colors),
            const SizedBox(height: 16),
            _buildTroubleshooting(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDimmerTypes(ZaftoColors colors) {
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
          Text('DIMMER SWITCH TYPES', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _typeRow('Single-Pole', 'Controls light from ONE location', colors),
          _typeRow('3-Way', 'Controls from TWO locations (with standard 3-way)', colors),
          _typeRow('Multi-Location', 'Controls from 3+ locations', colors),
          _typeRow('Smart Dimmer', 'WiFi/Bluetooth control, often needs neutral', colors),
        ],
      ),
    );
  }

  Widget _typeRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.sun, color: colors.accentPrimary, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13),
                children: [
                  TextSpan(text: '$type: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                  TextSpan(text: desc, style: TextStyle(color: colors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePoleDimmer(ZaftoColors colors) {
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
          Text('SINGLE-POLE DIMMER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('FROM PANEL                    TO LIGHT', colors.textTertiary),
                _diagramLine('    │                              │', colors.textTertiary),
                _diagramLine('    │      ┌────────────────┐      │', colors.textTertiary),
                _diagramLine('    │      │    DIMMER      │      │', colors.accentPrimary),
                _diagramLine('    │      │                │      │', colors.textTertiary),
                _diagramLine('HOT ├──────┤ BLACK ─► BLACK ├──────┤ LIGHT HOT', colors.accentError),
                _diagramLine('    │      │ (LINE)  (LOAD) │      │', colors.textTertiary),
                _diagramLine('    │      │                │      │', colors.textTertiary),
                _diagramLine('NEU ├──────┤ WHITE (if req) │──────┤ LIGHT NEUT', colors.textSecondary),
                _diagramLine('    │      │                │      │', colors.textTertiary),
                _diagramLine('GND ├──────┤ GREEN ─────────┤──────┤ GROUND', colors.accentSuccess),
                _diagramLine('    │      └────────────────┘      │', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Single-pole dimmers have 2 hot leads (interchangeable on basic models) plus ground.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _buildThreeWayDimmer(ZaftoColors colors) {
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
          Text('3-WAY DIMMER', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('POWER ────► 3-WAY DIMMER ────► 3-WAY SWITCH ────► LIGHT', colors.textTertiary),
                _diagramLine('           (Location 1)        (Location 2)', colors.textSecondary),
                _diagramLine('', colors.textTertiary),
                _diagramLine('┌──────────────────┐      ┌──────────────────┐', colors.textTertiary),
                _diagramLine('│   3-WAY DIMMER   │      │   3-WAY SWITCH   │', colors.accentPrimary),
                _diagramLine('│                  │      │  (standard)      │', colors.textTertiary),
                _diagramLine('│ COMMON (black) ◄─┼──HOT │                  │', colors.accentError),
                _diagramLine('│                  │      │                  │', colors.textTertiary),
                _diagramLine('│ TRAVELER 1 ──────┼──────┼── TRAVELER 1     │', colors.accentInfo),
                _diagramLine('│ TRAVELER 2 ──────┼──────┼── TRAVELER 2     │', colors.accentInfo),
                _diagramLine('│                  │      │                  │', colors.textTertiary),
                _diagramLine('│                  │      │ COMMON ──────────┼──► LIGHT', colors.accentWarning),
                _diagramLine('└──────────────────┘      └──────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.accentInfo, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Dimmer MUST be at the location where power enters. Other location uses standard 3-way switch.', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadCompatibility(ZaftoColors colors) {
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
          Text('LOAD COMPATIBILITY', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _loadRow('Incandescent', 'Standard dimmers work fine', colors.accentSuccess, colors),
          _loadRow('Halogen', 'Standard dimmers work fine', colors.accentSuccess, colors),
          _loadRow('LED (Dimmable)', 'Requires LED/CFL compatible dimmer', colors.accentWarning, colors),
          _loadRow('CFL (Dimmable)', 'Requires LED/CFL compatible dimmer', colors.accentWarning, colors),
          _loadRow('LED (Non-Dimmable)', 'DO NOT use with dimmer!', colors.accentError, colors),
          _loadRow('Fluorescent', 'Requires special ballast & dimmer', colors.accentError, colors),
          _loadRow('Ceiling Fans', 'Use FAN SPEED CONTROL, not dimmer!', colors.accentError, colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Using wrong dimmer type can cause flickering, buzzing, reduced bulb life, or fire hazard.', style: TextStyle(color: colors.accentError, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadRow(String load, String note, Color statusColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          SizedBox(width: 120, child: Text(load, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13))),
          Expanded(child: Text(note, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildNeutralRequirement(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentWarning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text('NEUTRAL WIRE REQUIREMENT', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text('NEC 404.2(C) requires a neutral wire in switch boxes for lighting loads in dwellings.', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(height: 12),
          _neutralRow('Smart Dimmers', 'Most require neutral for WiFi/electronics', colors),
          _neutralRow('Electronic Dimmers', 'Some require neutral for low wattage LEDs', colors),
          _neutralRow('Basic Dimmers', 'Usually don\'t need neutral', colors),
          _neutralRow('Older Homes', 'May lack neutral at switch - check before buying', colors),
        ],
      ),
    );
  }

  Widget _neutralRow(String item, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.minus, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12),
                children: [
                  TextSpan(text: '$item: ', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                  TextSpan(text: note, style: TextStyle(color: colors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshooting(ZaftoColors colors) {
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
              Icon(LucideIcons.wrench, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text('TROUBLESHOOTING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 16),
          _troubleRow('Lights flicker', 'Incompatible dimmer for LED/CFL, or overloaded dimmer', colors),
          _troubleRow('Buzzing/humming', 'Incompatible bulbs, or cheap dimmer. Try better quality dimmer.', colors),
          _troubleRow('Won\'t dim low', 'LED needs ELV dimmer, or bulbs not dimmable enough', colors),
          _troubleRow('Lights stay dim', 'Some LEDs need minimum load - add incandescent or bypass capacitor', colors),
          _troubleRow('Dimmer hot to touch', 'Normal for some heat. If very hot: overloaded or failing.', colors),
        ],
      ),
    );
  }

  Widget _troubleRow(String problem, String solution, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(problem, style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(height: 2),
          Text(solution, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCodeReference(ZaftoColors colors) {
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
          Row(
            children: [
              Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
              const SizedBox(width: 8),
              Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• NEC 404.2(C) - Neutral Conductor at Switch Location\n'
            '• NEC 404.14(E) - Dimmer Switches (rating requirements)\n'
            '• NEC 404.11 - Position and Connection of Switches\n'
            '• NEC 410.104 - Luminaires (dimmer compatibility)',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
