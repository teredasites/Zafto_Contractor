import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Service Entrance Wiring Diagram - Design System v2.6
class ServiceEntranceScreen extends ConsumerWidget {
  const ServiceEntranceScreen({super.key});

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
          'Service Entrance Wiring',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverheadDiagram(colors),
            const SizedBox(height: 16),
            _buildUndergroundDiagram(colors),
            const SizedBox(height: 16),
            _buildComponents(colors),
            const SizedBox(height: 16),
            _buildGroundingSystem(colors),
            const SizedBox(height: 16),
            _buildSizing(colors),
            const SizedBox(height: 16),
            _buildNEC2023(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverheadDiagram(ZaftoColors colors) {
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
          Text(
            'OVERHEAD SERVICE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('UTILITY POLE              HOUSE', colors.textTertiary),
                _diagramLine('    │                       │', colors.textTertiary),
                _diagramLine('    │   SERVICE DROP        │ Weatherhead', colors.textTertiary),
                _diagramLine('    └───────────────────────┤ (drip loops)', colors.accentPrimary),
                _diagramLine('                            │', colors.textTertiary),
                _diagramLine('                            │ Service Mast', colors.textTertiary),
                _diagramLine('                            │ (rigid conduit)', colors.textTertiary),
                _diagramLine('                            │', colors.textTertiary),
                _diagramLine('                       ┌────┴────┐', colors.textTertiary),
                _diagramLine('                       │  METER  │ ← 5-6ft center', colors.accentSuccess),
                _diagramLine('                       └────┬────┘', colors.textTertiary),
                _diagramLine('                            │ SE Cable or Conduit', colors.textTertiary),
                _diagramLine('                       ┌────┴────┐', colors.textTertiary),
                _diagramLine('                       │  MAIN   │', colors.accentPrimary),
                _diagramLine('                       │  PANEL  │', colors.accentPrimary),
                _diagramLine('                       └────┬────┘', colors.textTertiary),
                _diagramLine('                            │', colors.textTertiary),
                _diagramLine('                       ═════╧═════', colors.accentSuccess),
                _diagramLine('                       GROUNDING', colors.accentSuccess),
                _diagramLine('                       ELECTRODE', colors.accentSuccess),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(
      text,
      style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10),
    );
  }

  Widget _buildUndergroundDiagram(ZaftoColors colors) {
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
          Text(
            'UNDERGROUND SERVICE',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('UTILITY                          HOUSE', colors.textTertiary),
                _diagramLine('TRANSFORMER     UNDERGROUND      │', colors.textTertiary),
                _diagramLine('    │           SERVICE      ┌───┴───┐', colors.textTertiary),
                _diagramLine('    └───────────────────────►│ METER │', colors.accentPrimary),
                _diagramLine('         (utility installs)  └───┬───┘', colors.textTertiary),
                _diagramLine('                                 │', colors.textTertiary),
                _diagramLine('                            ┌────┴────┐', colors.textTertiary),
                _diagramLine('                            │  MAIN   │', colors.accentPrimary),
                _diagramLine('                            │  PANEL  │', colors.accentPrimary),
                _diagramLine('                            └────┬────┘', colors.textTertiary),
                _diagramLine('                                 │', colors.textTertiary),
                _diagramLine('                            ═════╧═════', colors.accentSuccess),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Underground typically cleaner, no weatherhead/mast required',
            style: TextStyle(color: colors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildComponents(ZaftoColors colors) {
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
          Text(
            'SERVICE COMPONENTS',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _compRow('Weatherhead', 'Keeps water out, drip loops below', colors),
          _compRow('Service Mast', 'Rigid conduit, supports service drop', colors),
          _compRow('Service Drop', 'Utility wires from pole to house', colors),
          _compRow('Service Lateral', 'Underground from transformer', colors),
          _compRow('Meter Base', 'Houses utility meter, 5-6ft height', colors),
          _compRow('SE Cable', 'Service entrance cable to panel', colors),
          _compRow('Main Panel', 'Service disconnect + branch circuits', colors),
          _compRow('Main Breaker', 'Service disconnect device', colors),
          _compRow('Grounding Electrode', 'Rods, Ufer, water pipe, etc', colors),
          _compRow('GEC', 'Grounding electrode conductor', colors),
          _compRow('MBJ', 'Main bonding jumper (bonds N to G)', colors),
        ],
      ),
    );
  }

  Widget _compRow(String comp, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              comp,
              style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundingSystem(ZaftoColors colors) {
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
          Text(
            'GROUNDING ELECTRODE SYSTEM',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All available electrodes must be bonded together:',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _groundRow('Concrete-encased (Ufer)', '20ft of 4 AWG or 1/2" rebar', colors),
          _groundRow('Ground rod(s)', '8ft, 5/8" copper-clad, 2 if >25Ω', colors),
          _groundRow('Metal water pipe', 'First 10ft entering building', colors),
          _groundRow('Building steel', 'If effectively grounded', colors),
          _groundRow('Ground ring', '20ft bare 2 AWG around building', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, color: colors.accentSuccess, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bond neutral and ground ONLY at main panel (or first disconnect). This is where the main bonding jumper connects N bar to G bar.',
                    style: TextStyle(color: colors.accentSuccess, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groundRow(String type, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.zap, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 12)),
          ),
          Expanded(
            child: Text(spec, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSizing(ZaftoColors colors) {
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
          Text(
            'SERVICE SIZING',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _sizeHeader(['Service', 'Copper', 'Aluminum', 'GEC (Cu)'], colors),
                _sizeRow(['100A', '4 AWG', '2 AWG', '8 AWG'], colors),
                _sizeRow(['150A', '1 AWG', '2/0 AWG', '6 AWG'], colors),
                _sizeRow(['200A', '2/0 AWG', '4/0 AWG', '4 AWG'], colors),
                _sizeRow(['320A', '350 kcmil', '500 kcmil', '2 AWG'], colors),
                _sizeRow(['400A', '500 kcmil', '750 kcmil', '1/0 AWG'], colors, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '83% rule applies for dwelling services (NEC 310.12)',
            style: TextStyle(color: colors.textTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sizeHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
      ),
      child: Row(
        children: headers.map((h) => Expanded(
          child: Text(
            h,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10),
          ),
        )).toList(),
      ),
    );
  }

  Widget _sizeRow(List<String> values, ZaftoColors colors, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5)),
      ),
      child: Row(
        children: values.asMap().entries.map((e) => Expanded(
          child: Text(
            e.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: e.key == 0 ? colors.textPrimary : colors.textSecondary,
              fontWeight: e.key == 0 ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildNEC2023(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 18),
              const SizedBox(width: 8),
              Text(
                'NEC 2023: EMERGENCY DISCONNECT (230.85)',
                style: TextStyle(
                  color: colors.accentError,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• REQUIRED for one/two-family dwellings\n'
            '• Must be OUTDOOR, readily accessible\n'
            '• Max 6 throws to disconnect all power\n'
            '• Marked "EMERGENCY DISCONNECT"\n'
            '• First responders can kill power from outside\n'
            '• Can be meter-main combo or separate disconnect',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
