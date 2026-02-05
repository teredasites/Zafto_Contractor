import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Curtain Rod Calculator - Rod and curtain sizing estimation
class CurtainRodScreen extends ConsumerStatefulWidget {
  const CurtainRodScreen({super.key});
  @override
  ConsumerState<CurtainRodScreen> createState() => _CurtainRodScreenState();
}

class _CurtainRodScreenState extends ConsumerState<CurtainRodScreen> {
  final _windowWidthController = TextEditingController(text: '48');
  final _windowHeightController = TextEditingController(text: '60');
  final _ceilingController = TextEditingController(text: '8');

  String _fullness = 'standard';
  bool _floorLength = true;

  double? _rodWidth;
  double? _mountHeight;
  double? _curtainWidth;
  double? _curtainLength;
  int? _panels;

  @override
  void dispose() { _windowWidthController.dispose(); _windowHeightController.dispose(); _ceilingController.dispose(); super.dispose(); }

  void _calculate() {
    final windowWidth = double.tryParse(_windowWidthController.text) ?? 48;
    final windowHeight = double.tryParse(_windowHeightController.text) ?? 60;
    final ceiling = double.tryParse(_ceilingController.text) ?? 8;

    // Rod width: window width + 6-12" each side (allows curtains to stack off window)
    final rodWidth = windowWidth + 16; // 8" each side

    // Mount height: 4-6" above window frame, or at ceiling
    final ceilingInches = ceiling * 12;
    final windowTop = ceilingInches - windowHeight - 36; // Estimate window from floor
    var mountHeight = windowTop + windowHeight + 4; // 4" above frame

    // Consider ceiling mount if close
    if (ceilingInches - mountHeight < 12) {
      mountHeight = ceilingInches - 2; // 2" from ceiling
    }

    // Curtain width: depends on fullness
    double fullnessMultiplier;
    switch (_fullness) {
      case 'minimal':
        fullnessMultiplier = 1.5;
        break;
      case 'standard':
        fullnessMultiplier = 2.0;
        break;
      case 'full':
        fullnessMultiplier = 2.5;
        break;
      default:
        fullnessMultiplier = 2.0;
    }

    final curtainWidth = rodWidth * fullnessMultiplier;

    // Curtain length
    double curtainLength;
    if (_floorLength) {
      curtainLength = mountHeight - 0.5; // 1/2" off floor
    } else {
      // Sill length or apron length
      curtainLength = windowHeight + 4;
    }

    // Panels: standard panels are 50-54" wide
    final panels = (curtainWidth / 52).ceil();

    setState(() { _rodWidth = rodWidth; _mountHeight = mountHeight; _curtainWidth = curtainWidth; _curtainLength = curtainLength; _panels = panels; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _windowWidthController.text = '48'; _windowHeightController.text = '60'; _ceilingController.text = '8'; setState(() { _fullness = 'standard'; _floorLength = true; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Curtain Rod', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 16),
            _buildToggle(colors, 'Floor Length Curtains', _floorLength, (v) { setState(() => _floorLength = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Window Width', unit: 'inches', controller: _windowWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Window Height', unit: 'inches', controller: _windowHeightController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Ceiling Height', unit: 'feet', controller: _ceilingController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_rodWidth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('ROD LENGTH', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_rodWidth!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mount Height', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mountHeight!.toStringAsFixed(0)}\" from floor', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Curtain Width', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_curtainWidth!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Curtain Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_curtainLength!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Panels Needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_panels', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Mount rod 4-6\" above window, extend 6-12\" past each side. Brackets every 3-4\'.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildLengthTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['minimal', 'standard', 'full'];
    final labels = {'minimal': 'Minimal (1.5x)', 'standard': 'Standard (2x)', 'full': 'Full (2.5x)'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FULLNESS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _fullness == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _fullness = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
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
        child: Center(child: Text(label, style: TextStyle(color: value ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _buildLengthTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD LENGTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Sill length', 'Bottom of window'),
        _buildTableRow(colors, 'Apron length', '4\" below sill'),
        _buildTableRow(colors, 'Floor length', '1/2\" off floor'),
        _buildTableRow(colors, 'Puddle', '1-6\" on floor'),
        _buildTableRow(colors, 'Standard panels', '84\", 95\", 108\"'),
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
