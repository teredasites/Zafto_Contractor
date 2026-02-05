import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// ADA Doorway Widening Calculator - Accessible doorway modification
class AdaDoorwayScreen extends ConsumerStatefulWidget {
  const AdaDoorwayScreen({super.key});
  @override
  ConsumerState<AdaDoorwayScreen> createState() => _AdaDoorwayScreenState();
}

class _AdaDoorwayScreenState extends ConsumerState<AdaDoorwayScreen> {
  final _currentWidthController = TextEditingController(text: '30');
  final _doorCountController = TextEditingController(text: '1');

  String _wallType = 'nonload';
  String _targetWidth = '36';

  double? _widenAmount;
  String? _roughOpening;
  String? _doorSize;
  String? _workScope;

  @override
  void dispose() { _currentWidthController.dispose(); _doorCountController.dispose(); super.dispose(); }

  void _calculate() {
    final currentWidth = double.tryParse(_currentWidthController.text) ?? 30;
    final targetWidthNum = double.tryParse(_targetWidth) ?? 36;

    final widenAmount = targetWidthNum - currentWidth;

    // Rough opening is door width + 2" (1" each side for jamb)
    final roughOpening = '${targetWidthNum.toStringAsFixed(0)}" x 82"';

    // Standard door sizes
    String doorSize;
    if (targetWidthNum >= 36) {
      doorSize = '36" door (34" clear)';
    } else if (targetWidthNum >= 34) {
      doorSize = '34" door (32" clear)';
    } else {
      doorSize = '32" door (30" clear)';
    }

    // Work scope based on wall type and widening amount
    String workScope;
    if (widenAmount <= 0) {
      workScope = 'No widening needed - current opening meets or exceeds target.';
    } else if (_wallType == 'nonload') {
      workScope = 'Cut studs, reframe opening, install new header, patch drywall, install door.';
    } else {
      workScope = 'LOAD BEARING: Requires temporary support, engineer-specified header, permit required.';
    }

    setState(() {
      _widenAmount = widenAmount;
      _roughOpening = roughOpening;
      _doorSize = doorSize;
      _workScope = workScope;
    });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _currentWidthController.text = '30'; _doorCountController.text = '1'; setState(() { _wallType = 'nonload'; _targetWidth = '36'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('ADA Doorway Widening', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'WALL TYPE', ['nonload', 'loadbearing'], _wallType, {'nonload': 'Non-Load Bearing', 'loadbearing': 'Load Bearing'}, (v) { setState(() => _wallType = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'TARGET WIDTH', ['32', '34', '36', '42'], _targetWidth, {'32': '32"', '34': '34"', '36': '36" (ADA)', '42': '42"'}, (v) { setState(() => _targetWidth = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Current Width', unit: 'inches', controller: _currentWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Door Count', unit: 'qty', controller: _doorCountController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_widenAmount != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('WIDEN BY', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_widenAmount! > 0 ? '${_widenAmount!.toStringAsFixed(0)}"' : 'None', style: TextStyle(color: _widenAmount! > 0 ? colors.accentPrimary : colors.accentSuccess, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rough Opening', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_roughOpening!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Door Size', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_doorSize!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _wallType == 'loadbearing' ? colors.accentError.withValues(alpha: 0.1) : colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_workScope!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildADATable(colors),
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

  Widget _buildADATable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ADA DOOR REQUIREMENTS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Min clear width', '32"'),
        _buildTableRow(colors, 'ADA standard', '36" door'),
        _buildTableRow(colors, 'Max threshold', '1/2" beveled'),
        _buildTableRow(colors, 'Handle height', '34-48" AFF'),
        _buildTableRow(colors, 'Maneuvering space', '18" latch side'),
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
