import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Porch Screen Calculator - Screen enclosure estimation
class PorchScreenScreen extends ConsumerStatefulWidget {
  const PorchScreenScreen({super.key});
  @override
  ConsumerState<PorchScreenScreen> createState() => _PorchScreenScreenState();
}

class _PorchScreenScreenState extends ConsumerState<PorchScreenScreen> {
  final _widthController = TextEditingController(text: '12');
  final _lengthController = TextEditingController(text: '16');
  final _heightController = TextEditingController(text: '8');

  String _screenType = 'fiberglass';
  String _frameType = 'aluminum';

  double? _screenSqft;
  double? _splineFeet;
  double? _frameFeet;
  int? _corners;

  @override
  void dispose() { _widthController.dispose(); _lengthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final width = double.tryParse(_widthController.text) ?? 12;
    final length = double.tryParse(_lengthController.text) ?? 16;
    final height = double.tryParse(_heightController.text) ?? 8;

    // Perimeter for walls
    final perimeter = (width + length) * 2;

    // Wall screen area (minus ~20% for framing)
    final wallArea = perimeter * height * 0.80;

    // Add 10% waste
    final screenSqft = wallArea * 1.10;

    // Spline: perimeter of each screen panel
    // Assume average panel is 4' wide
    final panels = (perimeter / 4).ceil();
    final splinePerPanel = (4 + height) * 2; // perimeter of each panel
    final splineFeet = panels * splinePerPanel * 1.10; // +10% waste

    // Frame material
    final frameFeet = perimeter * 3; // horizontal + verticals

    // Corner pieces: 4 main + 2 per panel
    final corners = 4 + (panels * 2);

    setState(() { _screenSqft = screenSqft; _splineFeet = splineFeet; _frameFeet = frameFeet; _corners = corners; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _widthController.text = '12'; _lengthController.text = '16'; _heightController.text = '8'; setState(() { _screenType = 'fiberglass'; _frameType = 'aluminum'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Porch Screen', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SCREEN TYPE', ['fiberglass', 'aluminum', 'pet', 'solar'], _screenType, {'fiberglass': 'Fiberglass', 'aluminum': 'Aluminum', 'pet': 'Pet-Resist', 'solar': 'Solar'}, (v) { setState(() => _screenType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'FRAME', ['aluminum', 'wood', 'vinyl'], _frameType, {'aluminum': 'Aluminum', 'wood': 'Wood', 'vinyl': 'Vinyl'}, (v) { setState(() => _frameType = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Wall Height', unit: 'feet', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_screenSqft != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SCREEN NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_screenSqft!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Spline', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_splineFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Frame Material', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_frameFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Corner Pieces', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_corners', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Standard screen: 18x16 mesh. Pet screen 7x stronger. Solar screen blocks 70-90% UV. Use proper spline size for frame.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildMaterialTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildMaterialTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SCREEN TYPES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Fiberglass', 'Standard, economical'),
        _buildTableRow(colors, 'Aluminum', 'Durable, rust-free'),
        _buildTableRow(colors, 'Pet-resistant', '7x stronger'),
        _buildTableRow(colors, 'Solar', 'Blocks heat/UV'),
        _buildTableRow(colors, 'No-see-um', '20x20 mesh, tiny insects'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
