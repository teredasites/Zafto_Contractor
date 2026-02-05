import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Boost Pressure Calculator - PSI to bar conversion and manifold pressure
class BoostPressureScreen extends ConsumerStatefulWidget {
  const BoostPressureScreen({super.key});
  @override
  ConsumerState<BoostPressureScreen> createState() => _BoostPressureScreenState();
}

class _BoostPressureScreenState extends ConsumerState<BoostPressureScreen> {
  final _boostPsiController = TextEditingController();
  final _atmosphericController = TextEditingController(text: '14.7');

  double? _boostBar;
  double? _absolutePressure;
  double? _pressureRatio;

  void _calculate() {
    final boostPsi = double.tryParse(_boostPsiController.text);
    final atmospheric = double.tryParse(_atmosphericController.text) ?? 14.7;

    if (boostPsi == null) {
      setState(() { _boostBar = null; });
      return;
    }

    final boostBar = boostPsi * 0.0689476;
    final absolutePsi = boostPsi + atmospheric;
    final pressureRatio = absolutePsi / atmospheric;

    setState(() {
      _boostBar = boostBar;
      _absolutePressure = absolutePsi;
      _pressureRatio = pressureRatio;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _boostPsiController.clear();
    _atmosphericController.text = '14.7';
    setState(() { _boostBar = null; });
  }

  @override
  void dispose() {
    _boostPsiController.dispose();
    _atmosphericController.dispose();
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
        title: Text('Boost Pressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Boost Pressure', unit: 'psi', hint: 'Gauge reading', controller: _boostPsiController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Atmospheric', unit: 'psi', hint: 'Sea level = 14.7', controller: _atmosphericController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_boostBar != null) _buildResultsCard(colors),
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
        Text('Absolute = Boost + Atmospheric', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Convert and calculate pressure ratio', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BOOST PRESSURE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_boostBar!.toStringAsFixed(2)} bar', style: TextStyle(color: colors.accentPrimary, fontSize: 36, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Absolute Pressure', '${_absolutePressure!.toStringAsFixed(1)} psia'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Pressure Ratio', '${_pressureRatio!.toStringAsFixed(2)}:1'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('QUICK REFERENCE', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('1 bar = 14.5 psi', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text('1 kPa = 0.145 psi', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          ]),
        ),
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
