import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Kidney/Irregular Pool Volume Calculator
class KidneyPoolVolumeScreen extends ConsumerStatefulWidget {
  const KidneyPoolVolumeScreen({super.key});
  @override
  ConsumerState<KidneyPoolVolumeScreen> createState() => _KidneyPoolVolumeScreenState();
}

class _KidneyPoolVolumeScreenState extends ConsumerState<KidneyPoolVolumeScreen> {
  final _lengthController = TextEditingController();
  final _widthAController = TextEditingController();
  final _widthBController = TextEditingController();
  final _depthController = TextEditingController();

  double? _gallons;
  double? _liters;
  double? _cubicFeet;

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final widthA = double.tryParse(_widthAController.text);
    final widthB = double.tryParse(_widthBController.text);
    final depth = double.tryParse(_depthController.text);

    if (length == null || widthA == null || widthB == null || depth == null ||
        length <= 0 || widthA <= 0 || widthB <= 0 || depth <= 0) {
      setState(() { _gallons = null; });
      return;
    }

    // Kidney pool formula: 0.45 × (A + B) × Length × Depth × 7.48
    // Where A and B are the widths at the widest and narrowest points
    final avgWidth = (widthA + widthB) / 2;
    final cubicFeet = 0.45 * (widthA + widthB) * length * depth / 2;
    final gallons = cubicFeet * 7.48;
    final liters = gallons * 3.785;

    setState(() {
      _cubicFeet = cubicFeet;
      _gallons = gallons;
      _liters = liters;
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    _lengthController.clear();
    _widthAController.clear();
    _widthBController.clear();
    _depthController.clear();
    setState(() { _gallons = null; });
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthAController.dispose();
    _widthBController.dispose();
    _depthController.dispose();
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
        title: Text('Kidney Pool Volume', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildFormulaCard(colors),
            const SizedBox(height: 24),
            ZaftoInputField(label: 'Length', unit: 'ft', hint: 'Longest dimension', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Width A (widest)', unit: 'ft', hint: 'Widest point', controller: _widthAController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Width B (narrowest)', unit: 'ft', hint: 'Narrowest point', controller: _widthBController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Average Depth', unit: 'ft', hint: 'Average depth', controller: _depthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_gallons != null) _buildResultsCard(colors),
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
        Text('V = 0.45 × (A+B) × L × D × 7.48', style: TextStyle(color: colors.accentPrimary, fontWeight: FontWeight.w600, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 8),
        Text('Kidney/figure-8 shaped pools', style: TextStyle(color: colors.textTertiary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildResultsCard(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3))),
      child: Column(children: [
        _buildResultRow(colors, 'Pool Volume', '${_gallons!.toStringAsFixed(0)} gal', isPrimary: true),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Liters', '${_liters!.toStringAsFixed(0)} L'),
        const SizedBox(height: 12),
        _buildResultRow(colors, 'Cubic Feet', '${_cubicFeet!.toStringAsFixed(1)} cu ft'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: colors.bgBase, borderRadius: BorderRadius.circular(8)),
          child: Text('This is an estimate. Irregular pools may vary +/- 10%.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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
