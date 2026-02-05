import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wastegate Calculator - Spring pressure and sizing
class WastegateScreen extends ConsumerStatefulWidget {
  const WastegateScreen({super.key});
  @override
  ConsumerState<WastegateScreen> createState() => _WastegateScreenState();
}

class _WastegateScreenState extends ConsumerState<WastegateScreen> {
  final _springPressureController = TextEditingController();
  final _boostControllerPressureController = TextEditingController();
  final _horsepowerController = TextEditingController();

  double? _baseBoost;
  double? _maxBoost;
  String? _recommendedSize;

  void _calculate() {
    final springPressure = double.tryParse(_springPressureController.text);
    final bcPressure = double.tryParse(_boostControllerPressureController.text) ?? 0;
    final horsepower = double.tryParse(_horsepowerController.text);

    if (springPressure == null) {
      setState(() { _baseBoost = null; });
      return;
    }

    final baseBoost = springPressure;
    final maxBoost = springPressure + bcPressure;

    String size;
    if (horsepower != null) {
      if (horsepower < 400) {
        size = '38mm single or IWG';
      } else if (horsepower < 600) {
        size = '40-44mm single';
      } else if (horsepower < 800) {
        size = '45-46mm single or dual 38mm';
      } else {
        size = '50mm+ or dual 44mm+';
      }
    } else {
      size = 'Enter HP for sizing';
    }

    setState(() {
      _baseBoost = baseBoost;
      _maxBoost = maxBoost;
      _recommendedSize = size;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _springPressureController.clear();
    _boostControllerPressureController.clear();
    _horsepowerController.clear();
    setState(() { _baseBoost = null; });
  }

  @override
  void dispose() {
    _springPressureController.dispose();
    _boostControllerPressureController.dispose();
    _horsepowerController.dispose();
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
        title: Text('Wastegate', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Spring Pressure', unit: 'psi', hint: 'Base spring rate', controller: _springPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Boost Controller', unit: 'psi', hint: 'Added pressure (optional)', controller: _boostControllerPressureController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Horsepower', unit: 'hp', hint: 'For sizing', controller: _horsepowerController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_baseBoost != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildSpringGuide(colors),
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
        Text('Max Boost = Spring + Controller', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Control boost with spring and solenoid', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        Text('BOOST LEVELS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _buildResultRow(colors, 'Base Boost (spring only)', '${_baseBoost!.toStringAsFixed(1)} psi'),
        const SizedBox(height: 8),
        _buildResultRow(colors, 'Max Boost (with controller)', '${_maxBoost!.toStringAsFixed(1)} psi'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text('RECOMMENDED SIZE', style: TextStyle(color: colors.textTertiary, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_recommendedSize!, style: TextStyle(color: colors.accentPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSpringGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SPRING PRESSURES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildSpringRow(colors, 'Low boost / mild', '5-7 psi'),
        _buildSpringRow(colors, 'Street performance', '7-10 psi'),
        _buildSpringRow(colors, 'Aggressive street', '10-14 psi'),
        _buildSpringRow(colors, 'Race / E85', '14-22 psi'),
        const SizedBox(height: 12),
        Text('Use lower spring + boost controller for adjustability', style: TextStyle(color: colors.textTertiary, fontSize: 12, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildSpringRow(ZaftoColors colors, String use, String pressure) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(use, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(pressure, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
