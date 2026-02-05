import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Chair Rail Calculator - Chair rail molding estimation
class ChairRailScreen extends ConsumerStatefulWidget {
  const ChairRailScreen({super.key});
  @override
  ConsumerState<ChairRailScreen> createState() => _ChairRailScreenState();
}

class _ChairRailScreenState extends ConsumerState<ChairRailScreen> {
  final _perimeterController = TextEditingController(text: '60');
  final _doorsController = TextEditingController(text: '2');
  final _ceilingController = TextEditingController(text: '8');

  String _profile = 'colonial';

  double? _linearFeet;
  int? _pieces8ft;
  double? _mountHeight;

  @override
  void dispose() { _perimeterController.dispose(); _doorsController.dispose(); _ceilingController.dispose(); super.dispose(); }

  void _calculate() {
    final perimeter = double.tryParse(_perimeterController.text) ?? 0;
    final doors = int.tryParse(_doorsController.text) ?? 0;
    final ceiling = double.tryParse(_ceilingController.text) ?? 8;

    // Subtract door openings (avg 3' each)
    var linearFeet = perimeter - (doors * 3);
    if (linearFeet < 0) linearFeet = 0;

    // Add 10% waste
    final withWaste = linearFeet * 1.10;
    final pieces8ft = (withWaste / 8).ceil();

    // Mount height: 1/3 of wall height from floor, typically 32-36"
    final mountHeight = ceiling * 12 / 3;

    setState(() { _linearFeet = linearFeet; _pieces8ft = pieces8ft; _mountHeight = mountHeight; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _perimeterController.text = '60'; _doorsController.text = '2'; _ceilingController.text = '8'; setState(() => _profile = 'colonial'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Chair Rail', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Room Perimeter', unit: 'feet', controller: _perimeterController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Door Openings', unit: 'qty', controller: _doorsController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Ceiling Height', unit: 'feet', controller: _ceilingController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_linearFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('LINEAR FEET', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('8\' Pieces (+10%)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_pieces8ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mount Height', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_mountHeight!.toStringAsFixed(0)}\" from floor', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Height = 1/3 wall height. Standard 32-36\" for 8\' ceilings. Can add picture molding above.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildHeightTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['colonial', 'ogee', 'craftsman', 'modern'];
    final labels = {'colonial': 'Colonial', 'ogee': 'Ogee', 'craftsman': 'Craftsman', 'modern': 'Modern'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PROFILE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _profile == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _profile = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildHeightTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HEIGHT BY CEILING', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '8\' ceiling', '32\" from floor'),
        _buildTableRow(colors, '9\' ceiling', '36\" from floor'),
        _buildTableRow(colors, '10\' ceiling', '40\" from floor'),
        _buildTableRow(colors, '12\' ceiling', '48\" from floor'),
        _buildTableRow(colors, 'General rule', '1/3 of wall height'),
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
