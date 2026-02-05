import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Payload Calculator - Calculate vehicle payload capacity
class PayloadScreen extends ConsumerStatefulWidget {
  const PayloadScreen({super.key});
  @override
  ConsumerState<PayloadScreen> createState() => _PayloadScreenState();
}

class _PayloadScreenState extends ConsumerState<PayloadScreen> {
  final _gvwrController = TextEditingController();
  final _curbWeightController = TextEditingController();
  final _passengersController = TextEditingController();
  final _cargoController = TextEditingController();

  double? _maxPayload;
  double? _usedPayload;
  double? _remainingPayload;

  void _calculate() {
    final gvwr = double.tryParse(_gvwrController.text);
    final curbWeight = double.tryParse(_curbWeightController.text);
    final passengers = double.tryParse(_passengersController.text) ?? 0;
    final cargo = double.tryParse(_cargoController.text) ?? 0;

    if (gvwr == null || curbWeight == null) {
      setState(() { _maxPayload = null; });
      return;
    }

    // Average passenger weight: 150 lbs
    final passengerWeight = passengers * 150;
    final usedPayload = passengerWeight + cargo;
    final maxPayload = gvwr - curbWeight;
    final remainingPayload = maxPayload - usedPayload;

    setState(() {
      _maxPayload = maxPayload;
      _usedPayload = usedPayload;
      _remainingPayload = remainingPayload;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _gvwrController.clear();
    _curbWeightController.clear();
    _passengersController.clear();
    _cargoController.clear();
    setState(() { _maxPayload = null; });
  }

  @override
  void dispose() {
    _gvwrController.dispose();
    _curbWeightController.dispose();
    _passengersController.dispose();
    _cargoController.dispose();
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
        title: Text('Payload', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            Text('Vehicle Specs', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ZaftoInputField(label: 'GVWR', unit: 'lbs', hint: 'Door sticker', controller: _gvwrController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Curb Weight', unit: 'lbs', hint: 'Empty vehicle', controller: _curbWeightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 16),
            Text('Current Load', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Passengers', unit: '', hint: 'Count', controller: _passengersController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Cargo', unit: 'lbs', hint: 'Weight', controller: _cargoController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_maxPayload != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('Payload = GVWR - Curb Weight', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Calculate how much weight your vehicle can carry', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final isOverloaded = _remainingPayload! < 0;
    final statusColor = isOverloaded ? colors.error : (_remainingPayload! < _maxPayload! * 0.1 ? colors.warning : colors.accentSuccess);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('PAYLOAD ANALYSIS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Max Payload', '${_maxPayload!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Used', '${_usedPayload!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Remaining', '${_remainingPayload!.toStringAsFixed(0)} lbs'),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            isOverloaded ? 'OVERLOADED by ${(-_remainingPayload!).toStringAsFixed(0)} lbs!' :
            _remainingPayload! < _maxPayload! * 0.1 ? 'Near capacity - drive carefully' :
            'Within safe payload limits',
            style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_usedPayload! / _maxPayload!).clamp(0, 1),
          backgroundColor: colors.bgBase,
          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
        ),
        const SizedBox(height: 8),
        Text('${((_usedPayload! / _maxPayload!) * 100).toStringAsFixed(0)}% capacity used', style: TextStyle(color: colors.textTertiary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildResultRow(ZaftoColors colors, String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}
