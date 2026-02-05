import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Speed from RPM Calculator - MPH at given RPM and gearing
class SpeedFromRpmScreen extends ConsumerStatefulWidget {
  const SpeedFromRpmScreen({super.key});
  @override
  ConsumerState<SpeedFromRpmScreen> createState() => _SpeedFromRpmScreenState();
}

class _SpeedFromRpmScreenState extends ConsumerState<SpeedFromRpmScreen> {
  final _rpmController = TextEditingController();
  final _transController = TextEditingController(text: '1.00');
  final _axleController = TextEditingController();
  final _tireController = TextEditingController();

  double? _speedMph;
  double? _speedKph;

  void _calculate() {
    final rpm = double.tryParse(_rpmController.text);
    final trans = double.tryParse(_transController.text);
    final axle = double.tryParse(_axleController.text);
    final tireDiameter = double.tryParse(_tireController.text);

    if (rpm == null || trans == null || axle == null || tireDiameter == null || trans <= 0 || axle <= 0) {
      setState(() { _speedMph = null; });
      return;
    }

    // MPH = (RPM × Tire Diameter) / (Trans Ratio × Axle Ratio × 336)
    final mph = (rpm * tireDiameter) / (trans * axle * 336);
    final kph = mph * 1.60934;

    setState(() {
      _speedMph = mph;
      _speedKph = kph;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _rpmController.clear();
    _transController.text = '1.00';
    _axleController.clear();
    _tireController.clear();
    setState(() { _speedMph = null; });
  }

  @override
  void dispose() {
    _rpmController.dispose();
    _transController.dispose();
    _axleController.dispose();
    _tireController.dispose();
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
        title: Text('Speed from RPM', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Engine RPM', unit: 'RPM', hint: 'Current engine speed', controller: _rpmController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Trans Ratio', unit: ':1', hint: '1.00 = direct drive', controller: _transController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Axle Ratio', unit: ':1', hint: 'e.g. 3.73', controller: _axleController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Tire Diameter', unit: 'in', hint: 'Overall diameter', controller: _tireController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_speedMph != null) _buildResultsCard(colors),
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
        Text('MPH = (RPM × Tire) / (Trans × Axle × 336)', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 12)),
        const SizedBox(height: 8),
        Text('Calculate vehicle speed from engine RPM', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Vehicle Speed', '${_speedMph!.toStringAsFixed(1)} MPH', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Metric', '${_speedKph!.toStringAsFixed(1)} km/h'),
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
