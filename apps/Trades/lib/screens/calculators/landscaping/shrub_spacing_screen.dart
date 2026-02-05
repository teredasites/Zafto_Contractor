import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Shrub Spacing Calculator - Plants for foundation planting
class ShrubSpacingScreen extends ConsumerStatefulWidget {
  const ShrubSpacingScreen({super.key});
  @override
  ConsumerState<ShrubSpacingScreen> createState() => _ShrubSpacingScreenState();
}

class _ShrubSpacingScreenState extends ConsumerState<ShrubSpacingScreen> {
  final _lengthController = TextEditingController(text: '40');
  final _matureWidthController = TextEditingController(text: '4');

  String _densityPref = 'standard';

  int? _shrubsNeeded;
  double? _spacing;
  double? _mulchCuYd;

  @override
  void dispose() { _lengthController.dispose(); _matureWidthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 40;
    final matureWidth = double.tryParse(_matureWidthController.text) ?? 4;

    // Spacing based on mature width and preference
    double spacingFactor;
    switch (_densityPref) {
      case 'tight': spacingFactor = 0.6; break; // 60% of mature width
      case 'standard': spacingFactor = 0.75; break; // 75% for slight overlap
      case 'spaced': spacingFactor = 1.0; break; // Full width, no overlap
      default: spacingFactor = 0.75;
    }

    final spacing = matureWidth * spacingFactor;
    final shrubs = (length / spacing).ceil();

    // Mulch: bed depth 3", width = mature width + 2'
    final bedWidth = matureWidth + 2;
    final mulchArea = length * bedWidth;
    final mulchCuFt = mulchArea * 0.25; // 3" depth
    final mulchCuYd = mulchCuFt / 27;

    setState(() {
      _shrubsNeeded = shrubs;
      _spacing = spacing;
      _mulchCuYd = mulchCuYd;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '40'; _matureWidthController.text = '4'; setState(() { _densityPref = 'standard'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Shrub Spacing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PLANTING DENSITY', ['tight', 'standard', 'spaced'], _densityPref, {'tight': 'Tight (60%)', 'standard': 'Standard (75%)', 'spaced': 'Spaced (100%)'}, (v) { setState(() => _densityPref = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Bed Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Mature Shrub Width', unit: 'ft', controller: _matureWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Check plant tag for mature width. Spacing based on % of mature size.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 32),
            if (_shrubsNeeded != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SHRUBS NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_shrubsNeeded', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Plant spacing', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text("${_spacing!.toStringAsFixed(1)}' apart", style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Bed mulch', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mulchCuYd!.toStringAsFixed(2)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildShrubGuide(colors),
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

  Widget _buildShrubGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('COMMON SHRUB WIDTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Dwarf boxwood', "2-3'"),
        _buildTableRow(colors, 'Azalea', "3-4'"),
        _buildTableRow(colors, 'Holly', "4-6'"),
        _buildTableRow(colors, 'Hydrangea', "4-6'"),
        _buildTableRow(colors, 'Viburnum', "6-8'"),
        _buildTableRow(colors, 'Arborvitae', "3-4'"),
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
