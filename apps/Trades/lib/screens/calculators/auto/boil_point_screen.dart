import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Boil Point Calculator - Coolant boiling point with pressure
class BoilPointScreen extends ConsumerStatefulWidget {
  const BoilPointScreen({super.key});
  @override
  ConsumerState<BoilPointScreen> createState() => _BoilPointScreenState();
}

class _BoilPointScreenState extends ConsumerState<BoilPointScreen> {
  final _glycolPercentController = TextEditingController(text: '50');
  final _systemPressureController = TextEditingController(text: '15');

  double? _boilPoint;
  double? _unpressurizedBoil;

  void _calculate() {
    final glycolPercent = double.tryParse(_glycolPercentController.text);
    final systemPressure = double.tryParse(_systemPressureController.text) ?? 15;

    if (glycolPercent == null) {
      setState(() { _boilPoint = null; });
      return;
    }

    // Base boiling point of water at sea level: 212°F
    // Ethylene glycol raises boiling point
    double baseBoil;
    if (glycolPercent <= 30) {
      baseBoil = 212 + (glycolPercent * 0.3);
    } else if (glycolPercent <= 50) {
      baseBoil = 220 + ((glycolPercent - 30) * 0.4);
    } else if (glycolPercent <= 70) {
      baseBoil = 228 + ((glycolPercent - 50) * 0.5);
    } else {
      baseBoil = 238 + ((glycolPercent - 70) * 0.3);
    }

    // Pressure raises boiling point: ~3°F per PSI
    final pressurizedBoil = baseBoil + (systemPressure * 3);

    setState(() {
      _unpressurizedBoil = baseBoil;
      _boilPoint = pressurizedBoil;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _glycolPercentController.text = '50';
    _systemPressureController.text = '15';
    setState(() { _boilPoint = null; });
  }

  @override
  void dispose() {
    _glycolPercentController.dispose();
    _systemPressureController.dispose();
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
        title: Text('Boil Point', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Glycol Concentration', unit: '%', hint: 'Typical 50%', controller: _glycolPercentController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'System Pressure', unit: 'psi', hint: 'Radiator cap rating', controller: _systemPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_boilPoint != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildPressureCapGuide(colors),
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
        Text('~3°F increase per PSI', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Pressure and glycol both raise boiling point', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BOILING POINT (PRESSURIZED)', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('${_boilPoint!.toStringAsFixed(0)}°F', style: TextStyle(color: colors.accentPrimary, fontSize: 48, fontWeight: FontWeight.w700)),
        Text('(${((_boilPoint! - 32) * 5 / 9).toStringAsFixed(0)}°C)', style: TextStyle(color: colors.textSecondary, fontSize: 16)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Unpressurized Boil', '${_unpressurizedBoil!.toStringAsFixed(0)}°F'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Pressure Increase', '+${((_boilPoint! - _unpressurizedBoil!)).toStringAsFixed(0)}°F'),
      ]),
    );
  }

  Widget _buildPressureCapGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('RADIATOR CAP RATINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildCapRow(colors, '7 psi', 'Older vehicles, low stress'),
        _buildCapRow(colors, '13-15 psi', 'Most modern vehicles'),
        _buildCapRow(colors, '16-18 psi', 'Performance/heavy duty'),
        _buildCapRow(colors, '20+ psi', 'Racing applications'),
        const SizedBox(height: 12),
        Text('Use manufacturer spec. Higher pressure stresses hoses and seals.', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildCapRow(ZaftoColors colors, String pressure, String use) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(pressure, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Expanded(child: Text(use, style: TextStyle(color: colors.textSecondary, fontSize: 13), textAlign: TextAlign.right)),
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
