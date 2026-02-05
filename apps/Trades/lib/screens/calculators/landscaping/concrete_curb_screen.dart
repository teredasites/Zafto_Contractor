import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Concrete Curb Calculator - Landscape curbing
class ConcreteCurbScreen extends ConsumerStatefulWidget {
  const ConcreteCurbScreen({super.key});
  @override
  ConsumerState<ConcreteCurbScreen> createState() => _ConcreteCurbScreenState();
}

class _ConcreteCurbScreenState extends ConsumerState<ConcreteCurbScreen> {
  final _lengthController = TextEditingController(text: '100');

  String _curbStyle = 'mower';

  double? _concreteCuYd;
  double? _bags80Lb;
  double? _laborHours;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 100;

    // Cross-section area in sq inches based on style
    double crossSectionSqIn;
    switch (_curbStyle) {
      case 'mower':
        // 6" wide × 4" high
        crossSectionSqIn = 24;
        break;
      case 'slant':
        // ~5" × 5" triangular
        crossSectionSqIn = 12.5;
        break;
      case 'curb_gutter':
        // 8" × 6"
        crossSectionSqIn = 48;
        break;
      default:
        crossSectionSqIn = 24;
    }

    // Volume calculation
    final lengthIn = length * 12;
    final volumeCuIn = crossSectionSqIn * lengthIn;
    final volumeCuFt = volumeCuIn / 1728;
    final volumeCuYd = volumeCuFt / 27;

    // 80 lb bag = 0.6 cu ft
    final bags = volumeCuFt / 0.6;

    // Labor: machine extruded ~50-100 ft/hr
    final labor = length / 75;

    setState(() {
      _concreteCuYd = volumeCuYd;
      _bags80Lb = bags;
      _laborHours = labor;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '100'; setState(() { _curbStyle = 'mower'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Concrete Curb', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'CURB STYLE', ['slant', 'mower', 'curb_gutter'], _curbStyle, {'slant': 'Slant/Slope', 'mower': 'Mower Edge', 'curb_gutter': 'Curb & Gutter'}, (v) { setState(() => _curbStyle = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Linear Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_concreteCuYd != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('CONCRETE', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_concreteCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('80 lb bags (alt)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_bags80Lb!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Est. labor (machine)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_laborHours!.toStringAsFixed(1)} hrs', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildCurbGuide(colors),
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

  Widget _buildCurbGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CURBING STYLES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Slant', 'Low profile, decorative'),
        _buildTableRow(colors, 'Mower edge', '4-6\" tall, clean edge'),
        _buildTableRow(colors, 'Curb & gutter', 'Water management'),
        _buildTableRow(colors, 'Cure time', '24-48 hrs minimum'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
