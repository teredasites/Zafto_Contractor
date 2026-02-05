import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Parasitic Draw Calculator - Battery drain diagnosis
class ParasiticDrawScreen extends ConsumerStatefulWidget {
  const ParasiticDrawScreen({super.key});
  @override
  ConsumerState<ParasiticDrawScreen> createState() => _ParasiticDrawScreenState();
}

class _ParasiticDrawScreenState extends ConsumerState<ParasiticDrawScreen> {
  final _drawMilliampsController = TextEditingController();
  final _batteryAhController = TextEditingController(text: '60');

  double? _daysToFlat;
  bool? _isAcceptable;

  void _calculate() {
    final drawMa = double.tryParse(_drawMilliampsController.text);
    final batteryAh = double.tryParse(_batteryAhController.text);

    if (drawMa == null || batteryAh == null) {
      setState(() { _daysToFlat = null; });
      return;
    }

    // Hours to drain = (Battery Ah × 1000) / Draw mA
    // Days = Hours / 24
    // Consider battery dead at 50% discharge
    final hoursToFlat = (batteryAh * 1000 * 0.5) / drawMa;
    final days = hoursToFlat / 24;
    final acceptable = drawMa <= 50; // 50mA is typical max acceptable

    setState(() {
      _daysToFlat = days;
      _isAcceptable = acceptable;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _drawMilliampsController.clear();
    _batteryAhController.text = '60';
    setState(() { _daysToFlat = null; });
  }

  @override
  void dispose() {
    _drawMilliampsController.dispose();
    _batteryAhController.dispose();
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
        title: Text('Parasitic Draw', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Measured Draw', unit: 'mA', hint: 'After sleep mode', controller: _drawMilliampsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Battery Capacity', unit: 'Ah', hint: 'Typical: 50-80 Ah', controller: _batteryAhController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_daysToFlat != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildTestingCard(colors),
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
        Text('Days = (Ah × 500) / mA / 24', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Acceptable draw: 25-50 mA for modern vehicles', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final statusColor = _isAcceptable! ? colors.accentSuccess : colors.error;
    final drawMa = double.tryParse(_drawMilliampsController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Days to Flat Battery', '${_daysToFlat!.toStringAsFixed(1)} days', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(_isAcceptable! ? 'ACCEPTABLE' : 'EXCESSIVE DRAW', style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_isAcceptable! ? 'Draw is within normal range' : 'Investigate source - pull fuses one at a time', style: TextStyle(color: statusColor.withValues(alpha: 0.8), fontSize: 12)),
          ]),
        ),
        if (!_isAcceptable!) ...[
          const SizedBox(height: 12),
          Text('${(drawMa - 50).toStringAsFixed(0)} mA over acceptable limit', style: TextStyle(color: colors.error, fontSize: 13)),
        ],
      ]),
    );
  }

  Widget _buildTestingCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TESTING PROCEDURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Text('1. Turn off all accessories\n2. Close all doors (use latch tool)\n3. Wait 30-60 min for modules to sleep\n4. Connect ammeter in series with battery\n5. Read milliamp draw\n6. If excessive, pull fuses one at a time to isolate circuit', style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
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
