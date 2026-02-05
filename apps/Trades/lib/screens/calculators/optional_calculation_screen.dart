import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/zafto_colors.dart';
import '../../theme/theme_provider.dart';

/// Optional Calculation Method - Design System v2.6
/// NEC 220.82/220.83 simplified dwelling load calculation
class OptionalCalculationScreen extends ConsumerStatefulWidget {
  const OptionalCalculationScreen({super.key});
  @override
  ConsumerState<OptionalCalculationScreen> createState() => _OptionalCalculationScreenState();
}

class _OptionalCalculationScreenState extends ConsumerState<OptionalCalculationScreen> {
  final _sqFtController = TextEditingController(text: '2000');
  final _smallApplianceController = TextEditingController(text: '3000');
  final _laundryController = TextEditingController(text: '1500');
  final _rangeController = TextEditingController(text: '12000');
  final _dryerController = TextEditingController(text: '5000');
  final _waterHeaterController = TextEditingController(text: '4500');
  final _acController = TextEditingController(text: '5000');
  final _heatController = TextEditingController(text: '10000');
  bool _isExisting = false; // 220.83 for existing dwellings

  double? _generalLoads;
  double? _heatingAcLoad;
  double? _totalConnected;
  double? _first10kva;
  double? _remainder;
  double? _demandLoad;
  double? _serviceAmps;

  @override
  void initState() { super.initState(); _calculate(); }

  @override
  void dispose() {
    _sqFtController.dispose();
    _smallApplianceController.dispose();
    _laundryController.dispose();
    _rangeController.dispose();
    _dryerController.dispose();
    _waterHeaterController.dispose();
    _acController.dispose();
    _heatController.dispose();
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
        title: Text('Optional Calc', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
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
              _buildSegmentedToggle(colors, label: 'Dwelling Type', options: const ['New (220.82)', 'Existing (220.83)'], selectedIndex: _isExisting ? 1 : 0, onChanged: (i) { setState(() => _isExisting = i == 1); _calculate(); }),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'GENERAL LOADS'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Square Footage', _sqFtController, 'sq ft'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Small Appliance (2 circuits)', _smallApplianceController, 'VA'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Laundry Circuit', _laundryController, 'VA'),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'APPLIANCES'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Range/Oven', _rangeController, 'VA'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Dryer', _dryerController, 'VA'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Water Heater', _waterHeaterController, 'VA'),
              const SizedBox(height: 24),
              _buildSectionHeader(colors, 'HVAC (Largest Only)'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'A/C', _acController, 'VA'),
              const SizedBox(height: 12),
              _buildInputRow(colors, 'Heat', _heatController, 'VA'),
              const SizedBox(height: 32),
              _buildSectionHeader(colors, 'SERVICE CALCULATION'),
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
        Expanded(child: Text('NEC 220.82/83 optional method for dwellings', style: TextStyle(color: colors.accentPrimary, fontSize: 13))),
      ]),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) => Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));

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
              child: Text(options[i], style: TextStyle(color: selectedIndex == i ? (colors.isDark ? Colors.black : Colors.white) : colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildInputRow(ZaftoColors colors, String label, TextEditingController controller, String unit) {
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
            decoration: InputDecoration(isDense: true, border: InputBorder.none, suffixText: unit, suffixStyle: TextStyle(color: colors.textTertiary)),
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
        Text('${_serviceAmps?.toStringAsFixed(0) ?? '0'}', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w700, fontSize: 48)),
        Text('amps @ 240V', style: TextStyle(color: colors.textTertiary, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: colors.accentPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_isExisting ? 'NEC 220.83' : 'NEC 220.82', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 16),
        _buildCalcRow(colors, 'General loads', '${_generalLoads?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Heating/AC (larger)', '${_heatingAcLoad?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Total connected', '${_totalConnected?.toStringAsFixed(0) ?? '0'} VA'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'First 10 kVA @ 100%', '${_first10kva?.toStringAsFixed(0) ?? '0'} VA'),
        _buildCalcRow(colors, 'Remainder @ ${_isExisting ? '40%' : '40%'}', '${_remainder?.toStringAsFixed(0) ?? '0'} VA'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildCalcRow(colors, 'Demand load', '${_demandLoad?.toStringAsFixed(0) ?? '0'} VA', highlight: true),
        _buildCalcRow(colors, 'Service size', '${_serviceAmps?.toStringAsFixed(0) ?? '0'} A', highlight: true),
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
    final sqFt = double.tryParse(_sqFtController.text) ?? 0;
    final smallAppliance = double.tryParse(_smallApplianceController.text) ?? 0;
    final laundry = double.tryParse(_laundryController.text) ?? 0;
    final range = double.tryParse(_rangeController.text) ?? 0;
    final dryer = double.tryParse(_dryerController.text) ?? 0;
    final waterHeater = double.tryParse(_waterHeaterController.text) ?? 0;
    final ac = double.tryParse(_acController.text) ?? 0;
    final heat = double.tryParse(_heatController.text) ?? 0;

    // General lighting @ 3 VA/sq ft
    final lighting = sqFt * 3;

    // General loads (all except heating/AC)
    final general = lighting + smallAppliance + laundry + range + dryer + waterHeater;

    // Use larger of heating or AC (NEC 220.82(C))
    // If heat pump, may use 100% of compressor + 65% of supplemental heat
    final hvacLoad = ac > heat ? ac : heat;

    final total = general + hvacLoad;

    // Apply demand factors per 220.82(B)
    // First 10 kVA @ 100%
    double first10k = total > 10000 ? 10000 : total;

    // Remainder @ 40%
    double remainderAmount = total > 10000 ? (total - 10000) * 0.40 : 0;

    // For existing (220.83), can use different factors for additions
    if (_isExisting) {
      // 220.83 allows different calculation for existing services
      // First 8 kVA @ 100%, remainder @ 40%
      first10k = total > 8000 ? 8000 : total;
      remainderAmount = total > 8000 ? (total - 8000) * 0.40 : 0;
    }

    final demand = first10k + remainderAmount;
    final amps = demand / 240; // Single phase 240V

    setState(() {
      _generalLoads = general;
      _heatingAcLoad = hvacLoad;
      _totalConnected = total;
      _first10kva = first10k;
      _remainder = remainderAmount;
      _demandLoad = demand;
      _serviceAmps = amps;
    });
  }

  void _reset() {
    _sqFtController.text = '2000';
    _smallApplianceController.text = '3000';
    _laundryController.text = '1500';
    _rangeController.text = '12000';
    _dryerController.text = '5000';
    _waterHeaterController.text = '4500';
    _acController.text = '5000';
    _heatController.text = '10000';
    setState(() => _isExisting = false);
    _calculate();
  }
}
