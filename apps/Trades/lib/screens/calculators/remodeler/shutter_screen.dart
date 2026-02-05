import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shutter Calculator - Exterior shutter estimation
class ShutterScreen extends ConsumerStatefulWidget {
  const ShutterScreen({super.key});
  @override
  ConsumerState<ShutterScreen> createState() => _ShutterScreenState();
}

class _ShutterScreenState extends ConsumerState<ShutterScreen> {
  final _windowCountController = TextEditingController(text: '8');
  final _windowWidthController = TextEditingController(text: '32');
  final _windowHeightController = TextEditingController(text: '54');

  String _style = 'louvered';
  String _material = 'vinyl';

  int? _shutterCount;
  double? _shutterWidth;
  double? _shutterHeight;
  int? _hinges;
  int? _holdbacks;

  @override
  void dispose() { _windowCountController.dispose(); _windowWidthController.dispose(); _windowHeightController.dispose(); super.dispose(); }

  void _calculate() {
    final windowCount = int.tryParse(_windowCountController.text) ?? 8;
    final windowWidth = double.tryParse(_windowWidthController.text) ?? 32;
    final windowHeight = double.tryParse(_windowHeightController.text) ?? 54;

    // 2 shutters per window (1 each side)
    final shutterCount = windowCount * 2;

    // Shutter width: typically 1/4 to 1/3 of window width
    final shutterWidth = windowWidth / 4;

    // Shutter height: matches or slightly exceeds window height
    final shutterHeight = windowHeight + 1;

    // Hardware (if functional shutters)
    final hinges = shutterCount * 2; // 2 hinges per shutter
    final holdbacks = shutterCount; // 1 holdback per shutter

    setState(() { _shutterCount = shutterCount; _shutterWidth = shutterWidth; _shutterHeight = shutterHeight; _hinges = hinges; _holdbacks = holdbacks; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _windowCountController.text = '8'; _windowWidthController.text = '32'; _windowHeightController.text = '54'; setState(() { _style = 'louvered'; _material = 'vinyl'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Shutter', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'STYLE', ['louvered', 'raised_panel', 'board_batten'], _style, {'louvered': 'Louvered', 'raised_panel': 'Raised Panel', 'board_batten': 'Board & Batten'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['vinyl', 'wood', 'composite', 'aluminum'], _material, {'vinyl': 'Vinyl', 'wood': 'Wood', 'composite': 'Composite', 'aluminum': 'Aluminum'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Windows', unit: 'qty', controller: _windowCountController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Window Width', unit: 'inches', controller: _windowWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Window Height', unit: 'inches', controller: _windowHeightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_shutterCount != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SHUTTERS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_shutterCount pairs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Shutter Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_shutterWidth!.toStringAsFixed(0)}\" x ${_shutterHeight!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hinges (functional)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_hinges', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Holdbacks', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_holdbacks', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Proper proportion: shutter width = 1/4 to 1/3 window width. Shutters should appear able to cover window when closed.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildStyleTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildStyleTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SHUTTER STYLES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Louvered', 'Classic, most common'),
        _buildTableRow(colors, 'Raised panel', 'Colonial style'),
        _buildTableRow(colors, 'Board & batten', 'Rustic, farmhouse'),
        _buildTableRow(colors, 'Bahama', 'Tropical, hinged top'),
        _buildTableRow(colors, 'Combination', 'Louver + panel'),
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
