import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tire Pressure Calculator - PSI/Bar/kPa conversion and load adjustment
class TirePressureScreen extends ConsumerStatefulWidget {
  const TirePressureScreen({super.key});
  @override
  ConsumerState<TirePressureScreen> createState() => _TirePressureScreenState();
}

class _TirePressureScreenState extends ConsumerState<TirePressureScreen> {
  final _psiController = TextEditingController();
  final _barController = TextEditingController();
  final _kpaController = TextEditingController();
  final _tempColdController = TextEditingController(text: '70');
  final _tempHotController = TextEditingController(text: '100');

  bool _isUpdating = false;
  double? _hotPressure;

  void _updateFromPsi(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final psi = double.tryParse(value);
    if (psi != null) {
      _barController.text = (psi * 0.0689476).toStringAsFixed(2);
      _kpaController.text = (psi * 6.89476).toStringAsFixed(0);
      _calculateHotPressure(psi);
    }
    _isUpdating = false;
  }

  void _updateFromBar(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final bar = double.tryParse(value);
    if (bar != null) {
      final psi = bar / 0.0689476;
      _psiController.text = psi.toStringAsFixed(1);
      _kpaController.text = (bar * 100).toStringAsFixed(0);
      _calculateHotPressure(psi);
    }
    _isUpdating = false;
  }

  void _updateFromKpa(String value) {
    if (_isUpdating) return;
    _isUpdating = true;
    final kpa = double.tryParse(value);
    if (kpa != null) {
      final psi = kpa / 6.89476;
      _psiController.text = psi.toStringAsFixed(1);
      _barController.text = (kpa / 100).toStringAsFixed(2);
      _calculateHotPressure(psi);
    }
    _isUpdating = false;
  }

  void _calculateHotPressure(double coldPsi) {
    final coldTemp = double.tryParse(_tempColdController.text) ?? 70;
    final hotTemp = double.tryParse(_tempHotController.text) ?? 100;

    // Pressure increases ~1 PSI per 10°F temperature increase
    final tempDiff = hotTemp - coldTemp;
    final pressureIncrease = tempDiff / 10;

    setState(() {
      _hotPressure = coldPsi + pressureIncrease;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _psiController.clear();
    _barController.clear();
    _kpaController.clear();
    _tempColdController.text = '70';
    _tempHotController.text = '100';
    setState(() { _hotPressure = null; });
  }

  @override
  void dispose() {
    _psiController.dispose();
    _barController.dispose();
    _kpaController.dispose();
    _tempColdController.dispose();
    _tempHotController.dispose();
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
        title: Text('Tire Pressure', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            _buildSectionHeader(colors, 'PRESSURE CONVERSION'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'PSI', unit: 'psi', hint: 'Pounds per sq inch', controller: _psiController, onChanged: _updateFromPsi),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Bar', unit: 'bar', hint: 'Metric bar', controller: _barController, onChanged: _updateFromBar),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'kPa', unit: 'kPa', hint: 'Kilopascals', controller: _kpaController, onChanged: _updateFromKpa),
            const SizedBox(height: 20),
            _buildSectionHeader(colors, 'TEMPERATURE COMPENSATION'),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Cold Temp', unit: '°F', hint: 'Ambient temp', controller: _tempColdController, onChanged: (_) { final psi = double.tryParse(_psiController.text); if (psi != null) _calculateHotPressure(psi); }),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Hot Temp', unit: '°F', hint: 'After driving', controller: _tempHotController, onChanged: (_) { final psi = double.tryParse(_psiController.text); if (psi != null) _calculateHotPressure(psi); }),
            const SizedBox(height: 32),
            if (_hotPressure != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ZaftoColors colors, String title) {
    return Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
  }

  Widget _buildFormulaCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(children: [
        Text('~1 PSI per 10°F temperature change', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Always set pressure when tires are cold', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Expected Hot Pressure', '${_hotPressure!.toStringAsFixed(1)} psi', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Hot pressure naturally increases from driving. This is normal - do not release air from hot tires.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
