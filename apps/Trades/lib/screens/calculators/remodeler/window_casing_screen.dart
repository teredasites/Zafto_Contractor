import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Window Casing Calculator - Window trim estimation
class WindowCasingScreen extends ConsumerStatefulWidget {
  const WindowCasingScreen({super.key});
  @override
  ConsumerState<WindowCasingScreen> createState() => _WindowCasingScreenState();
}

class _WindowCasingScreenState extends ConsumerState<WindowCasingScreen> {
  final _windowsController = TextEditingController(text: '8');
  final _heightController = TextEditingController(text: '48');
  final _widthController = TextEditingController(text: '36');

  String _style = 'picture';
  bool _hasApron = true;
  bool _hasStool = true;

  double? _casingLF;
  double? _apronLF;
  double? _stoolLF;
  double? _totalLF;

  @override
  void dispose() { _windowsController.dispose(); _heightController.dispose(); _widthController.dispose(); super.dispose(); }

  void _calculate() {
    final windows = int.tryParse(_windowsController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 48;
    final width = double.tryParse(_widthController.text) ?? 36;

    final heightFt = height / 12;
    final widthFt = width / 12;

    double casingPerWindow;
    switch (_style) {
      case 'picture':
        // All 4 sides
        casingPerWindow = (heightFt * 2) + (widthFt * 2) + 0.5;
        break;
      case 'stool':
        // 3 sides (top and 2 sides)
        casingPerWindow = (heightFt * 2) + widthFt + 0.5;
        break;
      default:
        casingPerWindow = (heightFt * 2) + (widthFt * 2) + 0.5;
    }

    final casingLF = casingPerWindow * windows * 1.10; // 10% waste

    // Apron: width + 2-3" each side
    final apronPerWindow = _hasApron ? widthFt + 0.5 : 0.0;
    final apronLF = apronPerWindow * windows;

    // Stool: width + 2" each side for horns
    final stoolPerWindow = _hasStool ? widthFt + 0.4 : 0.0;
    final stoolLF = stoolPerWindow * windows;

    final totalLF = casingLF + apronLF + stoolLF;

    setState(() { _casingLF = casingLF; _apronLF = apronLF; _stoolLF = stoolLF; _totalLF = totalLF; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _windowsController.text = '8'; _heightController.text = '48'; _widthController.text = '36'; setState(() { _style = 'picture'; _hasApron = true; _hasStool = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Window Casing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 16),
            ZaftoInputField(label: 'Number of Windows', unit: 'qty', controller: _windowsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Window Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Window Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildToggle(colors, 'Stool', _hasStool, (v) { setState(() => _hasStool = v); _calculate(); })),
              const SizedBox(width: 12),
              Expanded(child: _buildToggle(colors, 'Apron', _hasApron, (v) { setState(() => _hasApron = v); _calculate(); })),
            ]),
            const SizedBox(height: 32),
            if (_totalLF != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TOTAL TRIM', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_totalLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Casing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_casingLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                if (_hasStool) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Stool', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_stoolLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                if (_hasApron) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Apron', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_apronLF!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                ],
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Stool horns extend 1-2\" past casing. Apron matches casing width.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['picture', 'stool'];
    final labels = {'picture': 'Picture Frame', 'stool': 'Stool & Apron'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('TRIM STYLE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _style == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _style = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildToggle(ZaftoColors colors, String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: value ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: value ? colors.accentPrimary : colors.borderSubtle)),
        child: Center(child: Text(label, style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
      ),
    );
  }
}
