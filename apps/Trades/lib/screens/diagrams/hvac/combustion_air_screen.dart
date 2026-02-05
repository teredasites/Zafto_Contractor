import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Combustion Air Requirements Diagram - Design System v2.6
class CombustionAirScreen extends ConsumerWidget {
  const CombustionAirScreen({super.key});

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
        title: Text('Combustion Air', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWhyNeeded(colors),
            const SizedBox(height: 16),
            _buildAllAirFromInside(colors),
            const SizedBox(height: 16),
            _buildAllAirFromOutside(colors),
            const SizedBox(height: 16),
            _buildCombinationAir(colors),
            const SizedBox(height: 16),
            _buildDirectVent(colors),
            const SizedBox(height: 16),
            _buildOpeningRequirements(colors),
            const SizedBox(height: 16),
            _buildSafetyWarnings(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyNeeded(ZaftoColors colors) {
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
          Row(children: [
            Icon(LucideIcons.wind, color: colors.accentError, size: 20),
            const SizedBox(width: 8),
            Text('WHY COMBUSTION AIR IS CRITICAL', style: TextStyle(color: colors.accentError, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Gas-burning appliances need oxygen for combustion. Without adequate air:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _dangerRow('Incomplete combustion', 'Produces carbon monoxide (deadly)', colors),
          _dangerRow('Flame rollout', 'Flames escape combustion chamber', colors),
          _dangerRow('Sooting', 'Black soot on appliances, walls', colors),
          _dangerRow('Pilot outage', 'Insufficient draft causes flame failure', colors),
          _dangerRow('Backdrafting', 'Exhaust gases enter living space', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Modern tight homes are particularly at risk - weatherization without addressing combustion air can be deadly.', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _dangerRow(String issue, String result, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(issue, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(result, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllAirFromInside(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('METHOD 1: ALL AIR FROM INSIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Standard infiltration (older, leaky buildings only)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('┌────────────────────────────────┐', colors.textTertiary),
                _diagramLine('│          BUILDING              │', colors.textTertiary),
                _diagramLine('│                                │', colors.textTertiary),
                _diagramLine('│   Air infiltrates through      │', colors.accentInfo),
                _diagramLine('│   cracks, gaps, openings       │', colors.accentInfo),
                _diagramLine('│              ↓                 │', colors.textTertiary),
                _diagramLine('│      ┌──────────────┐          │', colors.accentWarning),
                _diagramLine('│      │   FURNACE    │          │', colors.accentWarning),
                _diagramLine('│      │   50 cu ft   │          │', colors.textTertiary),
                _diagramLine('│      │  per 1000    │          │', colors.textTertiary),
                _diagramLine('│      │   BTU/hr     │          │', colors.textTertiary),
                _diagramLine('│      └──────────────┘          │', colors.accentWarning),
                _diagramLine('└────────────────────────────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _reqRow('Building volume', '50 cu ft per 1,000 BTU/hr input', colors),
          _reqRow('Example', '100,000 BTU furnace needs 5,000 cu ft', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('This method rarely meets code for modern construction. Most homes need outside combustion air.', style: TextStyle(color: colors.accentWarning, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _reqRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildAllAirFromOutside(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('METHOD 2: ALL AIR FROM OUTSIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Direct opening(s) to outdoors - most common method', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Text('TWO OPENINGS (Vertical):', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('      OUTSIDE        │    EQUIPMENT ROOM', colors.textTertiary),
                _diagramLine('                     │', colors.textTertiary),
                _diagramLine('    ┌─────┐         │     ┌─────┐', colors.textTertiary),
                _diagramLine('    │ AIR │ ═══════════>  │ HIGH│ Within 12" of', colors.accentInfo),
                _diagramLine('    │ IN  │         │     │     │ ceiling', colors.accentInfo),
                _diagramLine('    └─────┘         │     └─────┘', colors.textTertiary),
                _diagramLine('                     │      ▼', colors.textTertiary),
                _diagramLine('                     │ ┌────────┐', colors.accentWarning),
                _diagramLine('                     │ │FURNACE │', colors.accentWarning),
                _diagramLine('                     │ └────────┘', colors.accentWarning),
                _diagramLine('    ┌─────┐         │     ┌─────┐', colors.textTertiary),
                _diagramLine('    │ AIR │ ═══════════>  │ LOW │ Within 12" of', colors.accentInfo),
                _diagramLine('    │ IN  │         │     │     │ floor', colors.accentInfo),
                _diagramLine('    └─────┘         │     └─────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sizeRow('Each opening', '1 sq in per 4,000 BTU/hr (min 100 sq in)', colors),
          _sizeRow('Example', '100,000 BTU = 25 sq in each opening', colors),
          const SizedBox(height: 12),
          Text('SINGLE OPENING:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _sizeRow('Single high opening', '1 sq in per 3,000 BTU/hr', colors),
          _sizeRow('Must be within 12"', 'of ceiling', colors),
        ],
      ),
    );
  }

  Widget _sizeRow(String label, String size, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(size, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildCombinationAir(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('METHOD 3: COMBINATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Openings to both inside and outside', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _comboRow('Inside openings', '1 sq in per 1,000 BTU/hr', colors),
          _comboRow('Outside openings', '1 sq in per 4,000 BTU/hr', colors),
          const SizedBox(height: 12),
          Text('Communicating to interior requires large openings to spaces with adequate volume for Method 1 calculations.', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _comboRow(String type, String size, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Text(size, style: TextStyle(color: colors.accentPrimary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDirectVent(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.check, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('DIRECT VENT (SEALED COMBUSTION)', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Best option - combustion air ducted directly to appliance', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    OUTSIDE          │         INSIDE', colors.textTertiary),
                _diagramLine('                     │', colors.textTertiary),
                _diagramLine('    EXHAUST ←════════════════ EXHAUST', colors.accentError),
                _diagramLine('    (outer pipe)     │         ↑', colors.textTertiary),
                _diagramLine('                     │    ┌────┴────┐', colors.accentWarning),
                _diagramLine('    INTAKE ══════════════ │ FURNACE │', colors.accentInfo),
                _diagramLine('    (inner pipe)     │    │ (sealed)│', colors.textTertiary),
                _diagramLine('                     │    └─────────┘', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _directRow('Coaxial vent', 'Intake inside exhaust pipe', colors),
          _directRow('Two-pipe', 'Separate intake and exhaust', colors),
          _directRow('90%+ AFUE', 'High efficiency, requires this method', colors),
          const SizedBox(height: 12),
          Text('No combustion air openings needed in equipment room!', style: TextStyle(color: colors.accentSuccess, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _directRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(type, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildOpeningRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OPENING SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _specRow('Minimum free area', '100 sq in per opening', colors),
          _specRow('Ducts to outside', 'Same cross-section as opening', colors),
          _specRow('Louvers/screens', 'Reduce free area (multiply by 0.25-0.75)', colors),
          _specRow('High opening', 'Top within 12" of ceiling', colors),
          _specRow('Low opening', 'Bottom within 12" of floor', colors),
          const SizedBox(height: 12),
          Text('Free Area Factors:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _factorRow('Wood louvers', '0.25', colors),
                _factorRow('Metal louvers', '0.50-0.75', colors),
                _factorRow('1/4" mesh screen', '0.50', colors),
                _factorRow('No covering', '1.00', colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String spec, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(spec, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _factorRow(String type, String factor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(type, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Text(factor, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSafetyWarnings(ZaftoColors colors) {
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
          Row(children: [
            Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 18),
            const SizedBox(width: 8),
            Text('COMPETING FOR AIR', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('These devices compete for air and can cause backdrafting:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          _competeRow('Kitchen range hood', '200-1200+ CFM', colors),
          _competeRow('Bathroom exhaust', '50-150 CFM', colors),
          _competeRow('Dryer', '100-200 CFM', colors),
          _competeRow('Central vacuum', '100-200 CFM', colors),
          _competeRow('Fireplace', '200-400 CFM', colors),
          const SizedBox(height: 12),
          Text('A 600 CFM range hood can depressurize a tight home enough to backdraft a water heater!', style: TextStyle(color: colors.accentError, fontWeight: FontWeight.w600, fontSize: 11)),
          const SizedBox(height: 12),
          Text('Solutions: makeup air systems, power vented appliances, sealed combustion', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _competeRow(String device, String cfm, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(LucideIcons.wind, color: colors.accentWarning, size: 12),
          const SizedBox(width: 8),
          Expanded(child: Text(device, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(cfm, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
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
            '• IFGC Section 304 - Combustion Air\n'
            '• IMC Section 703 - Combustion Air\n'
            '• Method 1: 50 cu ft per 1,000 BTU/hr\n'
            '• Method 2: 1 sq in per 4,000 BTU/hr outside\n'
            '• Minimum 100 sq in each opening\n'
            '• Motorized dampers must fail-open\n'
            '• Screen no smaller than 1/4" mesh\n'
            '• Openings must not be blocked\n'
            '• CO detector required near equipment',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 9));
  }
}
