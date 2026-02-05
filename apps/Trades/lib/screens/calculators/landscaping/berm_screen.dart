import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Berm Calculator - Soil volume for berms
class BermScreen extends ConsumerStatefulWidget {
  const BermScreen({super.key});
  @override
  ConsumerState<BermScreen> createState() => _BermScreenState();
}

class _BermScreenState extends ConsumerState<BermScreen> {
  final _lengthController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '3');
  final _widthController = TextEditingController(text: '8');

  double? _volumeCuYd;
  double? _topsoilCuYd;
  double? _fillCuYd;
  double? _surfaceArea;

  @override
  void dispose() { _lengthController.dispose(); _heightController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 30;
    final height = double.tryParse(_heightController.text) ?? 3;
    final width = double.tryParse(_widthController.text) ?? 8;

    // Berm cross-section is roughly half an ellipse
    // Area = (π × width × height) / 4
    final crossSectionArea = (3.14159 * width * height) / 4;
    final volumeCuFt = crossSectionArea * length;
    final volumeCuYd = volumeCuFt / 27;

    // Topsoil layer: 6" over surface
    // Surface area ≈ length × (π × width / 2) for half cylinder approx
    final surfaceArea = length * (3.14159 * width / 2);
    final topsoilCuFt = surfaceArea * 0.5; // 6" = 0.5 ft
    final topsoilCuYd = topsoilCuFt / 27;

    // Fill = total - topsoil
    final fillCuYd = volumeCuYd - topsoilCuYd;

    setState(() {
      _volumeCuYd = volumeCuYd;
      _topsoilCuYd = topsoilCuYd > 0 ? topsoilCuYd : 0;
      _fillCuYd = fillCuYd > 0 ? fillCuYd : 0;
      _surfaceArea = surfaceArea;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '30'; _heightController.text = '3'; _widthController.text = '8'; _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Berm', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ZaftoInputField(label: 'Berm Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Height', unit: 'ft', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Base Width', unit: 'ft', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_volumeCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL VOLUME', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Fill dirt', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fillCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Topsoil (6\")', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_topsoilCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Surface area', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_surfaceArea!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildBermGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildBermGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('BERM DESIGN', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Width:Height', '4:1 to 6:1 ratio'),
        _buildTableRow(colors, 'Max slope', '3:1 for mowing'),
        _buildTableRow(colors, 'Compaction', 'Compact every 6\"'),
        _buildTableRow(colors, 'Settle factor', 'Add 10-15%'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
