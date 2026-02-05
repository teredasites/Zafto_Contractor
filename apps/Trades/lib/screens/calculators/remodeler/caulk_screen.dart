import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Caulk Calculator - Caulk/sealant estimation
class CaulkScreen extends ConsumerStatefulWidget {
  const CaulkScreen({super.key});
  @override
  ConsumerState<CaulkScreen> createState() => _CaulkScreenState();
}

class _CaulkScreenState extends ConsumerState<CaulkScreen> {
  final _lengthController = TextEditingController(text: '50');
  final _widthController = TextEditingController(text: '0.25');
  final _depthController = TextEditingController(text: '0.25');

  String _type = 'silicone';

  double? _linearFeet;
  double? _tubes10oz;
  double? _tubes28oz;

  @override
  void dispose() { _lengthController.dispose(); _widthController.dispose(); _depthController.dispose(); super.dispose(); }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0.25;
    final depth = double.tryParse(_depthController.text) ?? 0.25;

    // Coverage calculation
    // A 10.3 oz tube covers about 31 linear feet at 1/4" x 1/4" bead
    // Adjust based on bead size
    final beadArea = width * depth; // sq inches
    final standardBead = 0.25 * 0.25; // 1/4" x 1/4"
    final coverageMultiplier = standardBead / (beadArea > 0 ? beadArea : standardBead);

    final standardCoverage10oz = 31.0; // lf per tube at 1/4" x 1/4"
    final actualCoverage10oz = standardCoverage10oz * coverageMultiplier;

    final tubes10oz = length / actualCoverage10oz;

    // 28 oz (quart) tube covers about 85 lf at 1/4" x 1/4"
    final standardCoverage28oz = 85.0;
    final actualCoverage28oz = standardCoverage28oz * coverageMultiplier;
    final tubes28oz = length / actualCoverage28oz;

    setState(() { _linearFeet = length; _tubes10oz = tubes10oz; _tubes28oz = tubes28oz; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _lengthController.text = '50'; _widthController.text = '0.25'; _depthController.text = '0.25'; setState(() => _type = 'silicone'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Caulk', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Total Length', unit: 'feet', controller: _lengthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Joint Width', unit: 'inches', controller: _widthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Joint Depth', unit: 'inches', controller: _depthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_tubes10oz != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('TUBES NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tubes10oz!.toStringAsFixed(1)}', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('10.3 oz Tubes', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tubes10oz!.ceil()}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('28 oz Tubes (alt)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_tubes28oz!.ceil()}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Length', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_linearFeet!.toStringAsFixed(0)} lf', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('For large joints, use backer rod to reduce caulk needed. Cut tip to match joint width.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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
    final options = ['silicone', 'latex', 'polyurethane', 'butyl'];
    final labels = {'silicone': 'Silicone', 'latex': 'Latex', 'polyurethane': 'Polyurethane', 'butyl': 'Butyl'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('CAULK TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _type == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _type = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
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
        Text('CAULK APPLICATIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Silicone', 'Bath, kitchen, glass'),
        _buildTableRow(colors, 'Latex/acrylic', 'Paintable, interior'),
        _buildTableRow(colors, 'Polyurethane', 'Exterior, concrete'),
        _buildTableRow(colors, 'Butyl', 'Gutters, flashing'),
        _buildTableRow(colors, 'Fire caulk', 'Penetrations, rated'),
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
