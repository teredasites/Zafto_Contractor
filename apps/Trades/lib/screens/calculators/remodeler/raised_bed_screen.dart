import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Raised Bed Calculator - Raised garden bed materials estimation
class RaisedBedScreen extends ConsumerStatefulWidget {
  const RaisedBedScreen({super.key});
  @override
  ConsumerState<RaisedBedScreen> createState() => _RaisedBedScreenState();
}

class _RaisedBedScreenState extends ConsumerState<RaisedBedScreen> {
  final _lengthController = TextEditingController(text: '8');
  final _widthController = TextEditingController(text: '4');
  final _heightController = TextEditingController(text: '12');

  String _material = 'cedar';
  int _bedCount = 1;

  double? _lumberFeet;
  int? _corners;
  double? _soilCuYd;
  double? _soilBags;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _heightController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 8;
    final width = double.tryParse(_widthController.text) ?? 4;
    final height = double.tryParse(_heightController.text) ?? 12;

    final heightFt = height / 12;

    // Perimeter for lumber
    final perimeter = (length + width) * 2;

    // Rows of boards (assuming 6\" boards for 12\" height = 2 rows)
    final rows = (height / 6).ceil();

    // Total linear feet of lumber
    final lumberFeet = perimeter * rows * _bedCount;

    // Corner posts: 4 per bed
    final corners = 4 * _bedCount;

    // Soil volume
    final cuFt = length * width * heightFt;
    final soilCuYd = (cuFt / 27) * _bedCount;

    // Bags of soil (2 cu ft bags)
    final soilBags = (cuFt / 2) * _bedCount;

    setState(() { _lumberFeet = lumberFeet; _corners = corners; _soilCuYd = soilCuYd; _soilBags = soilBags; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '8'; _widthController.text = '4'; _heightController.text = '12'; setState(() { _material = 'cedar'; _bedCount = 1; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Raised Bed', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['cedar', 'redwood', 'composite', 'block'], _material, {'cedar': 'Cedar', 'redwood': 'Redwood', 'composite': 'Composite', 'block': 'Block'}, (v) { setState(() => _material = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildCountSelector(colors),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Width', unit: 'feet', controller: _widthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Height', unit: 'inches', controller: _heightController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_lumberFeet != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_material == 'block' ? 'WALL BLOCKS' : 'LUMBER (2x6)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_lumberFeet!.toStringAsFixed(0)} lin ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Corner Posts (4x4)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_corners', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Soil (bulk)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilCuYd!.toStringAsFixed(1)} cu yd', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Soil (2 cu ft bags)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_soilBags!.toStringAsFixed(0)} bags', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Max 4\' width for reach from both sides. Use rot-resistant wood. Line with landscape fabric to retain soil.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSoilTable(colors),
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

  Widget _buildCountSelector(ZaftoColors colors) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('NUMBER OF BEDS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: [1, 2, 3, 4].map((n) {
        final isSelected = _bedCount == n;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _bedCount = n); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: n != 4 ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text('$n', textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSoilTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SOIL MIX RECIPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Topsoil', '40%'),
        _buildTableRow(colors, 'Compost', '40%'),
        _buildTableRow(colors, 'Drainage (perlite)', '20%'),
        const SizedBox(height: 8),
        Divider(color: colors.borderSubtle),
        const SizedBox(height: 8),
        _buildTableRow(colors, 'Depth for veggies', '12\" minimum'),
        _buildTableRow(colors, 'Depth for roots', '18-24\"'),
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
