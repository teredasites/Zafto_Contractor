import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Travel Speed Calculator - Calculate travel speed from parameters
class TravelSpeedScreen extends ConsumerStatefulWidget {
  const TravelSpeedScreen({super.key});
  @override
  ConsumerState<TravelSpeedScreen> createState() => _TravelSpeedScreenState();
}

class _TravelSpeedScreenState extends ConsumerState<TravelSpeedScreen> {
  final _depositionRateController = TextEditingController(text: '6');
  final _weldAreaController = TextEditingController();
  final _heatInputController = TextEditingController();
  final _voltageController = TextEditingController();
  final _amperageController = TextEditingController();
  String _calcMethod = 'Deposition';

  double? _travelSpeed;
  String? _notes;

  void _calculate() {
    double? travelSpeed;
    String notes;

    if (_calcMethod == 'Deposition') {
      final depositionRate = double.tryParse(_depositionRateController.text);
      final weldArea = double.tryParse(_weldAreaController.text);

      if (depositionRate == null || weldArea == null || weldArea <= 0) {
        setState(() { _travelSpeed = null; });
        return;
      }

      // Travel speed (in/min) = (Deposition Rate lb/hr × 60) / (Weld Area in² × Steel density 0.284 lb/in³)
      travelSpeed = (depositionRate * 60) / (weldArea * 0.284);
      notes = 'Based on deposition rate and required weld area';
    } else {
      final heatInput = double.tryParse(_heatInputController.text);
      final voltage = double.tryParse(_voltageController.text);
      final amperage = double.tryParse(_amperageController.text);

      if (heatInput == null || voltage == null || amperage == null || heatInput <= 0) {
        setState(() { _travelSpeed = null; });
        return;
      }

      // Heat Input (kJ/in) = (V × A × 60) / (Speed × 1000)
      // Speed = (V × A × 60) / (HI × 1000)
      travelSpeed = (voltage * amperage * 60) / (heatInput * 1000);
      notes = 'Calculated to achieve target heat input';
    }

    setState(() {
      _travelSpeed = travelSpeed;
      _notes = notes;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _depositionRateController.text = '6';
    _weldAreaController.clear();
    _heatInputController.clear();
    _voltageController.clear();
    _amperageController.clear();
    setState(() { _travelSpeed = null; });
  }

  @override
  void dispose() {
    _depositionRateController.dispose();
    _weldAreaController.dispose();
    _heatInputController.dispose();
    _voltageController.dispose();
    _amperageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Travel Speed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildMethodSelector(colors),
            const SizedBox(height: 16),
            if (_calcMethod == 'Deposition') ...[
              ZaftoInputField(label: 'Deposition Rate', unit: 'lb/hr', hint: '6 lb/hr typical MIG', controller: _depositionRateController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Weld Area', unit: 'sq in', hint: 'Cross-section area', controller: _weldAreaController, onChanged: (_) => _calculate()),
            ] else ...[
              ZaftoInputField(label: 'Target Heat Input', unit: 'kJ/in', hint: 'Desired heat input', controller: _heatInputController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Voltage', unit: 'V', hint: 'Arc voltage', controller: _voltageController, onChanged: (_) => _calculate()),
              const SizedBox(height: 12),
              ZaftoInputField(label: 'Amperage', unit: 'A', hint: 'Welding current', controller: _amperageController, onChanged: (_) => _calculate()),
            ],
            const SizedBox(height: 32),
            if (_travelSpeed != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(ZaftoColors colors) {
    final methods = ['Deposition', 'Heat Input'];
    return Wrap(
      spacing: 8,
      children: methods.map((m) => ChoiceChip(
        label: Text(m),
        selected: _calcMethod == m,
        onSelected: (_) => setState(() { _calcMethod = m; _calculate(); }),
      )).toList(),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Travel Speed Calculator', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Text('Calculate required travel speed for weld parameters', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Travel Speed', '${_travelSpeed!.toStringAsFixed(1)} IPM', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Feet/min', '${(_travelSpeed! / 12).toStringAsFixed(2)} ft/min'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'mm/sec', '${(_travelSpeed! * 25.4 / 60).toStringAsFixed(1)} mm/s'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(_notes!, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        ),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value, {bool isPrimary = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: isPrimary ? colors.accentPrimary : colors.textPrimary, fontSize: isPrimary ? 24 : 16, fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}
