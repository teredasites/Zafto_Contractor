import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Hedge Spacing Calculator - Plants for privacy hedge
class HedgeSpacingScreen extends ConsumerStatefulWidget {
  const HedgeSpacingScreen({super.key});
  @override
  ConsumerState<HedgeSpacingScreen> createState() => _HedgeSpacingScreenState();
}

class _HedgeSpacingScreenState extends ConsumerState<HedgeSpacingScreen> {
  final _lengthController = TextEditingController(text: '50');

  String _hedgeType = 'privet';
  String _density = 'standard';

  int? _plantsNeeded;
  double? _spacing;

  @override
  void dispose() { _lengthController.dispose(); super.dispose(); }

  void _calculate() {
    final lengthFt = double.tryParse(_lengthController.text) ?? 50;

    // Spacing by hedge type (feet between plants)
    double baseSpacing;
    switch (_hedgeType) {
      case 'privet': baseSpacing = 3; break;
      case 'boxwood': baseSpacing = 2; break;
      case 'arborvitae': baseSpacing = 4; break;
      case 'holly': baseSpacing = 4; break;
      case 'laurel': baseSpacing = 3; break;
      case 'yew': baseSpacing = 3; break;
      default: baseSpacing = 3;
    }

    // Density adjustment
    double densityFactor;
    switch (_density) {
      case 'tight': densityFactor = 0.75; break;
      case 'standard': densityFactor = 1.0; break;
      case 'loose': densityFactor = 1.25; break;
      default: densityFactor = 1.0;
    }

    final spacing = baseSpacing * densityFactor;
    final plants = (lengthFt / spacing).ceil() + 1;

    setState(() {
      _plantsNeeded = plants;
      _spacing = spacing;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; setState(() { _hedgeType = 'privet'; _density = 'standard'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Hedge Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'HEDGE TYPE', ['privet', 'boxwood', 'arborvitae', 'holly', 'laurel', 'yew'], _hedgeType, {'privet': 'Privet', 'boxwood': 'Boxwood', 'arborvitae': 'Arborvitae', 'holly': 'Holly', 'laurel': 'Laurel', 'yew': 'Yew'}, (v) { setState(() => _hedgeType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildDensitySelector(colors, 'DENSITY', ['tight', 'standard', 'loose'], _density, {'tight': 'Tight', 'standard': 'Standard', 'loose': 'Loose'}, (v) { setState(() => _density = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Hedge Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_plantsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PLANTS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_plantsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Plant spacing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_spacing!.toStringAsFixed(1)}'", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hedge length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_lengthController.text}'", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildHedgeGuide(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: options.map((o) {
        final isSelected = selected == o;
        return GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildDensitySelector(ZaftoColors colors, String title, List<String> options, String selected, Map<String, String> labels, Function(String) onSelect) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = selected == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onSelect(o); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildHedgeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HEDGE CHARACTERISTICS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Privet', 'Fast, deciduous, 3\' spacing'),
        _buildTableRow(colors, 'Boxwood', 'Slow, formal, 2\' spacing'),
        _buildTableRow(colors, 'Arborvitae', 'Tall privacy, 4\' spacing'),
        _buildTableRow(colors, 'Holly', 'Evergreen, thorny, 4\' spacing'),
        _buildTableRow(colors, 'Laurel', 'Fast, broadleaf, 3\' spacing'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
