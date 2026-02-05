import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Crown Molding Calculator - Crown trim estimation
class CrownMoldingScreen extends ConsumerStatefulWidget {
  const CrownMoldingScreen({super.key});
  @override
  ConsumerState<CrownMoldingScreen> createState() => _CrownMoldingScreenState();
}

class _CrownMoldingScreenState extends ConsumerState<CrownMoldingScreen> {
  final _perimeterController = TextEditingController(text: '60');

  String _size = '4inch';
  String _material = 'mdf';

  double? _linearFeet;
  int? _pieces8ft;
  int? _pieces12ft;
  int? _cornersInside;
  int? _cornersOutside;

  @override
  void dispose() { _perimeterController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text) ?? 0;

    // Add 15% waste for crown (more waste due to angled cuts)
    final withWaste = perimeter * 1.15;

    final pieces8ft = (withWaste / 8).ceil();
    final pieces12ft = (withWaste / 12).ceil();

    // Estimate 4 inside corners, 0 outside for typical room
    final cornersInside = 4;
    final cornersOutside = 0;

    setState(() { _linearFeet = perimeter; _pieces8ft = pieces8ft; _pieces12ft = pieces12ft; _cornersInside = cornersInside; _cornersOutside = cornersOutside; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '60'; setState(() { _size = '4inch'; _material = 'mdf'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Crown Molding', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SIZE', ['3inch', '4inch', '5inch', '6inch'], _size, {'3inch': '3.25\"', '4inch': '4.5\"', '5inch': '5.25\"', '6inch': '6\"+'}, (v) { setState(() => _size = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'MATERIAL', ['mdf', 'pine', 'poplar', 'poly'], _material, {'mdf': 'MDF', 'pine': 'Pine', 'poplar': 'Poplar', 'poly': 'Polyurethane'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Room Perimeter', unit: 'feet', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_linearFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LINEAR FEET', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('8\' Pieces (+15%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pieces8ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('12\' Pieces (+15%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pieces12ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Inside Corners', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~$_cornersInside', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Crown requires compound miter cuts. Use coping for inside corners. Practice on scrap first!', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildAngleTable(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildAngleTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('45/45 CROWN SETTINGS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Miter angle', '31.6°'),
        _buildTableRow(colors, 'Bevel angle', '33.9°'),
        _buildTableRow(colors, 'Inside corner L', 'Miter L, Bevel L'),
        _buildTableRow(colors, 'Inside corner R', 'Miter R, Bevel R'),
        _buildTableRow(colors, 'Or use coping', 'Easier for inside'),
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
