import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Sensor Range Calculator - Automotive sensor specifications
class SensorRangeScreen extends ConsumerStatefulWidget {
  const SensorRangeScreen({super.key});
  @override
  ConsumerState<SensorRangeScreen> createState() => _SensorRangeScreenState();
}

class _SensorRangeScreenState extends ConsumerState<SensorRangeScreen> {
  String _selectedSensor = 'map';

  final Map<String, Map<String, dynamic>> _sensors = {
    'map': {
      'name': 'MAP Sensor',
      'fullName': 'Manifold Absolute Pressure',
      'range': '0-5V',
      'typical': '0.5V idle, 4.5V WOT',
      'signal': 'Analog voltage',
      'symptoms': 'Rough idle, poor fuel economy, no-start',
    },
    'maf': {
      'name': 'MAF Sensor',
      'fullName': 'Mass Air Flow',
      'range': '0-5V or frequency',
      'typical': '0.5-1V idle, 2-4V cruising',
      'signal': 'Analog or digital',
      'symptoms': 'Stalling, hesitation, black smoke',
    },
    'tps': {
      'name': 'TPS',
      'fullName': 'Throttle Position Sensor',
      'range': '0.5-4.5V',
      'typical': '0.5V closed, 4.5V WOT',
      'signal': 'Analog voltage',
      'symptoms': 'Surging, poor acceleration, stalling',
    },
    'ect': {
      'name': 'ECT Sensor',
      'fullName': 'Engine Coolant Temperature',
      'range': '0.5-4.5V',
      'typical': '3.5V cold, 0.5V hot',
      'signal': 'Thermistor (NTC)',
      'symptoms': 'Poor fuel economy, hard start, overheating',
    },
    'iat': {
      'name': 'IAT Sensor',
      'fullName': 'Intake Air Temperature',
      'range': '0.5-4.5V',
      'typical': '3V cold air, 1V hot air',
      'signal': 'Thermistor (NTC)',
      'symptoms': 'Poor fuel trim, rough running',
    },
    'o2': {
      'name': 'O2 Sensor',
      'fullName': 'Oxygen Sensor (Narrowband)',
      'range': '0.1-0.9V',
      'typical': 'Oscillates 0.1-0.9V',
      'signal': 'Analog voltage',
      'symptoms': 'Poor fuel economy, failed emissions',
    },
    'crank': {
      'name': 'CKP Sensor',
      'fullName': 'Crankshaft Position',
      'range': 'AC voltage or digital',
      'typical': '0.2-5V AC, varies with RPM',
      'signal': 'Reluctor or Hall effect',
      'symptoms': 'No-start, random misfires, stalling',
    },
    'cam': {
      'name': 'CMP Sensor',
      'fullName': 'Camshaft Position',
      'range': '0-5V or AC',
      'typical': 'Square wave or AC',
      'signal': 'Hall effect or reluctor',
      'symptoms': 'No-start, rough running, poor timing',
    },
    'knock': {
      'name': 'Knock Sensor',
      'fullName': 'Knock/Detonation Sensor',
      'range': 'AC voltage',
      'typical': '0.02-0.5V AC',
      'signal': 'Piezoelectric',
      'symptoms': 'Spark retard, poor performance, pinging',
    },
    'fuel_press': {
      'name': 'Fuel Pressure',
      'fullName': 'Fuel Rail Pressure Sensor',
      'range': '0-5V',
      'typical': '1.5-2.5V typical',
      'signal': 'Analog voltage',
      'symptoms': 'Limp mode, no-start, poor performance',
    },
  };

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Sensor Specs', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSensorSelector(colors),
            const SizedBox(height: 24),
            _buildSensorDetail(colors),
            const SizedBox(height: 24),
            _buildTestingTips(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSensorSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SELECT SENSOR', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _sensors.keys.map((key) => _buildSensorChip(colors, key)).toList()),
      ]),
    );
  }

  Widget _buildSensorChip(ZaftoColors colors, String key) {
    final isSelected = _selectedSensor == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() { _selectedSensor = key; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle),
        ),
        child: Text(_sensors[key]!['name'], style: TextStyle(color: isSelected ? colors.bgBase : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSensorDetail(ZaftoColors colors) {
    final sensor = _sensors[_selectedSensor]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(sensor['name'], style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
        Text(sensor['fullName'], style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        _buildSpecRow(colors, 'Voltage Range', sensor['range']),
        _buildSpecRow(colors, 'Typical Values', sensor['typical']),
        _buildSpecRow(colors, 'Signal Type', sensor['signal']),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Failure Symptoms:', style: TextStyle(color: colors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(sensor['symptoms'], style: TextStyle(color: colors.textPrimary, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpecRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 12))),
        Expanded(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildTestingTips(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TESTING TIPS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('• Use a multimeter on DC voltage', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Back-probe connectors, don\'t pierce wires', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Check for 5V reference and ground first', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Compare live data to specs', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Scope testing shows intermittent faults', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text('• Always check wiring before replacing sensor', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
