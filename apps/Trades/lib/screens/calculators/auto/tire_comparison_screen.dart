import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Tire Size Comparison - Old vs new tire diameter difference
class TireComparisonScreen extends ConsumerStatefulWidget {
  const TireComparisonScreen({super.key});
  @override
  ConsumerState<TireComparisonScreen> createState() => _TireComparisonScreenState();
}

class _TireComparisonScreenState extends ConsumerState<TireComparisonScreen> {
  // Old tire
  final _oldWidthController = TextEditingController();
  final _oldAspectController = TextEditingController();
  final _oldWheelController = TextEditingController();
  // New tire
  final _newWidthController = TextEditingController();
  final _newAspectController = TextEditingController();
  final _newWheelController = TextEditingController();

  double? _oldDiameter;
  double? _newDiameter;
  double? _diameterDiff;
  double? _speedoError;

  void _calculate() {
    final oldW = double.tryParse(_oldWidthController.text);
    final oldA = double.tryParse(_oldAspectController.text);
    final oldR = double.tryParse(_oldWheelController.text);
    final newW = double.tryParse(_newWidthController.text);
    final newA = double.tryParse(_newAspectController.text);
    final newR = double.tryParse(_newWheelController.text);

    if (oldW == null || oldA == null || oldR == null || newW == null || newA == null || newR == null) {
      setState(() { _oldDiameter = null; });
      return;
    }

    final oldSidewall = (oldW * (oldA / 100)) / 25.4;
    final newSidewall = (newW * (newA / 100)) / 25.4;
    final oldDia = oldR + (2 * oldSidewall);
    final newDia = newR + (2 * newSidewall);
    final diff = newDia - oldDia;
    final speedoErr = ((newDia / oldDia) - 1) * 100;

    setState(() {
      _oldDiameter = oldDia;
      _newDiameter = newDia;
      _diameterDiff = diff;
      _speedoError = speedoErr;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _oldWidthController.clear();
    _oldAspectController.clear();
    _oldWheelController.clear();
    _newWidthController.clear();
    _newAspectController.clear();
    _newWheelController.clear();
    setState(() { _oldDiameter = null; });
  }

  @override
  void dispose() {
    _oldWidthController.dispose();
    _oldAspectController.dispose();
    _oldWheelController.dispose();
    _newWidthController.dispose();
    _newAspectController.dispose();
    _newWheelController.dispose();
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
        title: Text('Tire Comparison', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('ORIGINAL TIRE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'mm', controller: _oldWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: 'Aspect', unit: '%', controller: _oldAspectController, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: 'Wheel', unit: 'in', controller: _oldWheelController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 24),
            Text('NEW TIRE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'mm', controller: _newWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: 'Aspect', unit: '%', controller: _newAspectController, onChanged: (_) => _calculate())),
              const SizedBox(width: 8),
              Expanded(child: ZaftoInputField(label: 'Wheel', unit: 'in', controller: _newWheelController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_oldDiameter != null) _buildResultsCard(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final diffColor = _diameterDiff!.abs() > 1 ? colors.accentWarning : colors.accentSuccess;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Original Diameter', '${_oldDiameter!.toStringAsFixed(2)}"'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'New Diameter', '${_newDiameter!.toStringAsFixed(2)}"'),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Difference', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
          Text('${_diameterDiff! >= 0 ? '+' : ''}${_diameterDiff!.toStringAsFixed(2)}"', style: TextStyle(color: diffColor, fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Speedometer Error', '${_speedoError! >= 0 ? '+' : ''}${_speedoError!.toStringAsFixed(1)}%'),
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
