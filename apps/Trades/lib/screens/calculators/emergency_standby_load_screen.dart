import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Emergency/Standby Load Calculator - Design System v2.6
/// NEC 700/701/702 - Emergency, legally required, optional standby
class EmergencyStandbyLoadScreen extends ConsumerStatefulWidget {
  const EmergencyStandbyLoadScreen({super.key});
  @override
  ConsumerState<EmergencyStandbyLoadScreen> createState() => _EmergencyStandbyLoadScreenState();
}

class _EmergencyStandbyLoadScreenState extends ConsumerState<EmergencyStandbyLoadScreen> {
  // Emergency (Article 700)
  final _egressLightingController = TextEditingController(text: '2000');
  final _exitSignsController = TextEditingController(text: '500');
  final _fireAlarmController = TextEditingController(text: '1500');
  final _firePumpController = TextEditingController(text: '0');

  // Legally Required Standby (Article 701)
  final _smokeControlController = TextEditingController(text: '0');
  final _elevatorsController = TextEditingController(text: '0');
  final _heatingController = TextEditingController(text: '0');

  // Optional Standby (Article 702)
  final _hvacController = TextEditingController(text: '5000');
  final _refrigerationController = TextEditingController(text: '2000');
  final _dataController = TextEditingController(text: '3000');

  double? _emergencyTotal;
  double? _legallyRequiredTotal;
  double? _optionalTotal;
  double? _totalLoad;
  double? _generatorKw;
  String? _transferSwitchSize;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  void dispose() {
    _egressLightingController.dispose();
    _exitSignsController.dispose();
    _fireAlarmController.dispose();
    _firePumpController.dispose();
    _smokeControlController.dispose();
    _elevatorsController.dispose();
    _heatingController.dispose();
    _hvacController.dispose();
    _refrigerationController.dispose();
    _dataController.dispose();
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
        title: Text('Emergency Loads', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildCategoryHeader(colors, 'EMERGENCY (NEC 700)', colors.error),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Egress Lighting', _egressLightingController),
              const SizedBox(height: 8),
              _buildInputRow(colors, 'Exit Signs', _exitSignsController),
              const SizedBox(height: 8),
              _buildInputRow(colors, 'Fire Alarm', _fireAlarmController),
              const SizedBox(height: 8),
              _buildInputRow(colors, 'Fire Pump', _firePumpController),
              const SizedBox(height: 20),
              _buildCategoryHeader(colors, 'LEGALLY REQUIRED STANDBY (NEC 701)', colors.warning),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Smoke Control', _smokeControlController),
              const SizedBox(height: 8),
              _buildInputRow(colors, 'Elevators', _elevatorsController),
              const SizedBox(height: 8),
              _buildInputRow(colors, 'Space Heating', _heatingController),
              const SizedBox(height: 20),
              _buildCategoryHeader(colors, 'OPTIONAL STANDBY (NEC 702)', colors.accentPrimary),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'HVAC', _hvacController),
              const SizedBox(height: 8),
              _buildInputRow(colors, 'Refrigeration', _refrigerationController),
              const SizedBox(height: 8),
              _buildInputRow(colors, 'Data/IT', _dataController),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'GENERATOR SIZING'),
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
        Expanded(child: Text('NEC 700 (10 sec), 701 (60 sec), 702 (optional)', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _buildCategoryHeader(ZaftoColors colors, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

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

  Widget _buildResultCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3), width: 1.5)),
      child: Column(children: [
        Text('${_generatorKw?.toStringAsFixed(0) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('kW generator minimum', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_transferSwitchSize ?? '100A ATS', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        _buildLoadBar(colors, 'Emergency (700)', _emergencyTotal ?? 0, colors.error),
        const SizedBox(height: 8),
        _buildLoadBar(colors, 'Legally Required (701)', _legallyRequiredTotal ?? 0, colors.warning),
        const SizedBox(height: 8),
        _buildLoadBar(colors, 'Optional (702)', _optionalTotal ?? 0, colors.accentPrimary),
        const SizedBox(height: 16),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'Emergency loads', '${_emergencyTotal?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Legally required', '${_legallyRequiredTotal?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Optional standby', '${_optionalTotal?.toStringAsFixed(0) ?? '0'} VA'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Total load', '${_totalLoad?.toStringAsFixed(0) ?? '0'} VA', highlight: true),
        _buildCalcRow(colors, 'Generator size (0.8 PF)', '${_generatorKw?.toStringAsFixed(0) ?? '0'} kW', highlight: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TRANSFER REQUIREMENTS', style: TextStyle(color: colors.accentPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildReqRow(colors, 'Emergency (700)', '10 seconds max'),
            _buildReqRow(colors, 'Legally Required (701)', '60 seconds max'),
            _buildReqRow(colors, 'Optional (702)', 'No time requirement'),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLoadBar(ZaftoColors colors, String label, double value, Color color) {
    final maxVal = (_totalLoad ?? 1) > 0 ? _totalLoad! : 1;
    final pct = value / maxVal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        Text('${value.toStringAsFixed(0)} VA', style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 4),
      Container(
        height: 8,
        decoration: BoxDecoration(color: colors.borderSubtle, borderRadius: BorderRadius.circular(4)),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: pct.clamp(0, 1),
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        ),
      ),
    ]);
  }

  Widget _buildReqRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(LucideIcons.clock, color: colors.textTertiary, size: 12),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        const Spacer(),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
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
    // Emergency loads (NEC 700)
    final emergency = (double.tryParse(_egressLightingController.text) ?? 0) +
        (double.tryParse(_exitSignsController.text) ?? 0) +
        (double.tryParse(_fireAlarmController.text) ?? 0) +
        (double.tryParse(_firePumpController.text) ?? 0);

    // Legally Required Standby (NEC 701)
    final legallyRequired = (double.tryParse(_smokeControlController.text) ?? 0) +
        (double.tryParse(_elevatorsController.text) ?? 0) +
        (double.tryParse(_heatingController.text) ?? 0);

    // Optional Standby (NEC 702)
    final optional = (double.tryParse(_hvacController.text) ?? 0) +
        (double.tryParse(_refrigerationController.text) ?? 0) +
        (double.tryParse(_dataController.text) ?? 0);

    final total = emergency + legallyRequired + optional;

    // Generator sizing: VA / 0.8 PF / 1000 = kW, then add 25% margin
    final genKw = (total / 0.8 / 1000) * 1.25;

    // Transfer switch sizing
    final amps = total / 240; // Assume 240V single phase for residential
    String ats;
    if (amps <= 100) ats = '100A ATS';
    else if (amps <= 200) ats = '200A ATS';
    else if (amps <= 400) ats = '400A ATS';
    else if (amps <= 600) ats = '600A ATS';
    else if (amps <= 800) ats = '800A ATS';
    else ats = '1000A+ ATS';

    setState(() {
      _emergencyTotal = emergency;
      _legallyRequiredTotal = legallyRequired;
      _optionalTotal = optional;
      _totalLoad = total;
      _generatorKw = genKw;
      _transferSwitchSize = ats;
    });
  }

  void _reset() {
    _egressLightingController.text = '2000';
    _exitSignsController.text = '500';
    _fireAlarmController.text = '1500';
    _firePumpController.text = '0';
    _smokeControlController.text = '0';
    _elevatorsController.text = '0';
    _heatingController.text = '0';
    _hvacController.text = '5000';
    _refrigerationController.text = '2000';
    _dataController.text = '3000';
    _calculate();
  }
}
