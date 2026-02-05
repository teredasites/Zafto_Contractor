import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Low Voltage Wiring Diagram - Design System v2.6
class LowVoltageScreen extends ConsumerWidget {
  const LowVoltageScreen({super.key});

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
        title: Text('Low Voltage Wiring', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverview(colors),
            const SizedBox(height: 16),
            _buildDoorbellWiring(colors),
            const SizedBox(height: 16),
            _buildThermostatWiring(colors),
            const SizedBox(height: 16),
            _buildLandscapeLighting(colors),
            const SizedBox(height: 16),
            _buildSprinklerWiring(colors),
            const SizedBox(height: 16),
            _buildCodeReference(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(ZaftoColors colors) {
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
            Icon(LucideIcons.info, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('What is Low Voltage?', style: TextStyle(color: colors.accentPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          Text(
            'Low voltage systems operate below 50V and include doorbells, thermostats, landscape lighting, and irrigation controllers. These systems are safer and often exempt from standard electrical permits.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDoorbellWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.bellRing, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('DOORBELL WIRING (16-24V AC)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('120V ──► TRANSFORMER ──► 16-24V AC', colors.accentError),
                _diagramLine('              │', colors.textTertiary),
                _diagramLine('              ├───────► CHIME ◄───────┐', colors.accentPrimary),
                _diagramLine('              │           │           │', colors.textTertiary),
                _diagramLine('              │        FRONT        REAR', colors.textTertiary),
                _diagramLine('              │        BUTTON      BUTTON', colors.accentSuccess),
                _diagramLine('              │           │           │', colors.textTertiary),
                _diagramLine('              └───────────┴───────────┘', colors.textTertiary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('18-20 AWG thermostat wire', colors),
          _infoItem('Video doorbells: 16-24V AC, check VA rating', colors),
          _infoItem('Ring/Nest: minimum 16V 30VA transformer', colors),
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

  Widget _buildThermostatWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.thermometer, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Text('THERMOSTAT WIRE COLORS (24V)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          _thermoRow('R', 'Red', '24V Power', Colors.red, colors),
          _thermoRow('Rc', 'Red', '24V Cooling', Colors.red, colors),
          _thermoRow('Rh', 'Red', '24V Heating', Colors.red, colors),
          _thermoRow('C', 'Blue', 'Common (return)', Colors.blue, colors),
          _thermoRow('G', 'Green', 'Fan', Colors.green, colors),
          _thermoRow('Y', 'Yellow', 'Cooling', Colors.yellow, colors),
          _thermoRow('Y2', 'Yellow', 'Stage 2 Cool', Colors.yellow, colors),
          _thermoRow('W', 'White', 'Heat', Colors.white, colors),
          _thermoRow('W2', 'White', 'Aux/Stage 2', Colors.white, colors),
          _thermoRow('O/B', 'Orange', 'Heat pump reverse', Colors.orange, colors),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text('Smart thermostats REQUIRE C wire. No C? Use add-a-wire kit.', style: TextStyle(color: colors.accentInfo, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _thermoRow(String term, String color, String func, Color dotColor, ZaftoColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 35, child: Text(term, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 12))),
        Container(width: 14, height: 14, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, border: dotColor == Colors.white ? Border.all(color: colors.borderSubtle) : null)),
        SizedBox(width: 60, child: Text(color, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Expanded(child: Text(func, style: TextStyle(color: colors.textTertiary, fontSize: 12))),
      ]),
    );
  }

  Widget _buildLandscapeLighting(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.sun, color: colors.accentWarning, size: 20),
            const SizedBox(width: 8),
            Text('LANDSCAPE LIGHTING (12V)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('120V GFCI ──► TRANSFORMER ──► 12V AC', colors.accentError),
                _diagramLine('                   │', colors.textTertiary),
                _diagramLine('    ┌──────────────┼──────────────┐', colors.textTertiary),
                _diagramLine('    │              │              │', colors.textTertiary),
                _diagramLine('   ○ Light    ○ Light    ○ Light', colors.accentWarning),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('12-16 AWG direct burial cable', colors),
          _infoItem('Total watts / 12V = amps needed', colors),
          _infoItem('Max 80% transformer capacity', colors),
          _infoItem('Voltage drop: use larger wire for long runs', colors),
        ],
      ),
    );
  }

  Widget _buildSprinklerWiring(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LucideIcons.droplets, color: colors.accentInfo, size: 20),
            const SizedBox(width: 8),
            Text('SPRINKLER/IRRIGATION (24V AC)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.bgInset, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _diagramLine('CONTROLLER (24V AC out)', colors.textTertiary),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('    ├─ Zone 1 ──► Valve 1', colors.accentError),
                _diagramLine('    ├─ Zone 2 ──► Valve 2', colors.accentWarning),
                _diagramLine('    ├─ Zone 3 ──► Valve 3', colors.accentSuccess),
                _diagramLine('    │', colors.textTertiary),
                _diagramLine('    └─ COMMON ──► All Valves', colors.textPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _infoItem('18 AWG multi-conductor direct burial', colors),
          _infoItem('One wire per zone + one common', colors),
          _infoItem('Common connects to one side of ALL valves', colors),
          _infoItem('Waterproof wire nuts (silicone filled)', colors),
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
          Row(children: [
            Icon(LucideIcons.bookOpen, color: colors.accentInfo, size: 18),
            const SizedBox(width: 8),
            Text('NEC REFERENCE', style: TextStyle(color: colors.accentInfo, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 12),
          Text(
            '• NEC Article 725 - Class 2 and Class 3 Circuits\n'
            '• NEC 411 - Low-Voltage Lighting\n'
            '• NEC 720 - Circuits Less Than 50 Volts\n'
            '• Class 2 circuits: power-limited, inherently safe\n'
            '• No conduit required for Class 2 wiring',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
