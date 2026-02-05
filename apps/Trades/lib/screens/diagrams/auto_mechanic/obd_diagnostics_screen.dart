import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';

class ObdDiagnosticsScreen extends ConsumerWidget {
  const ObdDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(zaftoColorsProvider);

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        title: Text(
          'OBD-II Diagnostics',
          style: TextStyle(color: colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDtcFormat(colors),
            const SizedBox(height: 24),
            _buildCommonCodes(colors),
            const SizedBox(height: 24),
            _buildMonitorStatus(colors),
            const SizedBox(height: 24),
            _buildLiveData(colors),
            const SizedBox(height: 24),
            _buildConnectorLocation(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildDtcFormat(ZaftoColors colors) {
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
              Icon(LucideIcons.fileCode, color: colors.accentPrimary, size: 24),
              const SizedBox(width: 12),
              Text(
                'DTC Code Format',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''OBD-II CODE STRUCTURE

        P 0 1 3 5
        │ │ │ └─┴── Specific fault (00-99)
        │ │ │
        │ │ └────── Subsystem
        │ │         1 = Fuel/Air
        │ │         2 = Fuel/Air
        │ │         3 = Ignition
        │ │         4 = Emissions
        │ │         5 = Speed/Idle
        │ │         6 = Computer
        │ │         7 = Transmission
        │ │         8 = Transmission
        │ │
        │ └──────── Code Type
        │           0 = Generic/SAE
        │           1 = Manufacturer
        │
        └────────── System
                    P = Powertrain
                    B = Body
                    C = Chassis
                    U = Network''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonCodes(ZaftoColors colors) {
    final codes = [
      {'code': 'P0300', 'desc': 'Random/Multiple Misfire', 'system': 'Ignition'},
      {'code': 'P0171', 'desc': 'System Too Lean (Bank 1)', 'system': 'Fuel'},
      {'code': 'P0420', 'desc': 'Catalyst Efficiency Below', 'system': 'Emissions'},
      {'code': 'P0442', 'desc': 'EVAP Small Leak', 'system': 'EVAP'},
      {'code': 'P0401', 'desc': 'EGR Flow Insufficient', 'system': 'EGR'},
      {'code': 'P0505', 'desc': 'Idle Control System', 'system': 'Idle'},
      {'code': 'P0133', 'desc': 'O2 Sensor Slow Response', 'system': 'O2'},
      {'code': 'P0455', 'desc': 'EVAP Large Leak', 'system': 'EVAP'},
      {'code': 'P0128', 'desc': 'Coolant Temp Below', 'system': 'Cooling'},
      {'code': 'P0700', 'desc': 'Transmission Control', 'system': 'Trans'},
    ];

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
              Icon(LucideIcons.alertTriangle, color: colors.accentWarning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Common DTCs',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...codes.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentError.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(c['code']!, style: TextStyle(color: colors.accentError, fontSize: 10, fontFamily: 'monospace'), textAlign: TextAlign.center),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(c['desc']!, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentInfo.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(c['system']!, style: TextStyle(color: colors.accentInfo, fontSize: 9)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMonitorStatus(ZaftoColors colors) {
    final monitors = [
      {'monitor': 'Catalyst', 'conditions': 'Extended driving, warm engine', 'trips': '1'},
      {'monitor': 'Heated Catalyst', 'conditions': 'Various speeds, temps', 'trips': '1'},
      {'monitor': 'EVAP', 'conditions': 'Fuel 15-85%, cold soak', 'trips': '1'},
      {'monitor': 'Secondary Air', 'conditions': 'Cold start', 'trips': '1'},
      {'monitor': 'Oxygen Sensor', 'conditions': 'Warm engine, various load', 'trips': '1'},
      {'monitor': 'O2 Heater', 'conditions': 'Engine running', 'trips': '1'},
      {'monitor': 'EGR', 'conditions': 'Decel, cruise', 'trips': '1'},
      {'monitor': 'Misfire', 'conditions': 'Continuous', 'trips': '1-2'},
      {'monitor': 'Fuel System', 'conditions': 'Continuous', 'trips': '1-2'},
      {'monitor': 'Components', 'conditions': 'Continuous', 'trips': '1'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgInset,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.checkCircle, color: colors.accentSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Readiness Monitors',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All monitors must complete for emissions testing',
            style: TextStyle(color: colors.textTertiary, fontSize: 10, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          ...monitors.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(m['monitor']!, style: TextStyle(color: colors.textPrimary, fontSize: 10)),
                ),
                Expanded(
                  child: Text(m['conditions']!, style: TextStyle(color: colors.textSecondary, fontSize: 9)),
                ),
                Text('${m['trips']} trip', style: TextStyle(color: colors.accentInfo, fontSize: 9)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLiveData(ZaftoColors colors) {
    final pids = [
      {'pid': 'RPM', 'normal': '650-900 idle', 'unit': 'RPM'},
      {'pid': 'Coolant Temp', 'normal': '195-220°F', 'unit': '°F'},
      {'pid': 'Intake Temp', 'normal': 'Ambient +10-20', 'unit': '°F'},
      {'pid': 'MAF', 'normal': '3-7 g/s idle', 'unit': 'g/s'},
      {'pid': 'MAP', 'normal': '1-2 inHg idle', 'unit': 'inHg'},
      {'pid': 'Short Term FT', 'normal': '±10%', 'unit': '%'},
      {'pid': 'Long Term FT', 'normal': '±10%', 'unit': '%'},
      {'pid': 'O2 Voltage', 'normal': '0.1-0.9V cycling', 'unit': 'V'},
      {'pid': 'Timing Advance', 'normal': '10-20° idle', 'unit': '°'},
      {'pid': 'Throttle Position', 'normal': '0-100%', 'unit': '%'},
    ];

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
              Icon(LucideIcons.activity, color: colors.accentInfo, size: 20),
              const SizedBox(width: 8),
              Text(
                'Live Data PIDs',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pids.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(p['pid']!, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(p['normal']!, style: TextStyle(color: colors.accentSuccess, fontSize: 10)),
                ),
                Text(p['unit']!, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildConnectorLocation(ZaftoColors colors) {
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
              Icon(LucideIcons.plug, color: colors.accentPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'OBD-II Connector',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgInset,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '''OBD-II PORT PINOUT (16-pin)

    ┌─────────────────────────────┐
    │  1   2   3   4   5   6   7  8│
    │  ○   ○   ○   ○   ○   ○   ○  ○│
    │                              │
    │  ○   ○   ○   ○   ○   ○   ○  ○│
    │  9  10  11  12  13  14  15 16│
    └─────────────────────────────┘

Key Pins:
• Pin 4: Chassis ground
• Pin 5: Signal ground
• Pin 6: CAN High (J-2284)
• Pin 7: K-Line (ISO 9141)
• Pin 14: CAN Low (J-2284)
• Pin 16: Battery positive

LOCATION: Within 2 feet of steering
column, usually under dash''',
              style: TextStyle(
                color: colors.textSecondary,
                fontFamily: 'monospace',
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accentInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: colors.accentInfo, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'OBD-II mandatory on all US vehicles 1996+. Port provides power for scan tool.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
