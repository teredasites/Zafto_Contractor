import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/zafto/zafto_widgets.dart';

/// Motor Circuit Calculator - Design System v2.6
class MotorCircuitScreen extends ConsumerStatefulWidget {
  const MotorCircuitScreen({super.key});
  @override
  ConsumerState<MotorCircuitScreen> createState() => _MotorCircuitScreenState();
}

enum MotorType { squirrelCage('Squirrel Cage'), woundRotor('Wound Rotor'), synchronous('Synchronous'); const MotorType(this.displayName); final String displayName; }

class _MotorCircuitScreenState extends ConsumerState<MotorCircuitScreen> {
  final _hpController = TextEditingController();
  final _flaController = TextEditingController();
  int _voltage = 460;
  bool _isThreePhase = true;
  MotorType _motorType = MotorType.squirrelCage;
  Map<String, dynamic>? _results;

  static final Map<int, Map<double, double>> _flaTable3Phase = {
    208: {0.5: 2.4, 0.75: 3.5, 1: 4.6, 1.5: 6.6, 2: 7.5, 3: 10.6, 5: 16.7, 7.5: 24.2, 10: 30.8, 15: 46.2, 20: 59.4, 25: 74.8, 30: 88.0, 40: 114.0, 50: 143.0, 60: 169.0, 75: 211.0, 100: 273.0},
    230: {0.5: 2.2, 0.75: 3.2, 1: 4.2, 1.5: 6.0, 2: 6.8, 3: 9.6, 5: 15.2, 7.5: 22.0, 10: 28.0, 15: 42.0, 20: 54.0, 25: 68.0, 30: 80.0, 40: 104.0, 50: 130.0, 60: 154.0, 75: 192.0, 100: 248.0},
    460: {0.5: 1.1, 0.75: 1.6, 1: 2.1, 1.5: 3.0, 2: 3.4, 3: 4.8, 5: 7.6, 7.5: 11.0, 10: 14.0, 15: 21.0, 20: 27.0, 25: 34.0, 30: 40.0, 40: 52.0, 50: 65.0, 60: 77.0, 75: 96.0, 100: 124.0, 125: 156.0, 150: 180.0, 200: 240.0},
    575: {0.5: 0.9, 0.75: 1.3, 1: 1.7, 1.5: 2.4, 2: 2.7, 3: 3.9, 5: 6.1, 7.5: 9.0, 10: 11.0, 15: 17.0, 20: 22.0, 25: 27.0, 30: 32.0, 40: 41.0, 50: 52.0, 60: 62.0, 75: 77.0, 100: 99.0},
  };

  static const Map<MotorType, Map<String, double>> _branchProtection = {
    MotorType.squirrelCage: {'Dual Element Fuse': 1.75, 'Instantaneous Breaker': 8.0, 'Inverse Time Breaker': 2.5, 'Non-Time Delay Fuse': 3.0},
    MotorType.woundRotor: {'Dual Element Fuse': 1.5, 'Instantaneous Breaker': 8.0, 'Inverse Time Breaker': 1.5, 'Non-Time Delay Fuse': 1.5},
    MotorType.synchronous: {'Dual Element Fuse': 1.75, 'Instantaneous Breaker': 8.0, 'Inverse Time Breaker': 2.5, 'Non-Time Delay Fuse': 3.0},
  };

  static const List<int> _standardSizes = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200, 225, 250, 300, 350, 400, 450, 500, 600, 700, 800];

  @override
  void dispose() { _hpController.dispose(); _flaController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Motor Circuit', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildNecCard(colors),
            const SizedBox(height: 24),
            Text('MOTOR SPECIFICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildPhaseSelector(colors),
            const SizedBox(height: 12),
            ZaftoInputFieldDropdown<int>(label: 'Voltage', value: _voltage, items: const [208, 230, 460, 575], itemLabel: (v) => '$v V', onChanged: (v) { setState(() => _voltage = v); _lookupFLA(); }),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Horsepower', unit: 'HP', hint: 'Motor HP', controller: _hpController, onChanged: (_) => _lookupFLA()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Full Load Amps', unit: 'A', hint: 'From nameplate', controller: _flaController),
            const SizedBox(height: 8),
            Text('FLA auto-filled from NEC tables, or enter nameplate value', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
            const SizedBox(height: 12),
            ZaftoInputFieldDropdown<MotorType>(label: 'Motor Type', value: _motorType, items: MotorType.values, itemLabel: (t) => t.displayName, onChanged: (v) => setState(() => _motorType = v)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: colors.accentPrimary, foregroundColor: colors.isDark ? Colors.black : Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('SIZE CIRCUIT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1))),
            const SizedBox(height: 24),
            if (_results != null) _buildResults(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildNecCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(LucideIcons.bookOpen, color: colors.accentPrimary, size: 20), const SizedBox(width: 8), Text('NEC Article 430', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 8),
        Text('• 430.22 - Conductor sizing\n• 430.52 - Branch circuit protection\n• 430.32 - Overload protection', style: TextStyle(color: colors.textTertiary, fontSize: 11, height: 1.5)),
      ]),
    );
  }

  Widget _buildPhaseSelector(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [false, true].map((v) {
        final isSelected = v == _isThreePhase;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() { _isThreePhase = v; _lookupFLA(); }); },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(v ? '3-PHASE' : '1-PHASE', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600))),
        ));
      }).toList()),
    );
  }

  Widget _buildResults(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.accentSuccess.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Icon(LucideIcons.settings, color: colors.accentSuccess), const SizedBox(width: 8), Text('MOTOR CIRCUIT COMPONENTS', style: TextStyle(color: colors.accentSuccess, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1))]),
        const SizedBox(height: 20),
        _buildResultCard(colors, LucideIcons.zap, 'Conductors', _results!['conductor'], 'Min ${_results!['conductorAmps'].toStringAsFixed(1)}A capacity (125% × FLA)', colors.accentWarning),
        const SizedBox(height: 12),
        _buildResultCard(colors, LucideIcons.zap, 'Branch Protection (Max)', '${_results!['branchProtection']}A', _results!['branchNote'], colors.accentError),
        const SizedBox(height: 12),
        _buildResultCard(colors, LucideIcons.thermometer, 'Overload Protection', '${_results!['overloadMin'].toStringAsFixed(1)} - ${_results!['overloadMax'].toStringAsFixed(1)}A', '115-125% of nameplate FLA', colors.accentPrimary),
        const SizedBox(height: 12),
        _buildResultCard(colors, LucideIcons.powerOff, 'Disconnect (Min)', '${_results!['disconnect']}A', '115% of FLA', colors.accentSuccess),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors, IconData icon, String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(subtitle, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
        ])),
      ]),
    );
  }

  void _lookupFLA() {
    final hp = double.tryParse(_hpController.text);
    if (hp == null || hp <= 0) return;
    if (_isThreePhase) { final table = _flaTable3Phase[_voltage]; if (table != null && table.containsKey(hp)) { _flaController.text = table[hp]!.toString(); } }
  }

  void _calculate() {
    final fla = double.tryParse(_flaController.text);
    if (fla == null || fla <= 0) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Enter valid FLA'), backgroundColor: ref.read(zaftoColorsProvider).accentError)); return; }
    final conductorAmps = fla * 1.25;
    final protectionMultipliers = _branchProtection[_motorType]!;
    final maxBranch = (fla * protectionMultipliers['Inverse Time Breaker']!).ceil();
    final standardBranch = _getNextStandardSize(maxBranch.toDouble());
    String conductor;
    if (conductorAmps <= 15) conductor = '14 AWG'; else if (conductorAmps <= 20) conductor = '12 AWG'; else if (conductorAmps <= 30) conductor = '10 AWG'; else if (conductorAmps <= 40) conductor = '8 AWG'; else if (conductorAmps <= 55) conductor = '6 AWG'; else if (conductorAmps <= 70) conductor = '4 AWG'; else if (conductorAmps <= 85) conductor = '3 AWG'; else if (conductorAmps <= 95) conductor = '2 AWG'; else if (conductorAmps <= 110) conductor = '1 AWG'; else if (conductorAmps <= 125) conductor = '1/0 AWG'; else if (conductorAmps <= 145) conductor = '2/0 AWG'; else if (conductorAmps <= 165) conductor = '3/0 AWG'; else if (conductorAmps <= 195) conductor = '4/0 AWG'; else if (conductorAmps <= 230) conductor = '250 kcmil'; else if (conductorAmps <= 255) conductor = '300 kcmil'; else if (conductorAmps <= 285) conductor = '350 kcmil'; else conductor = '400+ kcmil';
    setState(() { _results = {'conductor': conductor, 'conductorAmps': conductorAmps, 'branchProtection': standardBranch, 'branchNote': 'Inverse time breaker @ 250%', 'overloadMin': fla * 1.15, 'overloadMax': fla * 1.25, 'disconnect': _getNextStandardSize(fla * 1.15)}; });
  }

  int _getNextStandardSize(double amps) { for (final size in _standardSizes) { if (size >= amps) return size; } return _standardSizes.last; }
  void _reset() { _hpController.clear(); _flaController.clear(); setState(() { _voltage = 460; _isThreePhase = true; _motorType = MotorType.squirrelCage; _results = null; }); }
}
