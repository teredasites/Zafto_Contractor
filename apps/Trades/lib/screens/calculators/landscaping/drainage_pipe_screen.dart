import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Drainage Pipe Calculator - Pipe capacity and materials
class DrainagePipeScreen extends ConsumerStatefulWidget {
  const DrainagePipeScreen({super.key});
  @override
  ConsumerState<DrainagePipeScreen> createState() => _DrainagePipeScreenState();
}

class _DrainagePipeScreenState extends ConsumerState<DrainagePipeScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _drainAreaController = TextEditingController(text: '2000');

  String _pipeSize = '4';

  double? _pipeCapacity;
  double? _neededCapacity;
  double? _gravelTons;
  double? _fabricSqFt;
  bool? _adequate;

  @override
  void dispose() { _lengthController.dispose(); _drainAreaController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 50;
    final drainArea = double.tryParse(_drainAreaController.text) ?? 2000;
    final pipeIn = double.tryParse(_pipeSize) ?? 4;

    // Flow needed: assume 2 in/hr storm
    final neededGpm = drainArea * 0.04; // simplified

    // Pipe capacity at 1% slope
    double capacity;
    switch (pipeIn.toInt()) {
      case 3:
        capacity = 20;
        break;
      case 4:
        capacity = 40;
        break;
      case 6:
        capacity = 100;
        break;
      default:
        capacity = 40;
    }

    final adequate = capacity >= neededGpm;

    // Gravel: 12" wide trench, 6" gravel base + 6" sides
    final trenchWidthFt = 1.0;
    final gravelCuFt = length * trenchWidthFt * 0.5; // 6" depth
    final gravelTons = (gravelCuFt / 27) * 1.4;

    // Filter fabric: line trench
    final fabricSqFt = length * (trenchWidthFt + 1) * 2; // sides + bottom

    setState(() {
      _pipeCapacity = capacity;
      _neededCapacity = neededGpm;
      _gravelTons = gravelTons;
      _fabricSqFt = fabricSqFt;
      _adequate = adequate;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _drainAreaController.text = '2000'; setState(() { _pipeSize = '4'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Drainage Pipe', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'PIPE SIZE', ['3', '4', '6'], _pipeSize, {'3': '3\"', '4': '4\"', '6': '6\"'}, (v) { setState(() => _pipeSize = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Pipe Length', unit: 'ft', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            ZaftoInputField(label: 'Drainage Area', unit: 'sq ft', controller: _drainAreaController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_pipeCapacity != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('PIPE CAPACITY', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_pipeCapacity!.toStringAsFixed(0)} GPM', style: TextStyle(color: _adequate! ? colors.accentSuccess : colors.accentError, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Flow needed', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_neededCapacity!.toStringAsFixed(1)} GPM', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Size adequate', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_adequate! ? 'Yes' : 'No - upsize', style: TextStyle(color: _adequate! ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Drain gravel', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelTons!.toStringAsFixed(2)} tons', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Filter fabric', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_fabricSqFt!.toStringAsFixed(0)} sq ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
              ]),
            ),
            const SizedBox(height: 20),
            _buildPipeGuide(colors),
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildPipeGuide(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PIPE INSTALLATION', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Min slope', '1% (1/8\" per ft)'),
        _buildTableRow(colors, 'Trench depth', '12-18\" minimum'),
        _buildTableRow(colors, 'Gravel bed', '2-3\" under pipe'),
        _buildTableRow(colors, 'Fabric wrap', 'Prevents clogging'),
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
