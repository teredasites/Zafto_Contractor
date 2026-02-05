import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Smoke Detector Calculator - Required detector placement
class SmokeDetectorScreen extends ConsumerStatefulWidget {
  const SmokeDetectorScreen({super.key});
  @override
  ConsumerState<SmokeDetectorScreen> createState() => _SmokeDetectorScreenState();
}

class _SmokeDetectorScreenState extends ConsumerState<SmokeDetectorScreen> {
  final _bedroomsController = TextEditingController(text: '4');
  final _floorsController = TextEditingController(text: '2');
  final _basementController = TextEditingController(text: '1');

  bool _hasGarage = true;

  int? _inBedrooms;
  int? _hallways;
  int? _basement;
  int? _garage;
  int? _total;

  @override
  void dispose() { _bedroomsController.dispose(); _floorsController.dispose(); _basementController.dispose(); super.dispose(); }

  void _calculate() {
    final bedrooms = int.tryParse(_bedroomsController.text) ?? 0;
    final floors = int.tryParse(_floorsController.text) ?? 1;
    final basementQty = int.tryParse(_basementController.text) ?? 0;

    // IRC R314 requirements
    // In each bedroom
    final inBedrooms = bedrooms;

    // Outside each sleeping area on each floor
    final hallways = floors;

    // Each basement level
    final basement = basementQty;

    // Garage (heat detector, not smoke)
    final garage = _hasGarage ? 1 : 0;

    final total = inBedrooms + hallways + basement + garage;

    setState(() { _inBedrooms = inBedrooms; _hallways = hallways; _basement = basement; _garage = garage; _total = total; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _bedroomsController.text = '4'; _floorsController.text = '2'; _basementController.text = '1'; setState(() => _hasGarage = true); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Smoke Detectors', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Bedrooms', unit: 'qty', controller: _bedroomsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Floors', unit: 'levels', controller: _floorsController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Basement Levels', unit: 'qty', controller: _basementController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: _buildToggle(colors, 'Attached Garage', _hasGarage, (v) { setState(() => _hasGarage = v); _calculate(); })),
            ]),
            const SizedBox(height: 32),
            if (_total != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL REQUIRED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_total', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('In Bedrooms', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_inBedrooms', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hallways/Floors', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hallways', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Basement', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_basement', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Garage (heat)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_garage', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('All smoke alarms must be interconnected. Hardwired with battery backup required in new construction.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildRequirementsTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
          child: Center(child: Text(value ? 'Yes' : 'No', style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
        ),
      ),
    ]);
  }

  Widget _buildRequirementsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('IRC R314 PLACEMENT', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Inside each bedroom', 'Required'),
        _buildTableRow(colors, 'Outside sleeping areas', 'Each floor'),
        _buildTableRow(colors, 'Each story including basement', 'Required'),
        _buildTableRow(colors, 'Ceiling mount', '4" from wall'),
        _buildTableRow(colors, 'Wall mount', '4"-12" from ceiling'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
