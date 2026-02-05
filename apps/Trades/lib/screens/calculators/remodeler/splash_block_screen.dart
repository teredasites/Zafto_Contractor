import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/zafto_colors.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/zafto/zafto_widgets.dart';

/// Splash Block Calculator - Splash block/discharge estimation
class SplashBlockScreen extends ConsumerStatefulWidget {
  const SplashBlockScreen({super.key});
  @override
  ConsumerState<SplashBlockScreen> createState() => _SplashBlockScreenState();
}

class _SplashBlockScreenState extends ConsumerState<SplashBlockScreen> {
  final _downspoutsController = TextEditingController(text: '4');

  String _type = 'concrete';
  String _discharge = 'splash';

  int? _splashBlocks;
  double? _extensionFeet;
  double? _gravelCuFt;

  @override
  void dispose() { _downspoutsController.dispose(); super.dispose(); }

  void _calculate() {
    final downspouts = int.tryParse(_downspoutsController.text) ?? 4;

    // Basic: 1 splash block per downspout
    final splashBlocks = _discharge == 'splash' ? downspouts : 0;

    // Extensions if using roll-out or pipe
    double extensionFeet;
    switch (_discharge) {
      case 'splash':
        extensionFeet = 0;
        break;
      case 'rollout':
        extensionFeet = downspouts * 4.0; // 4' each
        break;
      case 'pipe':
        extensionFeet = downspouts * 10.0; // 10' buried each
        break;
      case 'drywell':
        extensionFeet = downspouts * 6.0; // to drywell
        break;
      default:
        extensionFeet = 0;
    }

    // Gravel for drywell
    final gravelCuFt = _discharge == 'drywell' ? downspouts * 3.0 : 0.0; // 3 cuft per

    setState(() { _splashBlocks = splashBlocks; _extensionFeet = extensionFeet; _gravelCuFt = gravelCuFt; });
  }

  @override
  void initState() { super.initState(); _calculate(); }

  void _clearAll() { HapticFeedback.lightImpact(); _downspoutsController.text = '4'; setState(() { _type = 'concrete'; _discharge = 'splash'; }); _calculate(); }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(zaftoColorsProvider);
    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(backgroundColor: colors.bgBase, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: colors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Splash Block', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        actions: [IconButton(icon: Icon(LucideIcons.rotateCcw, color: colors.textSecondary), onPressed: _clearAll)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSelector(colors, 'MATERIAL', ['concrete', 'plastic', 'stone'], _type, {'concrete': 'Concrete', 'plastic': 'Plastic', 'stone': 'Stone'}, (v) { setState(() => _type = v); _calculate(); }),
            const SizedBox(height: 16),
            _buildSelector(colors, 'DISCHARGE', ['splash', 'rollout', 'pipe', 'drywell'], _discharge, {'splash': 'Splash Block', 'rollout': 'Roll-Out', 'pipe': 'Buried Pipe', 'drywell': 'Dry Well'}, (v) { setState(() => _discharge = v); _calculate(); }),
            const SizedBox(height: 20),
            ZaftoInputField(label: 'Number of Downspouts', unit: 'qty', controller: _downspoutsController, onChanged: (_) => _calculate()),
            const SizedBox(height: 32),
            if (_splashBlocks != null) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
              child: Column(children: [
                if (_discharge == 'splash') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('SPLASH BLOCKS', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('$_splashBlocks', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                ] else ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('EXTENSION NEEDED', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_extensionFeet!.toStringAsFixed(0)} ft', style: TextStyle(color: colors.accentPrimary, fontSize: 24, fontWeight: FontWeight.w700))]),
                ],
                const SizedBox(height: 12), Divider(color: colors.borderSubtle), const SizedBox(height: 12),
                if (_discharge == 'drywell') ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Gravel (per well)', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('${_gravelCuFt!.toStringAsFixed(0)} cu ft', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 8),
                ],
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Min Distance', style: TextStyle(color: colors.textSecondary, fontSize: 14)), Text('4-6\' from foundation', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 16),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colors.accentInfo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_getTypeTip(), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _buildOptionsTable(colors),
          ]),
        ),
      ),
    );
  }

  String _getTypeTip() {
    switch (_discharge) {
      case 'splash':
        return 'Position angled away from foundation. Replace cracked blocks. Best for small roofs.';
      case 'rollout':
        return 'Roll-out extensions unroll when water flows. Good for mowing areas. Check for kinks.';
      case 'pipe':
        return 'Bury 4\" solid pipe below frost line. Slope 1\" per 8\'. Discharge to daylight or drain.';
      case 'drywell':
        return 'Dry well: 3\' cube pit filled with gravel. Overflow to daylight. Best for heavy rain.';
      default:
        return 'Discharge water 4-6\' minimum from foundation to prevent basement seepage.';
    }
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
            child: Text(labels[o]!, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : colors.textPrimary, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _buildOptionsTable(ZaftoColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.bgElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderSubtle)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('DISCHARGE OPTIONS', style: TextStyle(color: colors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _buildTableRow(colors, 'Splash block', 'Cheapest, visible'),
        _buildTableRow(colors, 'Roll-out', 'Tidy, automatic'),
        _buildTableRow(colors, 'Buried pipe', 'Best, hidden'),
        _buildTableRow(colors, 'Dry well', 'Heavy rain areas'),
        _buildTableRow(colors, 'Rain barrel', 'Water collection'),
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
