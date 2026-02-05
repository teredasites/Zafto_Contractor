import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Pool & Spa Wiring Diagram - Design System v2.6
class PoolSpaWiringScreen extends ConsumerWidget {
  const PoolSpaWiringScreen({super.key});

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
        title: Text('Pool & Spa Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafetyWarning(colors),
            const SizedBox(height: 16),
            _buildBondingRequirements(colors),
            const SizedBox(height: 16),
            _buildDistanceRequirements(colors),
            const SizedBox(height: 16),
            _buildPumpWiring(colors),
            const SizedBox(height: 16),
            _buildGFCIRequirements(colors),
            const SizedBox(height: 16),
            _buildCodeSummary(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyWarning(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentError.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.skull, color: colors.accentError, size: 28),
            const SizedBox(width: 10),
            Text('LIFE SAFETY - NEC Article 680', style: TextStyle(color: colors.accentError, fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Pool/spa electrical is EXTREMELY dangerous. Water + electricity = death. '
            'Improper bonding causes electrocution. This is NOT DIY work.',
            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBondingRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.link, color: colors.accentSuccess, size: 20),
            const SizedBox(width: 8),
            Text('EQUIPOTENTIAL BONDING GRID', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 8),
          Text('All metal within 5ft of water must be bonded together', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          _bondItem('Pool shell rebar/grid', 'Min 8 AWG solid copper', colors),
          _bondItem('Metal pool walls', 'Bonding lug required', colors),
          _bondItem('Pump motor', 'To bonding grid', colors),
          _bondItem('Heater', 'To bonding grid', colors),
          _bondItem('Metal ladders/rails', 'To bonding grid', colors),
          _bondItem('Diving board supports', 'To bonding grid', colors),
          _bondItem('Metal light niches', 'To bonding grid', colors),
          _bondItem('Perimeter surfaces', '3ft unbroken bond, 18" from water', colors),
          _bondItem('Metal fencing <5ft', 'To bonding grid', colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentWarning, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Bonding connects metal together to prevent voltage differences. Grounding provides fault current path. They are NOT the same.', style: TextStyle(color: colors.accentWarning, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _bondItem(String item, String note, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(LucideIcons.link, color: colors.accentSuccess, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(item, style: TextStyle(color: colors.textPrimary, fontSize: 12))),
        Text(note, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildDistanceRequirements(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISTANCE REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: colors.borderSubtle), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _distHeader(['Item', 'Min', 'Max'], colors),
              _distRow(['Receptacles from water', '6 ft', '20 ft'], colors),
              _distRow(['Lighting (overhead)', '12 ft above', '-'], colors),
              _distRow(['Lighting (existing)', '5 ft horiz', '-'], colors),
              _distRow(['Disconnect from equip', 'In sight', '50 ft'], colors),
              _distRow(['Disconnect from pool', '5 ft', '-'], colors),
              _distRow(['Underground wiring', '5 ft from pool', '18" deep'], colors),
              _distRow(['Overhead wiring', '22.5 ft above water', '14.5 ft above deck'], colors, isLast: true),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _distHeader(List<String> headers, ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
      ),
      child: Row(children: [
        Expanded(flex: 3, child: Text(headers[0], style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10))),
        Expanded(flex: 2, child: Text(headers[1], textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10))),
        Expanded(flex: 2, child: Text(headers[2], textAlign: TextAlign.center, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 10))),
      ]),
    );
  }

  Widget _distRow(List<String> values, ZaftoColors colors, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: colors.borderSubtle, width: 0.5))),
      child: Row(children: [
        Expanded(flex: 3, child: Text(values[0], style: TextStyle(color: colors.textPrimary, fontSize: 11))),
        Expanded(flex: 2, child: Text(values[1], textAlign: TextAlign.center, style: TextStyle(color: colors.accentSuccess, fontSize: 11))),
        Expanded(flex: 2, child: Text(values[2], textAlign: TextAlign.center, style: TextStyle(color: colors.textTertiary, fontSize: 11))),
      ]),
    );
  }

  Widget _buildPumpWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.waves, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('POOL PUMP WIRING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('PANEL ──► GFCI BREAKER ──► DISCONNECT ──► PUMP', colors.accentError),
                _diagramLine('          (required)       (within sight)', colors.textTertiary),
                const SizedBox(height: 10),
                _diagramLine('Typical pump circuits:', colors.textSecondary),
                _diagramLine('  1 HP pump: 20A 240V, 12 AWG', colors.textSecondary),
                _diagramLine('  1.5 HP pump: 20A 240V, 12 AWG', colors.textSecondary),
                _diagramLine('  2 HP pump: 30A 240V, 10 AWG', colors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('All 120V and 240V pool equipment needs GFCI', colors),
          _infoItem('Pump motor must be bonded to grid', colors),
          _infoItem('Variable speed pumps may need neutral', colors),
        ],
      ),
    );
  }

  Widget _diagramLine(String text, Color color) {
    return Text(text, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 10));
  }

  Widget _infoItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: colors.accentPrimary, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildGFCIRequirements(ZaftoColors colors) {
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
            Icon(LucideIcons.shieldCheck, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('GFCI REQUIREMENTS', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text('ALL of the following need GFCI protection:', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          _gfciItem('Pump motors (all voltages)', colors),
          _gfciItem('Underwater lights', colors),
          _gfciItem('All receptacles within 20ft', colors),
          _gfciItem('Heaters', colors),
          _gfciItem('Sanitizer equipment', colors),
          _gfciItem('Any outlet serving pool equipment', colors),
        ],
      ),
    );
  }

  Widget _gfciItem(String text, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(LucideIcons.checkCircle, color: colors.accentInfo, size: 16),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildCodeSummary(ZaftoColors colors) {
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
            Text('NEC 680 REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• 680.21 - Motors\n'
            '• 680.22 - Area lighting\n'
            '• 680.23 - Underwater lighting\n'
            '• 680.26 - Equipotential bonding\n'
            '• 680.42 - Outdoor spas/hot tubs\n'
            '• 680.43 - Indoor spas/hot tubs\n'
            '• 680.71 - Hydromassage bathtubs',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
