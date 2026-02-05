import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Medicine Cabinet Calculator - Sizing and placement
class MedicineCabinetScreen extends ConsumerStatefulWidget {
  const MedicineCabinetScreen({super.key});
  @override
  ConsumerState<MedicineCabinetScreen> createState() => _MedicineCabinetScreenState();
}

class _MedicineCabinetScreenState extends ConsumerState<MedicineCabinetScreen> {
  final _vanityWidthController = TextEditingController(text: '36');
  final _mirrorHeightController = TextEditingController(text: '30');
  final _wallDepthController = TextEditingController(text: '4');

  String _mountType = 'recessed';

  double? _cabinetWidth;
  double? _cabinetHeight;
  bool? _fitsRecessed;
  String? _recommendation;

  @override
  void dispose() { _vanityWidthController.dispose(); _mirrorHeightController.dispose(); _wallDepthController.dispose(); super.dispose(); }

  void _calculate() {
    final vanityWidth = double.tryParse(_vanityWidthController.text) ?? 36;
    final mirrorHeight = double.tryParse(_mirrorHeightController.text) ?? 30;
    final wallDepth = double.tryParse(_wallDepthController.text) ?? 4;

    // Cabinet should be 2/3 to equal vanity width
    final cabinetWidth = vanityWidth * 0.75;

    // Standard heights
    final cabinetHeight = mirrorHeight;

    // Recessed needs 3.5" min wall depth (between studs)
    final fitsRecessed = wallDepth >= 3.5;

    String recommendation;
    if (vanityWidth <= 24) {
      recommendation = '15-20\" wide cabinet';
    } else if (vanityWidth <= 36) {
      recommendation = '24-30\" wide cabinet';
    } else if (vanityWidth <= 48) {
      recommendation = '30-36\" wide cabinet';
    } else {
      recommendation = '36-48\" or double cabinet';
    }

    setState(() { _cabinetWidth = cabinetWidth; _cabinetHeight = cabinetHeight; _fitsRecessed = fitsRecessed; _recommendation = recommendation; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _vanityWidthController.text = '36'; _mirrorHeightController.text = '30'; _wallDepthController.text = '4'; setState(() => _mountType = 'recessed'); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Medicine Cabinet', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Vanity Width', unit: 'inches', controller: _vanityWidthController, onChanged: (_) => _calculate()),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Mirror Height', unit: 'inches', controller: _mirrorHeightController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Wall Depth', unit: 'inches', controller: _wallDepthController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_cabinetWidth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RECOMMENDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Flexible(child: Text(_recommendation!, style: TextStyle(color: colors.accentPrimary, fontSize: 18, fontWeight: FontWeight.w700)))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Target Width', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cabinetWidth!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Target Height', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_cabinetHeight!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recessed Fit', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_fitsRecessed! ? 'YES' : 'NO (use surface)', style: TextStyle(color: _fitsRecessed! ? colors.accentSuccess : colors.accentWarning, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Center above sink. Bottom at 40-48\" from floor. Check for electrical/plumbing in wall.', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildSizeTable(colors),
          ]),
        ),
      ),
    );
  }

  Widget _buildSelector(ZaftoColors colors) {
    final options = ['recessed', 'surface', 'semi_recessed'];
    final labels = {'recessed': 'Recessed', 'surface': 'Surface', 'semi_recessed': 'Semi-Recess'};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('MOUNT TYPE', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Row(children: options.map((o) {
        final isSelected = _mountType == o;
        return Expanded(child: GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _mountType = o); _calculate(); },
          child: Container(margin: EdgeInsets.only(right: o != options.last ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: isSelected ? colors.accentPrimary : colors.bgElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? colors.accentPrimary : colors.borderSubtle)),
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Small', '15\" x 26\"'),
        _buildTableRow(colors, 'Medium', '24\" x 30\"'),
        _buildTableRow(colors, 'Large', '30\" x 36\"'),
        _buildTableRow(colors, 'Tri-view', '36-48\" wide'),
        _buildTableRow(colors, 'Recess depth', '3.5-4.5\"'),
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
