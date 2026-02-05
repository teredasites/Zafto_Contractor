import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Feeder Calculator - Design System v2.6
/// NEC 220 feeder sizing with demand factors
class FeederCalculatorScreen extends ConsumerStatefulWidget {
  const FeederCalculatorScreen({super.key});
  @override
  ConsumerState<FeederCalculatorScreen> createState() => _FeederCalculatorScreenState();
}

class _FeederCalculatorScreenState extends ConsumerState<FeederCalculatorScreen> {
  final _lightingController = TextEditingController(text: '4500');
  final _receptaclesController = TextEditingController(text: '3000');
  final _appliancesController = TextEditingController(text: '6000');
  final _hvacController = TextEditingController(text: '5000');
  final _motorController = TextEditingController(text: '0');
  int _voltage = 240;
  bool _singlePhase = true;

  double? _totalConnected;
  double? _demandLoad;
  double? _feederAmps;
  String? _wireSize;
  String? _breakerSize;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  void dispose() {
    _lightingController.dispose();
    _receptaclesController.dispose();
    _appliancesController.dispose();
    _hvacController.dispose();
    _motorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase,
        elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Feeder Calculator', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _reset, tooltip: 'Reset')],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(colors),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'LOADS (VA)'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'General Lighting', _lightingController),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Receptacles', _receptaclesController),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Appliances', _appliancesController),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'HVAC', _hvacController),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Motors', _motorController),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'SYSTEM'),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Voltage', options: const ['120V', '208V', '240V', '480V'], selectedIndex: _voltage == 120 ? 0 : _voltage == 208 ? 1 : _voltage == 240 ? 2 : 3, onChanged: (i) { setState(() => _voltage = [120, 208, 240, 480][i]); _calculate(); }),
              const SizedBox(height: 12),
              _buildSegmentedToggle(colors, label: 'Phase', options: const ['1Ø', '3Ø'], selectedIndex: _singlePhase ? 0 : 1, onChanged: (i) { setState(() => _singlePhase = i == 0); _calculate(); }),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'FEEDER SIZING'),
              const SizedBox(height: 12),
              _buildResultCard(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(LucideIcons.info, color: colors.accentPrimary, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text('NEC 220.40 - Feeder calculated load with demand', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildInputRow(ZaftoColors colors, String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14))),
        SizedBox(
          width: 100,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(isDense: true, border: InputBorder.none, suffixText: 'VA', suffixStyle: TextStyle(color: colors.textTertiary)),
            onChanged: (_) => _calculate(),
          ),
        ),
      ]),
    );
  }

  Widget _buildSegmentedToggle(ZaftoColors colors, {required String label, required List<String> options, required int selectedIndex, required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: List.generate(options.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(i); },
            child: Container(
              margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: selectedIndex == i ? colors.accentPrimary : colors.bgBase, borderRadius: BorderRadius.circular(8), border: Border.all(color: selectedIndex == i ? colors.accentPrimary : colors.borderSubtle)),
              alignment: Alignment.center,
              child: Text(options[i], style: TextStyle(color: selectedIndex == i ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_feederAmps?.toStringAsFixed(0) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('amps calculated', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildSpecChip(colors, _breakerSize ?? '100A', 'Breaker'),
          const SizedBox(width: 12),
          _buildSpecChip(colors, _wireSize ?? '#3 Cu', 'Wire'),
        ]),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Total connected', '${_totalConnected?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'After demand factors', '${_demandLoad?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'At ${_voltage}V ${_singlePhase ? '1Ø' : '3Ø'}', '${_feederAmps?.toStringAsFixed(1) ?? '0'} A'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Minimum feeder', '${_feederAmps?.toStringAsFixed(0) ?? '0'} A', highlight: true),
      ]),
    );
  }

  Widget _buildSpecChip(ZaftoColors colors, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label, style: TextStyle(color: colors.textTertiary, fontSize: 10)),
      ]),
    );
  }

  Widget _buildCalcRow(ZaftoColors colors, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: highlight ? colors.textPrimary : colors.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: highlight ? colors.accentPrimary : colors.textPrimary, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, fontSize: 14)),
      ]),
    );
  }

  void _calculate() {
    final lighting = double.tryParse(_lightingController.text) ?? 0;
    final receptacles = double.tryParse(_receptaclesController.text) ?? 0;
    final appliances = double.tryParse(_appliancesController.text) ?? 0;
    final hvac = double.tryParse(_hvacController.text) ?? 0;
    final motors = double.tryParse(_motorController.text) ?? 0;

    final total = lighting + receptacles + appliances + hvac + motors;

    // Apply demand factors (simplified)
    // Lighting: First 3000 @ 100%, rest @ 35%
    double lightingDemand = lighting <= 3000 ? lighting : 3000 + (lighting - 3000) * 0.35;

    // Receptacles: First 10000 @ 100%, rest @ 50%
    double recepDemand = receptacles <= 10000 ? receptacles : 10000 + (receptacles - 10000) * 0.50;

    // Appliances: 100% (unless more than 4)
    double appDemand = appliances;

    // HVAC: 100%
    double hvacDemand = hvac;

    // Motors: 125% of largest (simplified - assume this is the total)
    double motorDemand = motors * 1.25;

    final demand = lightingDemand + recepDemand + appDemand + hvacDemand + motorDemand;

    // Calculate amps
    double amps;
    if (_singlePhase) {
      amps = demand / _voltage;
    } else {
      amps = demand / (_voltage * 1.732);
    }

    // Determine wire and breaker size
    String wire = '';
    String breaker = '';
    if (amps <= 30) { wire = '#10 Cu'; breaker = '30A'; }
    else if (amps <= 40) { wire = '#8 Cu'; breaker = '40A'; }
    else if (amps <= 55) { wire = '#6 Cu'; breaker = '60A'; }
    else if (amps <= 70) { wire = '#4 Cu'; breaker = '70A'; }
    else if (amps <= 85) { wire = '#3 Cu'; breaker = '90A'; }
    else if (amps <= 100) { wire = '#2 Cu'; breaker = '100A'; }
    else if (amps <= 115) { wire = '#1 Cu'; breaker = '125A'; }
    else if (amps <= 130) { wire = '1/0 Cu'; breaker = '150A'; }
    else if (amps <= 150) { wire = '2/0 Cu'; breaker = '175A'; }
    else if (amps <= 175) { wire = '3/0 Cu'; breaker = '200A'; }
    else if (amps <= 200) { wire = '4/0 Cu'; breaker = '225A'; }
    else { wire = '250 kcmil'; breaker = '250A+'; }

    setState(() {
      _totalConnected = total;
      _demandLoad = demand;
      _feederAmps = amps;
      _wireSize = wire;
      _breakerSize = breaker;
    });
  }

  void _reset() {
    _lightingController.text = '4500';
    _receptaclesController.text = '3000';
    _appliancesController.text = '6000';
    _hvacController.text = '5000';
    _motorController.text = '0';
    setState(() {
      _voltage = 240;
      _singlePhase = true;
    });
    _calculate();
  }
}
