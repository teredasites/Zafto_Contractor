import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Ventilation HRV/ERV Systems Diagram - Design System v2.6
class VentilationHrvErvScreen extends ConsumerWidget {
  const VentilationHrvErvScreen({super.key});

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
        title: Text('HRV & ERV Ventilation', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWhyVentilate(colors),
            const SizedBox(height: 16),
            _buildHRVDiagram(colors),
            const SizedBox(height: 16),
            _buildERVDiagram(colors),
            const SizedBox(height: 16),
            _buildHrvVsErv(colors),
            const SizedBox(height: 16),
            _buildDuctConnections(colors),
            const SizedBox(height: 16),
            _buildControls(colors),
            const SizedBox(height: 16),
            _buildSizing(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildWhyVentilate(ZaftoColors colors) {
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
          Row(children: [
            Icon(LucideIcons.wind, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('WHY MECHANICAL VENTILATION?', style: TextStyle(color: colors.accentPrimary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Tight homes need controlled ventilation to maintain indoor air quality while preserving energy efficiency.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _reasonRow('Moisture control', 'Remove excess humidity from showers, cooking', colors),
          _reasonRow('Pollutant removal', 'VOCs, CO2, cooking odors, dust', colors),
          _reasonRow('Fresh air supply', 'Oxygen for occupants', colors),
          _reasonRow('Pressure balance', 'Prevent backdrafting issues', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('"Build tight, ventilate right" - Modern homes are too tight to rely on natural infiltration for fresh air.', style: TextStyle(color: colors.textSecondary, fontStyle: FontStyle.italic, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _reasonRow(String reason, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reason, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                Text(desc, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHRVDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HRV - HEAT RECOVERY VENTILATOR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Recovers HEAT (sensible) from exhaust air', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    OUTSIDE              │           INSIDE', colors.textTertiary),
                _diagramLine('                         │', colors.textTertiary),
                _diagramLine('    FRESH AIR ══════════>│════════> SUPPLY TO', colors.accentInfo),
                _diagramLine('    (cold in winter)     │  HEAT    LIVING SPACE', colors.accentInfo),
                _diagramLine('                         │ EXCHANGER', colors.accentWarning),
                _diagramLine('                         │  CORE', colors.accentWarning),
                _diagramLine('    EXHAUST <════════════│<════════ STALE AIR FROM', colors.accentError),
                _diagramLine('    (cold, but cleaner)  │          BATHS/KITCHEN', colors.accentError),
                _diagramLine('                         │', colors.textTertiary),
                _diagramLine('                    Heat transfers through core', colors.textTertiary),
                _diagramLine('                    (air streams don\'t mix)', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _hrvRow('Efficiency', '70-85% heat recovery typical', colors),
          _hrvRow('Best climate', 'Cold, dry climates', colors),
          _hrvRow('Moisture', 'Does NOT transfer moisture', colors),
        ],
      ),
    );
  }

  Widget _hrvRow(String label, String value, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(value, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildERVDiagram(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ERV - ENERGY RECOVERY VENTILATOR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Recovers HEAT and MOISTURE (sensible + latent)', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('    OUTSIDE              │           INSIDE', colors.textTertiary),
                _diagramLine('                         │', colors.textTertiary),
                _diagramLine('    FRESH AIR ══════════>│════════> SUPPLY', colors.accentInfo),
                _diagramLine('    (hot/humid summer)   │ENTHALPY  (pre-conditioned)', colors.accentInfo),
                _diagramLine('                         │  CORE', colors.accentWarning),
                _diagramLine('                         │', colors.accentWarning),
                _diagramLine('    EXHAUST <════════════│<════════ STALE AIR', colors.accentError),
                _diagramLine('    (cooled/dried)       │          (cool/dry inside)', colors.accentError),
                _diagramLine('                         │', colors.textTertiary),
                _diagramLine('               Heat AND moisture transfer', colors.textTertiary),
                _diagramLine('               through enthalpy wheel or core', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _hrvRow('Efficiency', '70-80% total energy recovery', colors),
          _hrvRow('Best climate', 'Hot/humid OR mixed climates', colors),
          _hrvRow('Moisture', 'DOES transfer moisture', colors),
        ],
      ),
    );
  }

  Widget _buildHrvVsErv(ZaftoColors colors) {
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
            Icon(LucideIcons.scale, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('HRV vs ERV - WHEN TO USE', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('Use HRV:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _useRow('Cold, dry climates (heating dominated)', colors),
          _useRow('Home has excess moisture (condensation issues)', colors),
          _useRow('Tight budget (HRV typically costs less)', colors),
          const SizedBox(height: 10),
          Text('Use ERV:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _useRow('Hot, humid climates (cooling dominated)', colors),
          _useRow('Mixed climates (both heating and cooling)', colors),
          _useRow('Home is too dry in winter (moisture recovery helps)', colors),
          _useRow('Heavy A/C use (reduces dehumidification load)', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Rule of thumb: If you run A/C more than heat, consider ERV. If heating dominated and dry climate, consider HRV.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _useRow(String use, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentWarning, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildDuctConnections(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DUCT CONNECTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('Four duct connections required:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          _ductRow('Fresh air IN', 'From outside (intake hood)', colors.accentInfo, colors),
          _ductRow('Stale air OUT', 'To outside (exhaust hood)', colors.accentError, colors),
          _ductRow('Supply air', 'To living spaces (or HVAC return)', colors.accentSuccess, colors),
          _ductRow('Return air', 'From baths/kitchen (exhaust points)', colors.accentWarning, colors),
          const SizedBox(height: 12),
          Text('Installation Options:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _optionRow('Fully ducted', 'Dedicated supply and return ducts', colors),
          _optionRow('Integrated', 'Tied into HVAC supply/return', colors),
          _optionRow('Simplified', 'Supply to return plenum, exhaust from baths', colors),
        ],
      ),
    );
  }

  Widget _ductRow(String duct, String connection, Color color, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          SizedBox(width: 85, child: Text(duct, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(connection, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _optionRow(String option, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(option, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildControls(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.sliders, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('CONTROL OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _ctrlRow('Manual switch', 'User turns on/off', colors),
          _ctrlRow('Timer', 'Runs X minutes per hour', colors),
          _ctrlRow('Humidity sensor', 'Runs when RH exceeds setpoint', colors),
          _ctrlRow('CO2 sensor', 'Runs when CO2 levels high', colors),
          _ctrlRow('Occupancy', 'Based on presence detection', colors),
          _ctrlRow('HVAC interlock', 'Runs with furnace fan', colors),
          const SizedBox(height: 12),
          Text('Speed Settings:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Most units have multiple speed settings. High speed for boost (cooking, shower), low for continuous background ventilation.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _ctrlRow(String control, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 95, child: Text(control, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildSizing(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SIZING REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('ASHRAE 62.2 Ventilation Rate:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CFM = (0.03 × floor area) + (7.5 × occupants + 1)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
                const SizedBox(height: 8),
                Text('Example: 2,000 sq ft, 4 bedrooms\nCFM = (0.03 × 2000) + (7.5 × 5) = 60 + 37.5 = 98 CFM', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Typical Unit Sizes:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _sizeRow('Small home', '70-100 CFM', colors),
          _sizeRow('Medium home', '100-150 CFM', colors),
          _sizeRow('Large home', '150-250 CFM', colors),
        ],
      ),
    );
  }

  Widget _sizeRow(String size, String cfm, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(size, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Text(cfm, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
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
            '• IRC M1507 - Mechanical Ventilation\n'
            '• ASHRAE 62.2 - Residential Ventilation\n'
            '• Whole-house ventilation required (IECC)\n'
            '• Rate per ASHRAE 62.2 formula\n'
            '• Controls must be accessible\n'
            '• Outdoor terminations per code\n'
            '• Insulated ducts where condensation risk\n'
            '• Condensate drain from unit\n'
            '• Filter access required\n'
            '• HVI certified capacity ratings',
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
