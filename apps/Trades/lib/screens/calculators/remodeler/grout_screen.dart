import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Grout Calculator - Tile grout estimation
class GroutScreen extends ConsumerStatefulWidget {
  const GroutScreen({super.key});
  @override
  ConsumerState<GroutScreen> createState() => _GroutScreenState();
}

class _GroutScreenState extends ConsumerState<GroutScreen> {
  final _areaSqftController = TextEditingController(text: '100');
  final _tileLengthController = TextEditingController(text: '12');
  final _tileWidthController = TextEditingController(text: '12');
  final _jointWidthController = TextEditingController(text: '0.125');
  final _jointDepthController = TextEditingController(text: '0.375');

  String _groutType = 'sanded';

  double? _groutLbs;
  double? _bags25lb;
  double? _bags10lb;

  @override
  void dispose() { _areaSqftController.dispose(); _tileLengthController.dispose(); _tileWidthController.dispose(); _jointWidthController.dispose(); _jointDepthController.dispose(); super.dispose(); }

  void _calculate() {
    final areaSqft = double.tryParse(_areaSqftController.text) ?? 0;
    final tileLength = double.tryParse(_tileLengthController.text) ?? 12;
    final tileWidth = double.tryParse(_tileWidthController.text) ?? 12;
    final jointWidth = double.tryParse(_jointWidthController.text) ?? 0.125;
    final jointDepth = double.tryParse(_jointDepthController.text) ?? 0.375;

    // Calculate grout coverage
    // Formula: (L + W) × Joint Width × Joint Depth × 1.86 / (L × W)
    // Result is lbs per sqft
    final numerator = (tileLength + tileWidth) * jointWidth * jointDepth * 1.86;
    final denominator = tileLength * tileWidth;

    final lbsPerSqft = denominator > 0 ? numerator / denominator : 0;
    final groutLbs = lbsPerSqft * areaSqft;

    // Add 10% waste
    final groutWithWaste = groutLbs * 1.10;

    final bags25lb = (groutWithWaste / 25).ceil();
    final bags10lb = (groutWithWaste / 10).ceil();

    setState(() { _groutLbs = groutWithWaste; _bags25lb = bags25lb.toDouble(); _bags10lb = bags10lb.toDouble(); });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _areaSqftController.text = '100'; _tileLengthController.text = '12'; _tileWidthController.text = '12'; _jointWidthController.text = '0.125'; _jointDepthController.text = '0.375'; setState(() => _groutType = 'sanded'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Grout', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Area to Grout', unit: 'sq ft', controller: _areaSqftController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Tile Length', unit: 'inches', controller: _tileLengthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Tile Width', unit: 'inches', controller: _tileWidthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Joint Width', unit: 'inches', controller: _jointWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Joint Depth', unit: 'inches', controller: _jointDepthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_groutLbs != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('GROUT NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_groutLbs!.toStringAsFixed(1)} lbs', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('25 lb Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bags25lb!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('10 lb Bags', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_bags10lb!.toStringAsFixed(0)}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Sanded: joints > 1/8\". Unsanded: joints < 1/8\". Epoxy: wet areas, high traffic.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
    final options = ['sanded', 'unsanded', 'epoxy'];
    final labels = {'sanded': 'Sanded', 'unsanded': 'Unsanded', 'epoxy': 'Epoxy'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('GROUT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _groutType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _groutType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
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
        Text('COMMON JOINT WIDTHS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, '1/16\" (0.0625)', 'Rectified tile'),
        _buildTableRow(colors, '1/8\" (0.125)', 'Standard wall'),
        _buildTableRow(colors, '3/16\" (0.1875)', 'Standard floor'),
        _buildTableRow(colors, '1/4\" (0.25)', 'Rustic look'),
        _buildTableRow(colors, '3/8\" (0.375)', 'Saltillo, stone'),
      ]),
    );
  }

  Widget _buildTableRow(ZaftoColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }
}
