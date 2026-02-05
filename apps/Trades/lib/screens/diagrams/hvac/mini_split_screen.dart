import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

/// Mini-Split Systems Diagram - Design System v2.6
class MiniSplitScreen extends ConsumerWidget {
  const MiniSplitScreen({super.key});

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
        title: Text('Mini-Split Systems', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildSystemComponents(colors),
            const SizedBox(height: 16),
            _buildLineSet(colors),
            const SizedBox(height: 16),
            _buildInstallation(colors),
            const SizedBox(height: 16),
            _buildMultiZone(colors),
            const SizedBox(height: 16),
            _buildSizing(colors),
            const SizedBox(height: 16),
            _buildAdvantages(colors),
            const SizedBox(height: 16),
            _buildCodeRequirements(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DUCTLESS MINI-SPLIT SYSTEM', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('         INDOOR UNIT (wall-mounted)', colors.accentInfo),
                _diagramLine('         ┌────────────────────────┐', colors.accentInfo),
                _diagramLine('         │  ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼  │', colors.accentInfo),
                _diagramLine('         │       EVAPORATOR       │', colors.accentInfo),
                _diagramLine('         │        BLOWER          │', colors.accentInfo),
                _diagramLine('         └──────────┬─────────────┘', colors.accentInfo),
                _diagramLine('                    │', colors.textTertiary),
                _diagramLine('                    │ LINE SET', colors.accentWarning),
                _diagramLine('       (liquid + suction + power + drain)', colors.textTertiary),
                _diagramLine('                    │', colors.textTertiary),
                _diagramLine('    ════════════════╪════════════════ WALL', colors.textTertiary),
                _diagramLine('                    │', colors.textTertiary),
                _diagramLine('         ┌──────────┴─────────────┐', colors.accentPrimary),
                _diagramLine('         │      OUTDOOR UNIT      │', colors.accentPrimary),
                _diagramLine('         │    CONDENSER + COMP    │', colors.accentPrimary),
                _diagramLine('         └────────────────────────┘', colors.accentPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('A mini-split is a split system without ductwork. Refrigerant lines connect outdoor condenser to indoor air handler(s).', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSystemComponents(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SYSTEM COMPONENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('Outdoor Unit:', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _compRow('Compressor', 'Inverter-driven (variable speed)', colors),
          _compRow('Condenser coil', 'Rejects/absorbs heat (reversible)', colors),
          _compRow('Fan', 'Moves air across condenser', colors),
          _compRow('Control board', 'System brain, communicates with indoor', colors),
          const SizedBox(height: 10),
          Text('Indoor Unit:', style: TextStyle(color: colors.accentInfo, fontWeight: FontWeight.w600, fontSize: 12)),
          _compRow('Evaporator coil', 'Absorbs/rejects heat (reversible)', colors),
          _compRow('Blower', 'Variable speed fan', colors),
          _compRow('Air filter', 'Washable/replaceable', colors),
          _compRow('Condensate pump', 'Built-in (some models)', colors),
          _compRow('Remote receiver', 'IR or WiFi control', colors),
        ],
      ),
    );
  }

  Widget _compRow(String component, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(component, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(desc, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildLineSet(ZaftoColors colors) {
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
            Icon(LucideIcons.plug, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('LINE SET COMPONENTS', style: TextStyle(color: colors.accentWarning, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _lineRow('Liquid line', 'Small copper (1/4" or 3/8")', 'High pressure liquid', colors),
          _lineRow('Suction line', 'Large copper (1/2" to 3/4")', 'Low pressure vapor, insulated', colors),
          _lineRow('Power wire', '14-3 or 12-3 typical', 'To outdoor unit', colors),
          _lineRow('Control wire', '14-4 or 18-4', 'Communication', colors),
          _lineRow('Condensate', '3/4" PVC or pump line', 'Drain water', colors),
          const SizedBox(height: 12),
          Text('Line Set Lengths:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _lengthRow('Minimum', '10-15 ft (varies by brand)', colors),
          _lengthRow('Maximum', '50-100 ft (varies by capacity)', colors),
          _lengthRow('Max vertical', '30-50 ft', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Text('Pre-charged line sets simplify DIY installs but limit flexibility. Professional installs use copper tubing with field brazing.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(String line, String size, String purpose, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 85, child: Text(line, style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(size, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                Text(purpose, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lengthRow(String type, String length, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(length, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildInstallation(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INSTALLATION BASICS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('Indoor Unit Mounting:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _installRow('Height', '7 ft minimum from floor', colors),
          _installRow('Wall clearance', '4" sides, 6" top', colors),
          _installRow('Opposite wall', '6 ft minimum clearance', colors),
          _installRow('Slope', 'Slight tilt toward drain', colors),
          const SizedBox(height: 10),
          Text('Outdoor Unit Placement:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          _installRow('Side clearance', '12-24" (varies by model)', colors),
          _installRow('Front clearance', '24" minimum', colors),
          _installRow('Above grade', '4" minimum (snow areas more)', colors),
          _installRow('Level', 'Must be level on pad', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(LucideIcons.alertTriangle, color: colors.accentError, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('EPA 608 certification required to handle refrigerant. DIY kits with pre-charged lines may be exempt.', style: TextStyle(color: colors.accentError, fontSize: 11))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _installRow(String item, String spec, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(item, style: TextStyle(color: colors.accentPrimary, fontSize: 11))),
          Expanded(child: Text(spec, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildMultiZone(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.layoutGrid, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('MULTI-ZONE SYSTEMS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('One outdoor unit can serve multiple indoor units:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _zoneRow('Dual zone', '2 indoor heads', '18-24k BTU outdoor', colors),
          _zoneRow('Tri zone', '3 indoor heads', '24-36k BTU outdoor', colors),
          _zoneRow('Quad zone', '4 indoor heads', '36-48k BTU outdoor', colors),
          _zoneRow('Penta zone', '5 indoor heads', '48-60k BTU outdoor', colors),
          const SizedBox(height: 12),
          Text('Indoor Head Types:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          _headRow('Wall mount', 'Most common, high on wall', colors),
          _headRow('Ceiling cassette', 'Recessed in ceiling', colors),
          _headRow('Floor mount', 'Low on wall, like radiator', colors),
          _headRow('Slim duct', 'Hidden, uses short ducts', colors),
        ],
      ),
    );
  }

  Widget _zoneRow(String zone, String heads, String outdoor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(zone, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          SizedBox(width: 80, child: Text(heads, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Expanded(child: Text(outdoor, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _headRow(String type, String desc, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          SizedBox(width: 85, child: Text(type, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
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
          Text('SIZING GUIDE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text('Quick BTU Estimates (well-insulated):', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                _sizeRow('150-300 sq ft', '9,000 BTU', colors),
                _sizeRow('300-450 sq ft', '12,000 BTU', colors),
                _sizeRow('450-700 sq ft', '18,000 BTU', colors),
                _sizeRow('700-1,000 sq ft', '24,000 BTU', colors),
                _sizeRow('1,000-1,400 sq ft', '36,000 BTU', colors),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('12,000 BTU = 1 ton of cooling', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text('These are estimates. Proper sizing requires Manual J load calculation considering insulation, windows, climate, and orientation.', style: TextStyle(color: colors.accentWarning, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _sizeRow(String area, String btu, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(area, style: TextStyle(color: colors.textPrimary, fontSize: 11))),
          Text(btu, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAdvantages(ZaftoColors colors) {
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
            Icon(LucideIcons.thumbsUp, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('ADVANTAGES', style: TextStyle(color: colors.accentSuccess, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _advantageRow('No ductwork', 'Avoids 25-30% duct losses', colors),
          _advantageRow('Zone control', 'Each head independent', colors),
          _advantageRow('Inverter tech', 'Variable speed = high efficiency', colors),
          _advantageRow('Easy install', 'Only 3" hole through wall', colors),
          _advantageRow('Quiet', '20-40 dB indoor units', colors),
          _advantageRow('Heat pump', 'Heating and cooling in one', colors),
          _advantageRow('High SEER', '20-30 SEER common', colors),
          const SizedBox(height: 12),
          Text('Considerations:', style: TextStyle(color: colors.accentWarning, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 4),
          Text('• Higher upfront cost per BTU\n• Visible indoor units\n• Filter cleaning required monthly\n• May need multiple heads for large homes', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _advantageRow(String adv, String detail, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.check, color: colors.accentSuccess, size: 14),
          const SizedBox(width: 8),
          SizedBox(width: 85, child: Text(adv, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 11))),
          Expanded(child: Text(detail, style: TextStyle(color: colors.textSecondary, fontSize: 11))),
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
            '• Permit typically required\n'
            '• EPA 608 for refrigerant handling\n'
            '• Electrical per NEC Article 440\n'
            '• Dedicated circuit for outdoor unit\n'
            '• Disconnect within sight of unit\n'
            '• Condensate disposal per IMC 307\n'
            '• Line set penetrations sealed\n'
            '• Manufacturer clearances maintained\n'
            '• Refrigerant type on nameplate',
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
