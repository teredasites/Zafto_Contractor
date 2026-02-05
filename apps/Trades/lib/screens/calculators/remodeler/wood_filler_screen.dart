import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Wood Filler Calculator - Wood putty/filler estimation
class WoodFillerScreen extends ConsumerStatefulWidget {
  const WoodFillerScreen({super.key});
  @override
  ConsumerState<WoodFillerScreen> createState() => _WoodFillerScreenState();
}

class _WoodFillerScreenState extends ConsumerState<WoodFillerScreen> {
  final _holesController = TextEditingController(text: '50');
  final _avgDiameterController = TextEditingController(text: '0.25');
  final _avgDepthController = TextEditingController(text: '0.375');

  String _type = 'solvent';

  double? _volumeCuIn;
  double? _oz;
  int? _containers6oz;

  @override
  void dispose() { _holesController.dispose(); _avgDiameterController.dispose(); _avgDepthController.dispose(); super.dispose(); }

  void _calculate() {
    final holes = int.tryParse(_holesController.text) ?? 0;
    final diameter = double.tryParse(_avgDiameterController.text) ?? 0.25;
    final depth = double.tryParse(_avgDepthController.text) ?? 0.375;

    // Volume of a cylinder: π × r² × h
    final radius = diameter / 2;
    final volumePerHole = 3.14159 * radius * radius * depth;

    // Total volume
    final volumeCuIn = volumePerHole * holes;

    // Convert to oz (approximately 0.554 oz per cubic inch for wood filler)
    final oz = volumeCuIn * 0.554;

    // Add 25% for overfill and waste
    final ozWithWaste = oz * 1.25;

    final containers6oz = (ozWithWaste / 6).ceil();

    setState(() { _volumeCuIn = volumeCuIn; _oz = ozWithWaste; _containers6oz = containers6oz; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _holesController.text = '50'; _avgDiameterController.text = '0.25'; _avgDepthController.text = '0.375'; setState(() => _type = 'solvent'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Wood Filler', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Holes', unit: 'qty', controller: _holesController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Avg Diameter', unit: 'inches', controller: _avgDiameterController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Avg Depth', unit: 'inches', controller: _avgDepthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_oz != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('FILLER NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('~${_oz!.toStringAsFixed(1)} oz', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('6 oz Containers', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_containers6oz', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Volume', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_volumeCuIn!.toStringAsFixed(2)} cu in', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Apply in layers for deep holes. Overfill slightly and sand flush when dry.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildTypeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['solvent', 'water', 'epoxy'];
    final labels = {'solvent': 'Solvent-Based', 'water': 'Water-Based', 'epoxy': 'Epoxy'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FILLER TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildTypeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('FILLER COMPARISON', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Solvent-based', 'Stainable, harder'),
        _buildTableRow(colors, 'Water-based', 'Easy cleanup, shrinks'),
        _buildTableRow(colors, 'Epoxy', 'Strongest, no shrink'),
        _buildTableRow(colors, 'Putty sticks', 'Quick touch-ups'),
        _buildTableRow(colors, 'Grain filler', 'Open-grain woods'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12))),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
