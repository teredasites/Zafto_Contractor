import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Vanity Calculator - Bathroom vanity sizing
class VanityScreen extends ConsumerStatefulWidget {
  const VanityScreen({super.key});
  @override
  ConsumerState<VanityScreen> createState() => _VanityScreenState();
}

class _VanityScreenState extends ConsumerState<VanityScreen> {
  final _wallWidthController = TextEditingController(text: '60');
  final _clearanceController = TextEditingController(text: '30');

  String _sinks = 'single';
  String _style = 'freestanding';

  double? _maxVanityWidth;
  bool? _fitsDouble;
  String? _recommendation;

  @override
  void dispose() { _wallWidthController.dispose(); _clearanceController.dispose(); super.dispose(); }

  void _calculate() {
    final wallWidth = double.tryParse(_wallWidthController.text) ?? 60;
    final clearance = double.tryParse(_clearanceController.text) ?? 30;

    // Max vanity leaves clearance on sides
    final maxVanityWidth = wallWidth - 4; // 2" each side min

    // Double sink needs min 60"
    final fitsDouble = maxVanityWidth >= 60;

    String recommendation;
    if (maxVanityWidth >= 72) {
      recommendation = '72\" double vanity with ample counter';
    } else if (maxVanityWidth >= 60) {
      recommendation = '60\" double vanity (tight but works)';
    } else if (maxVanityWidth >= 48) {
      recommendation = '48\" single vanity with counter space';
    } else if (maxVanityWidth >= 36) {
      recommendation = '36\" single vanity';
    } else if (maxVanityWidth >= 24) {
      recommendation = '24\" single vanity (compact)';
    } else {
      recommendation = 'Pedestal or wall-mount sink';
    }

    setState(() { _maxVanityWidth = maxVanityWidth; _fitsDouble = fitsDouble; _recommendation = recommendation; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _wallWidthController.text = '60'; _clearanceController.text = '30'; setState(() { _sinks = 'single'; _style = 'freestanding'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Vanity Sizing', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'SINKS', ['single', 'double'], _sinks, {'single': 'Single', 'double': 'Double'}, (v) { setState(() => _sinks = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'STYLE', ['freestanding', 'floating', 'builtin'], _style, {'freestanding': 'Freestanding', 'floating': 'Floating', 'builtin': 'Built-in'}, (v) { setState(() => _style = v); _calculate(); }),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ZaftoInputField(label: 'Wall Width', unit: 'inches', controller: _wallWidthController, onChanged: (_) => _calculate())),
              const SizedBox(width: 12),
              Expanded(child: ZaftoInputField(label: 'Floor Clearance', unit: 'inches', controller: _clearanceController, onChanged: (_) => _calculate())),
            ]),
            const SizedBox(height: 32),
            if (_maxVanityWidth != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('MAX VANITY', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_maxVanityWidth!.toStringAsFixed(0)}\"', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Double Sink', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text(_fitsDouble! ? 'YES' : 'NO', style: TextStyle(color: _fitsDouble! ? colors.accentSuccess : colors.accentError, fontSize: 14, fontWeight: FontWeight.w600))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_recommendation!, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
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

  Widget _buildSizeTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('STANDARD VANITY SIZES', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Powder room', '18-24\" wide'),
        _buildTableRow(colors, 'Small bath', '24-30\" wide'),
        _buildTableRow(colors, 'Standard single', '36-48\" wide'),
        _buildTableRow(colors, 'Double vanity', '60-72\" wide'),
        _buildTableRow(colors, 'Standard depth', '18-22\" deep'),
        _buildTableRow(colors, 'Counter height', '32-36\"'),
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
