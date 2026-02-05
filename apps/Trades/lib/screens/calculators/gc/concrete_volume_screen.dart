import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Concrete Volume Calculator - Cubic yards
class ConcreteVolumeScreen extends ConsumerStatefulWidget {
  const ConcreteVolumeScreen({super.key});
  @override
  ConsumerState<ConcreteVolumeScreen> createState() => _ConcreteVolumeScreenState();
}

class _ConcreteVolumeScreenState extends ConsumerState<ConcreteVolumeScreen> {
  final _lengthController = TextEditingController(text: '20');
  final _widthController = TextEditingController(text: '20');
  final _thicknessController = TextEditingController(text: '4');

  double? _cubicFeet;
  double? _cubicYards;
  double? _withWaste;
  int? _bags80lb;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _thicknessController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text);
    final width = double.tryParse(_widthController.text);
    final thicknessInches = double.tryParse(_thicknessController.text);

    if (length == null || width == null || thicknessInches == null) {
      setState(() { _cubicFeet = null; _cubicYards = null; _withWaste = null; _bags80lb = null; });
      return;
    }

    final thicknessFeet = thicknessInches / 12;
    final cubicFeet = length * width * thicknessFeet;
    final cubicYards = cubicFeet / 27;
    final withWaste = cubicYards * 1.1; // 10% waste
    final bags80lb = (cubicFeet / 0.6).ceil(); // 80lb bag = ~0.6 cu ft

    setState(() { _cubicFeet = cubicFeet; _cubicYards = cubicYards; _withWaste = withWaste; _bags80lb = bags80lb; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '20'; _widthController.text = '20'; _thicknessController.text = '4'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Concrete Volume', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Thickness', unit: 'inches', controller: _thicknessController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_cubicYards != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CUBIC YARDS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_cubicYards!.toStringAsFixed(2), style: TextStyle(color: colors.accentPrimary, fontSize: 28, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cubic Feet', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_cubicFeet!.toStringAsFixed(1), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('With 10% Waste', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_withWaste!.toStringAsFixed(2)} yd³', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('80lb Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_bags80lb', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Ready-mix trucks typically hold 8-10 cubic yards. Order extra for subgrade irregularities.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
