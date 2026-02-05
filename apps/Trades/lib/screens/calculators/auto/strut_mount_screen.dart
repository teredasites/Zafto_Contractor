import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Strut Mount Calculator - Camber adjustment via mount position
class StrutMountScreen extends ConsumerStatefulWidget {
  const StrutMountScreen({super.key});
  @override
  ConsumerState<StrutMountScreen> createState() => _StrutMountScreenState();
}

class _StrutMountScreenState extends ConsumerState<StrutMountScreen> {
  final _currentCamberController = TextEditingController();
  final _targetCamberController = TextEditingController();
  final _strutLengthController = TextEditingController(text: '18');

  double? _offsetNeeded;

  void _calculate() {
    final currentCamber = double.tryParse(_currentCamberController.text);
    final targetCamber = double.tryParse(_targetCamberController.text);
    final strutLength = double.tryParse(_strutLengthController.text);

    if (currentCamber == null || targetCamber == null || strutLength == null) {
      setState(() { _offsetNeeded = null; });
      return;
    }

    // Simplified: 1mm of offset ≈ 0.1° of camber change for typical strut
    // More accurate: offset = strut length × sin(angle difference)
    final angleDiff = targetCamber - currentCamber;
    final offsetMm = angleDiff * 10; // Approximation

    setState(() {
      _offsetNeeded = offsetMm;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _currentCamberController.clear();
    _targetCamberController.clear();
    _strutLengthController.text = '18';
    setState(() { _offsetNeeded = null; });
  }

  @override
  void dispose() {
    _currentCamberController.dispose();
    _targetCamberController.dispose();
    _strutLengthController.dispose();
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
        title: Text('Strut Mount', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Current Camber', unit: '°', hint: 'Measured camber', controller: _currentCamberController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Target Camber', unit: '°', hint: 'Desired camber', controller: _targetCamberController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Strut Length', unit: 'in', hint: 'Knuckle to mount', controller: _strutLengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_offsetNeeded != null) _buildResultsCard(colors),
            const SizedBox(height: 24),
            _buildOptionsCard(colors),
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
        Text('Offset ≈ 10mm per degree', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Approximation - varies by strut geometry', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    final direction = _offsetNeeded! < 0 ? 'inward' : 'outward';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Offset Needed', '${_offsetNeeded!.abs().toStringAsFixed(1)} mm', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Direction', 'Move top $direction'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('Moving top of strut inward adds negative camber, outward adds positive camber.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _buildOptionsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CAMBER ADJUSTMENT OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildOptionRow(colors, 'Slotted strut mounts', '±1.5° typical'),
        _buildOptionRow(colors, 'Camber plates', '±3° typical'),
        _buildOptionRow(colors, 'Camber bolts', '±1.75° typical'),
        _buildOptionRow(colors, 'Adjustable control arms', 'Varies by design'),
      ]),
    );
  }

  Widget _buildOptionRow(ZaftoColors colors, String option, String range) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(option, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
        Text(range, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
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
