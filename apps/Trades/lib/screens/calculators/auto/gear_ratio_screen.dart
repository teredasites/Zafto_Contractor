import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Gear Ratio Calculator - Final drive from ring/pinion
class GearRatioScreen extends ConsumerStatefulWidget {
  const GearRatioScreen({super.key});
  @override
  ConsumerState<GearRatioScreen> createState() => _GearRatioScreenState();
}

class _GearRatioScreenState extends ConsumerState<GearRatioScreen> {
  final _ringController = TextEditingController();
  final _pinionController = TextEditingController();

  double? _gearRatio;

  void _calculate() {
    final ring = double.tryParse(_ringController.text);
    final pinion = double.tryParse(_pinionController.text);

    if (ring == null || pinion == null || pinion <= 0) {
      setState(() { _gearRatio = null; });
      return;
    }

    setState(() {
      _gearRatio = ring / pinion;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _ringController.clear();
    _pinionController.clear();
    setState(() { _gearRatio = null; });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pinionController.dispose();
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
        title: Text('Gear Ratio', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Ring Gear Teeth', unit: 'teeth', hint: 'e.g. 41', controller: _ringController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Pinion Teeth', unit: 'teeth', hint: 'e.g. 11', controller: _pinionController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gearRatio != null) _buildResultsCard(colors),
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
        Text('Ratio = Ring Teeth / Pinion Teeth', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Higher ratio = more acceleration, lower top speed', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    String analysis;
    if (_gearRatio! < 3.0) {
      analysis = 'Highway gears - economy, lower acceleration';
    } else if (_gearRatio! < 3.7) {
      analysis = 'Street gears - balanced performance';
    } else if (_gearRatio! < 4.3) {
      analysis = 'Performance gears - quick acceleration';
    } else {
      analysis = 'Drag/off-road gears - max torque multiplication';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Final Drive Ratio', '${_gearRatio!.toStringAsFixed(2)}:1', isPrimary: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text(analysis, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
